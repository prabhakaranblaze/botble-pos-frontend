<?php

namespace Botble\PosPro\Http\Controllers\Vendor;

use Botble\Base\Http\Controllers\BaseController;
use Botble\Base\Http\Responses\BaseHttpResponse;
use Botble\Ecommerce\Facades\Currency;
use Botble\Ecommerce\Models\Address;
use Botble\Ecommerce\Models\Currency as CurrencyModel;
use Botble\Ecommerce\Models\Customer;
use Botble\Ecommerce\Models\Product;
use Botble\Ecommerce\Models\ProductVariationItem;
use Botble\Language\Facades\Language;
use Botble\PosPro\Services\CartService;
use Botble\PosPro\Traits\HasVendorContext;
use Exception;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Str;

class VendorPosController extends BaseController
{
    use HasVendorContext;

    public function __construct(protected CartService $cartService)
    {
    }

    public function index()
    {
        $this->pageTitle(trans('plugins/pos-pro::pos.name'));

        $storeId = $this->getStoreId();

        $products = Product::query()
            ->where('store_id', $storeId)
            ->where('status', 'published')
            ->where('is_variation', 0)
            ->where(function ($query): void {
                $query->where('is_available_in_pos', true)
                    ->orWhereNull('is_available_in_pos');
            })
            ->latest()
            ->paginate(12);

        $customers = $this->getStoreCustomers();

        $cart = $this->cartService->getCart($this->getCartSessionPrefix());
        $cart['html'] = view('plugins/pos-pro::partials.cart', ['cart' => $cart, 'customers' => $customers])->render();

        $routePrefix = 'marketplace.vendor.pos';

        $user = auth('customer')->user();

        $posContext = [
            'user' => [
                'name' => $user->name,
                'email' => $user->email,
                'avatar_url' => $user->avatar_url,
            ],
            'urls' => [
                'dashboard' => route('marketplace.vendor.dashboard'),
                'profile' => route('customer.edit-account'),
                'logout' => route('customer.logout'),
            ],
        ];

        return view('plugins/pos-pro::index', compact('products', 'customers', 'cart', 'routePrefix', 'posContext'));
    }

    public function scanBarcode(Request $request, BaseHttpResponse $response)
    {
        $barcode = $request->input('barcode');
        $storeId = $this->getStoreId();

        if (! $barcode) {
            return $response
                ->setError()
                ->setMessage('Barcode is required')
                ->toApiResponse();
        }

        $product = Product::query()
            ->where('barcode', $barcode)
            ->where('status', 'published')
            ->with(['variationInfo.configurableProduct', 'variations'])
            ->first();

        if (! $product) {
            return $response
                ->setError()
                ->setMessage(trans('plugins/pos-pro::pos.no_product_found_with_barcode', ['barcode' => $barcode]))
                ->toApiResponse();
        }

        if ($product->is_variation) {
            $parentProduct = $product->variationInfo->configurableProduct ?? null;

            if (! $parentProduct || $parentProduct->store_id !== $storeId) {
                return $response
                    ->setError()
                    ->setMessage(trans('plugins/pos-pro::pos.product_not_in_store'))
                    ->toApiResponse();
            }

            if ($parentProduct->is_available_in_pos === false) {
                return $response
                    ->setError()
                    ->setMessage(trans('plugins/pos-pro::pos.product_not_available_in_pos'))
                    ->toApiResponse();
            }

            try {
                $result = $this->cartService->addToCart($product->id, 1, [], $this->getCartSessionPrefix());

                return $response
                    ->setData([
                        'auto_added' => true,
                        'product' => $product,
                        'parent_product' => $parentProduct,
                        'cart' => $result['cart'],
                        'message' => $result['message'],
                    ])
                    ->toApiResponse();
            } catch (Exception $e) {
                return $response
                    ->setError()
                    ->setMessage($e->getMessage())
                    ->toApiResponse();
            }
        } else {
            if ($product->store_id !== $storeId) {
                return $response
                    ->setError()
                    ->setMessage(trans('plugins/pos-pro::pos.product_not_in_store'))
                    ->toApiResponse();
            }

            if ($product->is_available_in_pos === false) {
                return $response
                    ->setError()
                    ->setMessage(trans('plugins/pos-pro::pos.product_not_available_in_pos'))
                    ->toApiResponse();
            }

            if ($product->variations->isEmpty()) {
                try {
                    $result = $this->cartService->addToCart($product->id, 1, [], $this->getCartSessionPrefix());

                    return $response
                        ->setData([
                            'auto_added' => true,
                            'product' => $product,
                            'cart' => $result['cart'],
                            'message' => $result['message'],
                        ])
                        ->toApiResponse();
                } catch (Exception $e) {
                    return $response
                        ->setError()
                        ->setMessage($e->getMessage())
                        ->toApiResponse();
                }
            } else {
                return $response
                    ->setData([
                        'auto_added' => false,
                        'product' => $product,
                        'has_variations' => true,
                        'message' => trans('plugins/pos-pro::pos.product_has_variations_select_option'),
                    ])
                    ->toApiResponse();
            }
        }
    }

