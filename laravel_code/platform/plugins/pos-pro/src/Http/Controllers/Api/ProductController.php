<?php

namespace Botble\PosPro\Http\Controllers\Api;

use Botble\Base\Http\Controllers\BaseController;
use Botble\Base\Http\Responses\BaseHttpResponse;
use Botble\Ecommerce\Models\Product;
use Botble\Ecommerce\Models\ProductCategory;
use Illuminate\Http\Request;

class ProductController extends BaseController
{
    /**
     * Get user's store filter
     * Same logic as PosController
     */
    protected function getUserStoreFilter()
    {
        $user = auth()->user();
        return $user->store_id ?? null;
    }

    /**
     * Get products with pagination
     * Uses same logic as PosController->getProducts() but returns JSON
     */
    public function index(Request $request, BaseHttpResponse $response)
    {
        $page = $request->input('page', 1);
        $perPage = $request->input('per_page', 20);

        $query = Product::query()
            ->where('status', 'published')
            ->where('is_variation', 0)
            ->where(function ($query) {
                $query->where('is_available_in_pos', true)
                    ->orWhereNull('is_available_in_pos');
            })
            ->when($this->getUserStoreFilter(), function ($query, $storeId) {
                $query->where('store_id', $storeId);
            })
            ->when($request->input('search'), function ($query, $search): void {
                // Check if the search is an exact barcode match for a variation
                $storeId = $this->getUserStoreFilter();
                
                $variationQuery = Product::query()
                    ->where('barcode', $search)
                    ->where('status', 'published')
                    ->where('is_variation', 1);
                
                if ($storeId !== null) {
                    $variationQuery->where('store_id', $storeId);
                }
                
                $variationWithBarcode = $variationQuery
                    ->with('variationInfo.configurableProduct')
                    ->first();

                if ($variationWithBarcode && $variationWithBarcode->variationInfo) {
                    $parentProduct = $variationWithBarcode->variationInfo->configurableProduct;
                    if ($parentProduct) {
                        $query->where('id', $parentProduct->id);
                        return;
                    }
                }

                // Regular search
                $query->where(function ($q) use ($search): void {
                    $q->where('name', 'LIKE', '%' . $search . '%')
                        ->orWhere('sku', 'LIKE', '%' . $search . '%')
                        ->orWhere('barcode', 'LIKE', '%' . $search . '%');
                });
            })
            ->when($request->input('category_id'), function ($query, $categoryId): void {
                $query->whereHas('categories', function ($query) use ($categoryId): void {
                    $query->where('ec_product_categories.id', $categoryId);
                });
            })
            ->with(['variations.product'])
            ->latest();

        $products = $query->paginate($perPage);

        // ✅ Transform to JSON instead of HTML
        $productsData = $products->map(function ($product) {
            return $this->transformProduct($product);
        });

        return $response
            ->setData([
                'products' => $productsData,
                'pagination' => [
                    'current_page' => $products->currentPage(),
                    'last_page' => $products->lastPage(),
                    'per_page' => $products->perPage(),
                    'total' => $products->total(),
                ],
            ])
            ->setMessage('Products retrieved successfully');
    }

    /**
     * Get single product details
     */
    public function show(int $id, Request $request, BaseHttpResponse $response)
    {
        $product = Product::query()
            ->where('id', $id)
            ->where('status', 'published')
            ->when($this->getUserStoreFilter(), function ($query, $storeId) {
                $query->where('store_id', $storeId);
            })
            ->with(['categories', 'variations', 'variationInfo.configurableProduct'])
            ->first();

        if (!$product) {
            return $response
                ->setError()
                ->setMessage('Product not found or not available in your store')
                ->setCode(404);
        }

        return $response
            ->setData([
                'product' => $this->transformProduct($product, true),
            ])
            ->setMessage('Product retrieved successfully');
    }

