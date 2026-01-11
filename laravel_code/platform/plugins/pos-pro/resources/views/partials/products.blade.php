@if(isset($isFirstLoad) && $isFirstLoad)
<div class="products-container">
@endif

@if($products->isEmpty() && request()->input('search'))
    <div class="col-12">
        <div class="empty">
            <div class="empty-icon">
                <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
                    <path stroke="none" d="M0 0h24v24H0z" fill="none" />
                    <circle cx="10" cy="10" r="7" />
                    <line x1="21" y1="21" x2="15" y2="15" />
                </svg>
            </div>
            <p class="empty-title">{{ trans('plugins/pos-pro::pos.no_products_found') }}</p>
            <p class="empty-subtitle text-secondary">
                {{ trans('plugins/pos-pro::pos.try_different_search') }}
            </p>
            <div class="empty-action">
                <button type="button" class="btn btn-primary" id="clear-search">
                    <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
                        <path stroke="none" d="M0 0h24v24H0z" fill="none" />
                        <circle cx="10" cy="10" r="7" />
                        <line x1="21" y1="21" x2="15" y2="15" />
                    </svg>
                    {{ trans('plugins/pos-pro::pos.search_again') }}
                </button>
            </div>
        </div>
    </div>
@else
    @foreach($products as $product)
        <div class="col-lg-3 col-md-4 col-sm-6 mb-3">
            <div class="card h-100 product-card" data-product-id="{{ $product->id }}">
                <div class="card-img-top text-center pt-2">
                    <img src="{{ RvMedia::getImageUrl($product->image) }}" alt="{{ $product->name }}" class="img-fluid">
                </div>
                <div class="card-body p-2">
                    <div class="d-flex align-items-center mb-1">
                        @php
                            $stockStatusClass = match($product->stock_status->getValue()) {
                                'out_of_stock' => 'bg-red-lt',
                                'on_backorder' => 'bg-yellow-lt',
                                default => 'bg-green-lt'
                            };
                        @endphp
                        <span class="badge badge-pill {{ $stockStatusClass }} me-1">
                            {{ $product->stock_status_label }}
                        </span>
                        <span class="text-muted small">{{ $product->sku }}</span>
                    </div>
                    @if($product->barcode)
                    <div class="d-flex align-items-center mb-1">
                        <span class="badge badge-pill bg-blue-lt me-1">
                            <x-core::icon name="ti ti-barcode" class="me-1" />
                        </span>
                        <span class="text-muted small">{{ $product->barcode }}</span>
                    </div>
                    @endif
                    <h3 class="card-title product-name h5 mb-1" data-bs-toggle="tooltip" title="{{ $product->name }}">{{ $product->name }}</h3>
                    <div class="d-flex justify-content-between align-items-center mt-1">
                        @include('plugins/ecommerce::themes.includes.product-price', [
                            'product' => $product,
                            'priceWrapperClassName' => 'mb-0',
                            'priceClassName' => 'h5 mb-0 text-primary'
                        ])
                        @if($product->with_storehouse_management)
                            <span class="badge badge-outline text-azure badge-pill" data-bs-toggle="tooltip" title="{{ trans('plugins/pos-pro::pos.available_quantity') }}">
                                <x-core::icon name="ti ti-box" class="me-1" />
                                @if($product->variations->isEmpty())
                                    {{ $product->quantity }}
                                @else
                                    @php
                                        $withStoreHouseManagement = $product->with_storehouse_management;
                                        $quantity = 0;
                                        foreach ($product->variations as $variation) {
                                            if (!$variation->product->with_storehouse_management) {
                                                $withStoreHouseManagement = false;
                                                break;
                                            }
                                            $quantity += $variation->product->quantity;
                                        }
                                    @endphp
                                    {{ $withStoreHouseManagement ? $quantity : '∞' }}
                                @endif
                            </span>
                        @endif
                    </div>
                </div>
                <div class="card-footer bg-transparent border-top-0 p-2">
                    <button type="button"
                        class="btn btn-primary btn-sm w-100 add-to-cart"
                        data-product-id="{{ $product->id }}"
                        data-has-variations="{{ $product->variations->isNotEmpty() ? 'true' : 'false' }}"
                        data-url="{{ route(($routePrefix ?? 'pos-pro') . '.cart.add') }}"
                        {{ $product->isOutOfStock() && !$product->allow_checkout_when_out_of_stock ? 'disabled' : '' }}>
                        <x-core::icon name="ti ti-shopping-cart-plus" class="me-1" />
                        @if($product->variations->isNotEmpty())
                            {{ trans('plugins/pos-pro::pos.select_options') }}
                        @else
                            {{ trans('plugins/pos-pro::pos.add_to_cart') }}
                        @endif
                    </button>
                </div>
            </div>
        </div>
    @endforeach
@endif

@if(isset($isFirstLoad) && $isFirstLoad)
</div>

@if($products->hasMorePages())
    <div class="col-12 text-center mt-3 load-more-container">
        <div class="load-more-loading d-none">
            <div class="spinner-border text-primary" role="status">
                <span class="visually-hidden">{{ trans('plugins/pos-pro::pos.loading') }}</span>
            </div>
        </div>
    </div>
@endif

<!-- Quick Shop Modal -->
<x-core::modal
    id="quick-shop-modal"
    :title="trans('plugins/pos-pro::pos.select_options')"
    :centered="true"
    :body-attrs="['class' => 'p-4']"
    :content-class="'p-4'"
>
    <div id="quick-shop-content">
        <!-- Content will be loaded dynamically -->
    </div>
</x-core::modal>
@endif