    public function getProducts(Request $request, BaseHttpResponse $response)
    {
        $storeId = $this->getStoreId();
        $page = $request->input('page', 1);
        $isFirstLoad = $page == 1;

        $products = Product::query()
            ->where('store_id', $storeId)
            ->where('status', 'published')
            ->where('is_variation', 0)
            ->where(function ($query): void {
                $query->where('is_available_in_pos', true)
                    ->orWhereNull('is_available_in_pos');
            })
            ->when($request->input('search'), function ($query, $search) use ($storeId): void {
                $variationWithBarcode = Product::query()
                    ->where('barcode', $search)
                    ->where('status', 'published')
                    ->where('is_variation', 1)
                    ->whereHas('variationInfo.configurableProduct', function ($q) use ($storeId): void {
                        $q->where('store_id', $storeId);
                    })
                    ->with('variationInfo.configurableProduct')
                    ->first();

                if ($variationWithBarcode && $variationWithBarcode->variationInfo->configurableProduct) {
                    $parentProduct = $variationWithBarcode->variationInfo->configurableProduct;
                    $query->where(function ($q) use ($search, $parentProduct): void {
                        $q->where('id', $parentProduct->id)
                            ->orWhere(function ($subQuery) use ($search): void {
                                $subQuery->where('name', 'like', "%{$search}%")
                                    ->orWhere('sku', 'like', "%{$search}%")
                                    ->orWhere('barcode', 'like', "%{$search}%");
                            });
                    });
                } else {
                    $query->where(function ($q) use ($search): void {
                        $q->where('name', 'like', "%{$search}%")
                            ->orWhere('sku', 'like', "%{$search}%")
                            ->orWhere('barcode', 'like', "%{$search}%");
                    });
                }
            })
            ->latest()
            ->paginate(12);

        return $response
            ->setData([
                'html' => view('plugins/pos-pro::partials.products', compact('products', 'isFirstLoad'))->render(),
                'has_more' => $products->hasMorePages(),
                'next_page' => $products->currentPage() + 1,
            ])
            ->setMessage('Products loaded successfully')
            ->toApiResponse();
    }

    public function quickShop($id)
    {
        $storeId = $this->getStoreId();

        $product = Product::query()
            ->where('id', $id)
            ->where('store_id', $storeId)
            ->with([
                'variations.product',
                'variations.productAttributes',
                'productAttributeSets',
            ])
            ->firstOrFail();

        foreach ($product->variations as $variation) {
            if ($variation->product) {
                $variation->product->price_formatted = format_price($variation->product->price);
            }
        }

        return response()->json([
            'error' => false,
            'data' => [
                'html' => view('plugins/pos-pro::partials.quick-shop', compact('product'))->render(),
            ],
            'message' => 'Success',
        ]);
    }

    public function getProductPrice(Request $request, BaseHttpResponse $response)
    {
        $productId = $request->input('product_id');
        $storeId = $this->getStoreId();

        if (! $productId) {
            return $response
                ->setError()
                ->setMessage('Product ID is required')
                ->toApiResponse();
        }

        $product = Product::query()
            ->where('id', $productId)
            ->where('store_id', $storeId)
            ->firstOrFail();

        $priceHtml = view('plugins/ecommerce::themes.includes.product-price', [
            'product' => $product,
        ])->render();

        return $response
            ->setData($priceHtml)
            ->toApiResponse();
    }

