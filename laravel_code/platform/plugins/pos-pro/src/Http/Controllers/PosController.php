<?php

namespace Botble\PosPro\Http\Controllers;

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
use Botble\PosPro\Services\OrderSlotService;
use Botble\PosPro\Services\RegisterService;
use Botble\PosPro\Tables\PosOrderTable;
use Exception;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Str;

class PosController extends BaseController
{
    public function __construct(
        protected CartService $cartService,
        protected OrderSlotService $orderSlotService,
        protected RegisterService $registerService
    ) {
    }

    public function customerDisplay()
    {
        return view('plugins/pos-pro::customer');
    }

    public function index()
    {
        $this->pageTitle(trans('plugins/pos-pro::pos.name'));

        $products = Product::query()
            ->where('status', 'published')
            ->where('is_variation', 0)
            ->where(function ($query): void {
                $query->where('is_available_in_pos', true)
                    ->orWhereNull('is_available_in_pos');
            })
            ->latest()
            ->paginate(12);

        $customers = Customer::query()
            ->oldest('name')
            ->get();

        $sessionPrefix = $this->orderSlotService->getSessionPrefix();
        $orderSlots = $this->orderSlotService->getSlotsWithCarts($this->cartService);
        $activeSlot = $this->orderSlotService->getActiveSlot();

        $cart = $this->cartService->getCart($sessionPrefix);
        $cart['html'] = view('plugins/pos-pro::partials.cart', [
            'cart' => $cart,
            'customers' => $customers,
            'orderSlots' => $orderSlots,
            'activeSlot' => $activeSlot,
        ])->render();

        $user = auth()->user();

        $posContext = [
            'user' => [
                'name' => $user->name,
                'email' => $user->email,
                'avatar_url' => $user->avatar_url,
            ],
            'urls' => [
                'dashboard' => route('dashboard.index'),
                'profile' => route('users.profile.view', $user->id),
                'logout' => route('access.logout'),
            ],
        ];

        $registerStatus = $this->registerService->getRegisterStatus($user->id);

        return view('plugins/pos-pro::index', compact('products', 'customers', 'cart', 'posContext', 'registerStatus'));
    }

    public function scanBarcode(Request $request, BaseHttpResponse $response)
    {
        $barcode = $request->input('barcode');

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

            if (! $parentProduct) {
                return $response
                    ->setError()
                    ->setMessage(trans('plugins/pos-pro::pos.product_not_available_in_pos'))
                    ->toApiResponse();
            }

            if ($parentProduct->is_available_in_pos === false) {
                return $response
                    ->setError()
                    ->setMessage(trans('plugins/pos-pro::pos.product_not_available_in_pos'))
                    ->toApiResponse();
            }

            try {
                $result = $this->cartService->addToCart($product->id, 1);

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
            if ($product->is_available_in_pos === false) {
                return $response
                    ->setError()
                    ->setMessage(trans('plugins/pos-pro::pos.product_not_available_in_pos'))
                    ->toApiResponse();
            }

            if ($product->variations->isEmpty()) {
                try {
                    $result = $this->cartService->addToCart($product->id, 1);

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
        $page = $request->input('page', 1);
        $isFirstLoad = $page == 1;

        $products = Product::query()
            ->where('status', 'published')
            ->where('is_variation', 0)
            ->where(function ($query): void {
                $query->where('is_available_in_pos', true)
                    ->orWhereNull('is_available_in_pos');
            })
            ->when($request->input('search'), function ($query, $search): void {
                $variationWithBarcode = Product::query()
                    ->where('barcode', $search)
                    ->where('status', 'published')
                    ->where('is_variation', 1)
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
            })->latest()
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

    public function addToCart(Request $request, BaseHttpResponse $response)
    {
        try {
            $result = $this->cartService->addToCart(
                $request->input('product_id'),
                $request->input('quantity', 1)
            );

            $result['cart']['html'] = view('plugins/pos-pro::partials.cart', ['cart' => $result['cart']])->render();

            return $response
                ->setData($result)
                ->toApiResponse();
        } catch (Exception $e) {
            return $response
                ->setError()
                ->setMessage($e->getMessage())
                ->toApiResponse();
        }
    }

    public function updateQuantity(Request $request, BaseHttpResponse $response)
    {
        try {
            $result = $this->cartService->updateQuantity(
                $request->input('product_id'),
                $request->input('quantity')
            );

            $result['cart']['html'] = view('plugins/pos-pro::partials.cart', ['cart' => $result['cart']])->render();

            return $response
                ->setData($result)
                ->toApiResponse();
        } catch (Exception $e) {
            return $response
                ->setError()
                ->setMessage($e->getMessage())
                ->toApiResponse();
        }
    }

    public function removeFromCart(Request $request, BaseHttpResponse $response)
    {
        try {
            $result = $this->cartService->removeFromCart($request->input('product_id'));

            $result['cart']['html'] = view('plugins/pos-pro::partials.cart', ['cart' => $result['cart']])->render();

            return $response
                ->setData($result)
                ->toApiResponse();
        } catch (Exception $e) {
            return $response
                ->setError()
                ->setMessage($e->getMessage())
                ->toApiResponse();
        }
    }

    public function getCart(BaseHttpResponse $response)
    {
        $cart = $this->cartService->getCart();
        $cart['html'] = view('plugins/pos-pro::partials.cart', ['cart' => $cart])->render();

        return $response
            ->setData(['cart' => $cart])
            ->toApiResponse();
    }

    public function quickShop($id)
    {
        $product = Product::query()
            ->where('id', $id)
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

        if (! $productId) {
            return $response
                ->setError()
                ->setMessage('Product ID is required')
                ->toApiResponse();
        }

        $product = Product::query()
            ->where('id', $productId)
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

            if (! $productId) {
                return $response
                    ->setError()
                    ->setMessage('Product ID is required')
                    ->toApiResponse();
            }

            $product = Product::query()
                ->where('id', $productId)
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
        $keyword = $request->input('q');
        $page = (int) $request->input('page', 1);
        $perPage = 20; // Increased to show more customers

        $query = Customer::query()
            ->select(['id', 'name', 'email', 'phone'])
            ->oldest('name');

        if ($keyword) {
            $query->where(function (Builder $query) use ($keyword): void {
                $query->where('name', 'LIKE', "%{$keyword}%")
                    ->orWhere('email', 'LIKE', "%{$keyword}%")
                    ->orWhere('phone', 'LIKE', "%{$keyword}%");
            });
        }

        $customers = $query->paginate($perPage, ['*'], 'page', $page);

        $data = [
            'results' => $customers->map(function ($customer) {
                return [
                    'id' => $customer->id,
                    'text' => $customer->name . ' (' . $customer->phone . ')',
                    'name' => $customer->name,
                    'phone' => $customer->phone,
                    'email' => $customer->email,
                ];
            })->toArray(),
            'pagination' => [
                'more' => $customers->hasMorePages(),
            ],
        ];

        return $response->setData($data);
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

    public function orders(PosOrderTable $table)
    {
        $this->pageTitle(trans('plugins/pos-pro::pos.orders'));

        return $table->renderTable();
    }
}