    /**
     * Search products by barcode or SKU
     * Uses same logic as PosController->scanBarcode()
     */
    public function searchByCode(Request $request, BaseHttpResponse $response)
    {
        $request->validate([
            'code' => 'required|string',
        ]);

        $code = $request->input('code');

        // Search for any product (parent or variation) with this exact barcode/sku
        $product = Product::query()
            ->where('status', 'published')
            ->where(function ($q) use ($code) {
                $q->where('sku', $code)
                  ->orWhere('barcode', $code);
            })
            ->when($this->getUserStoreFilter(), function ($query, $storeId) {
                $query->where('store_id', $storeId);
            })
            ->with(['categories', 'variations', 'variationInfo.configurableProduct'])
            ->first();

        if (!$product) {
            return $response
                ->setError()
                ->setMessage('Product not found with the provided code')
                ->setCode(404);
        }

        // Check if this is a variation product
        if ($product->is_variation) {
            $parentProduct = $product->variationInfo->configurableProduct ?? null;

            if (!$parentProduct) {
                return $response
                    ->setError()
                    ->setMessage('Parent product not found')
                    ->setCode(404);
            }

            // Check if parent is available in POS
            if ($parentProduct->is_available_in_pos === false) {
                return $response
                    ->setError()
                    ->setMessage('Product not available in POS')
                    ->setCode(403);
            }

            return $response
                ->setData([
                    'product' => $this->transformProduct($product, true),
                    'parent_product' => $this->transformProduct($parentProduct, true),
                    'is_variation' => true,
                ])
                ->setMessage('Product variation found successfully');
        }

        // Parent product
        if ($product->is_available_in_pos === false) {
            return $response
                ->setError()
                ->setMessage('Product not available in POS')
                ->setCode(403);
        }

        return $response
            ->setData([
                'product' => $this->transformProduct($product, true),
                'is_variation' => false,
                'has_variations' => $product->variations->isNotEmpty(),
            ])
            ->setMessage('Product found successfully');
    }

    /**
     * Get product categories
     */
    public function categories(BaseHttpResponse $response)
    {
        $categories = ProductCategory::query()
            ->where('status', 'published')
            ->whereNull('parent_id')
            ->with('children')
            ->orderBy('order')
            ->get();

        return $response
            ->setData([
                'categories' => $categories->map(function ($category) {
                    return [
                        'id' => $category->id,
                        'name' => $category->name,
                        'slug' => $category->slug,
                        'icon' => $category->icon,
                        'image' => $category->image ? url($category->image) : null,
                        'description' => $category->description,
                        'children' => $category->children->map(function ($child) {
                            return [
                                'id' => $child->id,
                                'name' => $child->name,
                                'slug' => $child->slug,
                                'icon' => $child->icon,
                                'image' => $child->image ? url($child->image) : null,
                            ];
                        }),
                    ];
                }),
            ])
            ->setMessage('Categories retrieved successfully');
    }

    /**
     * Transform product to API format
     * Returns clean JSON structure for Flutter
     */
    protected function transformProduct(Product $product, bool $detailed = false): array
    {
        // Base product data
        $data = [
            'id' => $product->id,
            'name' => $product->name,
            'sku' => $product->sku,
            'barcode' => $product->barcode,
            'price' => (float) $product->price,
            'sale_price' => $product->sale_price ? (float) $product->sale_price : null,
            'final_price' => (float) ($product->sale_price ?: $product->price),
            'quantity' => $product->quantity ?? 0,
            'image' => $product->image ? url($product->image) : null,
            'is_variation' => (bool) $product->is_variation,
            'stock_status' => $product->stock_status,
            'with_storehouse_management' => (bool) $product->with_storehouse_management,
        ];

        // Add tax info if available
        if ($product->tax) {
            $data['tax'] = [
                'id' => $product->tax->id,
                'title' => $product->tax->title,
                'percentage' => (float) $product->tax->percentage,
            ];
        }

        // Add detailed information if requested
        if ($detailed) {
            $data['description'] = $product->description;
            $data['content'] = $product->content;
            
            // Add all images
            if ($product->images) {
                $data['images'] = collect($product->images)->map(function ($image) {
                    return url($image);
                })->toArray();
            }
            
            // Add categories
            if ($product->categories) {
                $data['categories'] = $product->categories->map(function ($category) {
                    return [
                        'id' => $category->id,
                        'name' => $category->name,
                        'slug' => $category->slug,
                    ];
                })->toArray();
            }
            
            // Add variations if available
            if ($product->variations && $product->variations->count() > 0) {
                $data['variations'] = $product->variations->map(function ($variation) {
                    $variationData = [
                        'id' => $variation->id,
                        'name' => $variation->name,
                        'sku' => $variation->sku,
                        'barcode' => $variation->barcode,
                        'price' => (float) $variation->price,
                        'sale_price' => $variation->sale_price ? (float) $variation->sale_price : null,
                        'final_price' => (float) ($variation->sale_price ?: $variation->price),
                        'quantity' => $variation->quantity ?? 0,
                        'image' => $variation->image ? url($variation->image) : null,
                    ];

                    // Add variation attributes
                    if ($variation->variationItems) {
                        $variationData['attributes'] = $variation->variationItems->map(function ($item) {
                            return [
                                'attribute_id' => $item->attribute_id,
                                'attribute_name' => $item->attribute->title ?? '',
                                'id' => $item->id,
                                'title' => $item->title,
                            ];
                        })->toArray();
                    }

                    return $variationData;
                })->toArray();
            }
        } else {
            // For list view, just indicate if has variations
            $data['has_variations'] = $product->variations && $product->variations->count() > 0;
        }

        return $data;
    }
}