    public function getVariation(Request $request, BaseHttpResponse $response)
    {
        try {
            $productId = $request->input('product_id');
            $attributes = $request->input('attributes', []);
            $storeId = $this->getStoreId();

            if (! $productId) {
                return $response
                    ->setError()
                    ->setMessage('Product ID is required')
                    ->toApiResponse();
            }

            $product = Product::query()
                ->where('id', $productId)
                ->where('store_id', $storeId)
                ->with([
                    'variations.product',
                    'variations.productAttributes',
                    'productAttributeSets.attributes',
                ])
                ->firstOrFail();

            $productVariations = $product->variations;
            $productVariationsInfo = ProductVariationItem::getVariationsInfo($productVariations->pluck('id')->all());

            $matchedVariation = null;
            foreach ($product->variations as $variation) {
                $variationAttributes = $variation->productAttributes;

                $variationAttributeMap = [];
                foreach ($variationAttributes as $attr) {
                    $variationAttributeMap[$attr->attribute_set_id] = $attr->id;
                }

                $isMatch = true;
                foreach ($attributes as $setId => $attrId) {
                    if (! isset($variationAttributeMap[$setId]) || $variationAttributeMap[$setId] != $attrId) {
                        $isMatch = false;

                        break;
                    }
                }

                if ($isMatch && count($attributes) == count($variationAttributeMap)) {
                    $matchedVariation = $variation;

                    break;
                }
            }

            $attributeSets = $product->productAttributeSets;
            $availableAttributeIds = [];

            foreach ($attributeSets as $set) {
                $variationInfo = $productVariationsInfo->where('attribute_set_id', $set->id);

                if (isset($attributes[$set->id])) {
                    $selectedAttributeId = $attributes[$set->id];
                    $variationIds = $variationInfo->where('id', $selectedAttributeId)->pluck('variation_id')->toArray();

                    foreach ($attributeSets as $otherSet) {
                        if ($otherSet->id != $set->id) {
                            $availableInSet = $productVariationsInfo
                                ->whereIn('variation_id', $variationIds)
                                ->where('attribute_set_id', $otherSet->id)
                                ->pluck('id')
                                ->toArray();

                            $availableAttributeIds[$otherSet->id] = $availableInSet;
                        }
                    }
                }
            }

            if (! $matchedVariation) {
                return $response
                    ->setData([
                        'variation' => null,
                        'availableAttributes' => $availableAttributeIds,
                    ])
                    ->setMessage('No matching variation found, but available attributes returned')
                    ->toApiResponse();
            }

            return $response
                ->setData([
                    'variation' => $matchedVariation,
                    'availableAttributes' => $availableAttributeIds,
                ])
                ->setMessage('Variation found successfully')
                ->toApiResponse();
        } catch (Exception $e) {
            return $response
                ->setError()
                ->setMessage($e->getMessage())
                ->toApiResponse();
        }
    }

    public function createCustomer(Request $request, BaseHttpResponse $response)
    {
        try {
            $request->validate([
                'name' => ['required', 'string', 'max:255'],
                'email' => ['nullable', 'email', 'unique:ec_customers,email'],
                'phone' => ['required', 'string', 'max:20'],
                'address' => ['nullable', 'string', 'max:255'],
            ]);

            $customer = new Customer();
            $customer->name = $request->input('name');
            $customer->email = $request->input('email') ?: ($request->input('phone') . '@example.com');
            $customer->phone = $request->input('phone');
            $customer->confirmed_at = now();
            $customer->password = bcrypt(Str::random(32));
            $customer->save();

            if ($request->input('address')) {
                $address = new Address([
                    'name' => $customer->name,
                    'phone' => $customer->phone,
                    'email' => $customer->email,
                    'address' => $request->input('address'),
                    'customer_id' => $customer->id,
                    'is_default' => true,
                ]);
                $address->save();
            }

            return $response
                ->setData([
                    'customer' => $customer,
                ])
                ->setMessage(trans('plugins/pos-pro::pos.customer_created_successfully'))
                ->toApiResponse();
        } catch (Exception $e) {
            return $response
                ->setError()
                ->setMessage($e->getMessage())
                ->toApiResponse();
        }
    }

