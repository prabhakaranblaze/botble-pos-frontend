<?php

namespace Botble\Quickbooks\Http\Controllers;

use Botble\Base\Http\Controllers\BaseController;
use Botble\Base\Http\Responses\BaseHttpResponse;
use Botble\Quickbooks\Forms\QuickbooksSettingForm;
use Botble\Quickbooks\Http\Requests\QuickbooksSettingRequest;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Botble\Quickbooks\Services\QuickBooksService;
use QuickBooksOnline\API\DataService\DataService;
use Illuminate\Support\Facades\Storage;
use Botble\Quickbooks\Models\QuickbooksToken;
use Botble\Quickbooks\Models\QuickbooksJob;
use Botble\Ecommerce\Models\Product;
use Botble\Ecommerce\Models\ProductCategory;
use Botble\Slug\Models\Slug;
use Botble\Setting\Facades\Setting;
use Botble\Quickbooks\Tables\CronTable;
use Botble\Quickbooks\Tables\QuickbooksProductsTable;
use Botble\Setting\Commands\ProcessQuickbooksJobsCommand;
use Illuminate\Support\Str;
use Botble\Quickbooks\Tables\QuickbooksCategoryTable;

class QuickBooksproductController extends BaseController
{
    public function QuickbooksProducts(QuickbooksProductsTable $dataTable)
    {
        $this->pageTitle(trans('plugins/quickbooks::qbs.products.title'));
        
        return $dataTable->renderTable();
    }

    public function importProduct($itemId)
    {
        try {
            $service = app(QuickBooksService::class);

            // Fetch item by ID from QuickBooks
            $item = $service->fetchItemById($itemId);
            if (!$item) {
                return redirect()->back()->with('error', 'QuickBooks item not found.');
            }
           
            //  Handle Category
            $parentRef = $item['ParentRef'] ?? null;
            $categoryId = null;

            if ($parentRef) {
                // Check if category already exists by QuickBooks category ID
                $category = ProductCategory::where('qb_cat_id', $parentRef['value'])->first();

                if (!$category) {
                    // Generate unique slug
                    $slug = Str::slug($parentRef['name']);
                    $originalSlug = $slug;
                    $counter = 1;

                    while (ProductCategory::where('slug', $slug)->exists()) {
                        $slug = $originalSlug . '-' . $counter;
                        $counter++;
                    }

                    // Create new category
                    $category = ProductCategory::create([
                        'name'      => $parentRef['name'],
                        'slug'      => $slug,
                        'qb_cat_id' => $parentRef['value'],
                    ]);

                    Slug::create([
                        'key' => $slug,
                        'reference_type' => ProductCategory::class,
                        'reference_id' => $category->id,
                        'prefix' => 'product-categories',
                    ]);

                  
                }

                $categoryId = $category->id;
            }

            // Handle Product
            $product = Product::firstOrNew(['quickbooks_item_id' => $item['Id']]);
            $isNewProduct = !$product->exists;

            if (!$product->exists && !empty($item['Sku'])) {
                $productBySku = Product::where('sku', $item['Sku'])->first();

                if ($productBySku) {
                    // Existing product found by SKU → update QB item ID
                    $product = $productBySku;
                    $product->quickbooks_item_id = $item['Id'];
                    $isNewProduct = false; // It’s existing, just updated QB ID
                } else {
                    // Completely new product
                    $product = new Product();
                    $product->quickbooks_item_id = $item['Id'];
                    $isNewProduct = true;
                }
            }

            $product->name    = $item['Name'];
            $product->sku     = $item['Sku'] ?? null;
            $product->price   = $item['UnitPrice'] ?? 0;
            $product->description   = $item['Description'] ?? null;
            $product->images  = json_encode([]);
            $quantity = 0;
            // Update quantity if TrackQtyOnHand is true
            if (isset($item['TrackQtyOnHand']) && $item['TrackQtyOnHand']) {
                $quantity = $item['QtyOnHand'] ?? 0;
            }
            $product->quantity = $quantity;
            if ($isNewProduct) {
                $product->length  = 0;
                $product->wide    = 0;
                $product->height  = 0;
                $product->weight  = 0;
                $product->cost_per_item  = 0;
                $product->generate_license_code  = 0;
            }
           
            //stock_status
            $stock_status = 'in_stock';
            if (isset($item['TrackQtyOnHand']) && isset($item['QtyOnHand']) && $item['QtyOnHand'] == 0) {
                $stock_status = 'out_of_stock';
            }
            $product->stock_status  = $stock_status;
            $product->sale_price   = $item['UnitPrice'] ?? null;
            $product->cost_per_item   = $item['PurchaseCost'] ?? null;
            // Generate unique slug for product
            if ($isNewProduct || $product->isDirty('name')) {
                $slug = Str::slug($product->name);
                $originalSlug = $slug;
                $counter = 1;

                while (Product::where('slug', $slug)->where('id', '!=', $product->id)->exists()) {
                    $slug = $originalSlug . '-' . $counter;
                    $counter++;
                }
                $product->slug = $slug;
            }
            
            $product->save();
            
            if ($isNewProduct || $product->isDirty('name')) {
                Slug::create([
                    'key' => $slug,
                    'reference_type' => Product::class,
                    'reference_id' => $product->id,
                    'prefix' => 'products',
                ]);
            }
            

            // Attach category via pivot table
            if (!empty($categoryId)) {
                $product->categories()->syncWithoutDetaching([$categoryId]);
            }

            return $this->httpResponse()->setError(false)->setMessage('Product imported successfully');

        } catch (\Exception $e) {
            \Log::error('QuickBooks import error: ' . $e->getMessage());
            return $this->httpResponse()->setError()->setMessage('Failed to import product');
        }
    }

    public function QuickbooksCategories(QuickbooksCategoryTable $dataTable)
    {
        $this->pageTitle(trans('plugins/quickbooks::qbs.categories.title'));
        
        return $dataTable->renderTable();
    }

    public function importCategory($itemId)
    {
        try {
            $service = app(QuickBooksService::class);

            // Fetch item by ID from QuickBooks
            $item = $service->fetchItemById($itemId);
            if (!$item) {
                return redirect()->back()->with('error', 'QuickBooks category not found.');
            } 
            
            // Generate unique slug
            $slug = Str::slug($item['Name']);
            $originalSlug = $slug;
            $counter = 1;
            while (ProductCategory::where('slug', $slug)->exists()) {
                $slug = $originalSlug . '-' . $counter;
                $counter++;
            }

            $category = ProductCategory::firstOrNew(['qb_cat_id' => $item['Id']]);
            $category->name    = $item['Name'];
            $category->slug     = $slug ?? null;
            $category->qb_cat_id   = $item['Id'];
            $category->save();

            Slug::create([
                'key' => $slug,
                'reference_type' => ProductCategory::class,
                'reference_id' => $category->id,
                'prefix' => 'product-categories',
            ]);
                       
            return $this->httpResponse()->setError(false)->setMessage('Category imported successfully');

        } catch (\Exception $e) {
            \Log::error('QuickBooks import error: ' . $e->getMessage());
            return $this->httpResponse()->setError()->setMessage('Failed to import category');
        }
    }


}