    public function searchCustomers(Request $request, BaseHttpResponse $response)
    {
        $storeId = $this->getStoreId();
        $keyword = $request->input('q');
        $page = (int) $request->input('page', 1);
        $perPage = 20;

        $query = Customer::query()
            ->select(['ec_customers.id', 'ec_customers.name', 'ec_customers.email', 'ec_customers.phone'])
            ->whereHas('orders', function ($q) use ($storeId): void {
                $q->where('store_id', $storeId);
            })
            ->oldest('name');

        if ($keyword) {
            $query->where(function (Builder $q) use ($keyword): void {
                $q->where('name', 'LIKE', "%{$keyword}%")
                    ->orWhere('email', 'LIKE', "%{$keyword}%")
                    ->orWhere('phone', 'LIKE', "%{$keyword}%");
            });
        }

        $customers = $query->paginate($perPage, ['*'], 'page', $page);

        return $response->setData([
            'results' => $customers->map(fn ($c) => [
                'id' => $c->id,
                'text' => $c->name . ' (' . $c->phone . ')',
                'name' => $c->name,
                'phone' => $c->phone,
                'email' => $c->email,
            ])->toArray(),
            'pagination' => ['more' => $customers->hasMorePages()],
        ]);
    }

    public function getCustomerAddresses($customerId, BaseHttpResponse $response)
    {
        $customer = Customer::query()->find($customerId);

        if (! $customer) {
            return $response
                ->setError()
                ->setMessage(trans('plugins/pos-pro::pos.customer_not_found'))
                ->toApiResponse();
        }

        $addresses = $customer->addresses()
            ->orderByDesc('is_default')
            ->get()
            ->map(function ($address) {
                return [
                    'id' => $address->id,
                    'name' => $address->name,
                    'phone' => $address->phone,
                    'email' => $address->email,
                    'country' => $address->country,
                    'state' => $address->state,
                    'city' => $address->city,
                    'address' => $address->address,
                    'zip_code' => $address->zip_code,
                    'is_default' => $address->is_default,
                ];
            });

        return $response
            ->setData($addresses)
            ->toApiResponse();
    }

    public function switchLanguage(string $locale): RedirectResponse
    {
        if (Language::getActiveLanguage()->where('lang_code', $locale)->count() > 0) {
            Session::put('pos_locale', $locale);
            app()->setLocale($locale);

            return redirect()->back();
        }

        return redirect()->back();
    }

    public function switchCurrency(string $currency): RedirectResponse
    {
        $currencyModel = CurrencyModel::query()->where('title', $currency)->first();

        if ($currencyModel) {
            Currency::setApplicationCurrency($currencyModel);
        }

        return redirect()->back();
    }

    public function getAddressForm(Request $request, BaseHttpResponse $response)
    {
        $customerId = $request->input('customer_id');

        $sessionCheckoutData = [];
        $addresses = collect();
        $isAvailableAddress = false;
        $sessionAddressId = null;

        if ($customerId) {
            $customer = Customer::query()->find($customerId);
            if ($customer) {
                $addresses = $customer->addresses;
                $isAvailableAddress = ! $addresses->isEmpty();

                if ($isAvailableAddress) {
                    $defaultAddress = $addresses->firstWhere('is_default') ?: $addresses->first();
                    $sessionAddressId = $defaultAddress->id;

                    $sessionCheckoutData = [
                        'name' => $defaultAddress->name,
                        'email' => $defaultAddress->email,
                        'phone' => $defaultAddress->phone,
                        'address' => $defaultAddress->address,
                        'country' => $defaultAddress->country,
                        'state' => $defaultAddress->state,
                        'city' => $defaultAddress->city,
                        'zip_code' => $defaultAddress->zip_code,
                    ];
                } else {
                    $sessionCheckoutData = [
                        'name' => $customer->name,
                        'email' => $customer->email,
                        'phone' => $customer->phone,
                    ];
                }
            }
        }

        $model = compact('sessionCheckoutData', 'addresses', 'isAvailableAddress', 'sessionAddressId');

        $html = view('plugins/pos-pro::partials.address-form', $model)->render();

        return $response
            ->setData(['html' => $html])
            ->toApiResponse();
    }
}
