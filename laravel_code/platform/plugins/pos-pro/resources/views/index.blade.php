@extends('plugins/pos-pro::layouts.master')

@php
    $routePrefix = $routePrefix ?? 'pos-pro';
@endphp

@section('content')
    <div id="pos-container"
        data-cart-add-url="{{ route($routePrefix . '.cart.add') }}"
        data-cart-update-url="{{ route($routePrefix . '.cart.update') }}"
        data-cart-remove-url="{{ route($routePrefix . '.cart.remove') }}"
        data-cart-clear-url="{{ route($routePrefix . '.cart.clear') }}"
        data-cart-apply-coupon-url="{{ route($routePrefix . '.cart.apply-coupon') }}"
        data-cart-remove-coupon-url="{{ route($routePrefix . '.cart.remove-coupon') }}"
        data-cart-update-shipping-url="{{ route($routePrefix . '.cart.update-shipping') }}"
        data-cart-update-manual-discount-url="{{ route($routePrefix . '.cart.update-manual-discount') }}"
        data-cart-remove-manual-discount-url="{{ route($routePrefix . '.cart.remove-manual-discount') }}"
        data-cart-update-customer-url="{{ route($routePrefix . '.cart.update-customer') }}"
        data-cart-update-payment-method-url="{{ route($routePrefix . '.cart.update-payment-method') }}"
        data-cart-reset-customer-payment-url="{{ route($routePrefix . '.cart.reset-customer-payment') }}"
        data-products-url="{{ route($routePrefix . '.products') }}"
        data-quick-shop-url="{{ route($routePrefix . '.quick-shop', ':id') }}"
        data-checkout-url="{{ route($routePrefix . '.checkout') }}"
        data-receipt-url="{{ route($routePrefix . '.receipt', ':id') }}"
        data-create-customer-url="{{ route($routePrefix . '.create-customer') }}"
        data-search-customers-url="{{ route($routePrefix . '.search-customers') }}"
        data-get-variation-url="{{ route($routePrefix . '.get-variation') }}"
        data-product-price-url="{{ route($routePrefix . '.product-price') }}"
        data-customer-addresses-url="{{ route($routePrefix . '.customers.addresses.list', ['id' => '__id__']) }}"
        data-address-form-url="{{ route($routePrefix . '.address-form') }}"
        data-scan-barcode-url="{{ route($routePrefix . '.scan-barcode') }}"
        data-order-slots-url="{{ route($routePrefix . '.order-slots.index') }}"
        data-order-slots-create-url="{{ route($routePrefix . '.order-slots.create') }}"
        data-order-slots-switch-url="{{ route($routePrefix . '.order-slots.switch') }}"
        data-order-slots-close-url="{{ route($routePrefix . '.order-slots.close') }}"
        data-register-status-url="{{ route($routePrefix . '.register.status') }}"
        data-register-open-url="{{ route($routePrefix . '.register.open') }}"
        data-register-close-url="{{ route($routePrefix . '.register.close') }}"
        data-register-is-open="{{ isset($registerStatus) && $registerStatus['is_open'] ? 'true' : 'false' }}">
        <div class="row">
            <!-- Cart Section - Will appear on top on mobile -->
            <div class="col-md-4 order-1 order-md-2 mb-3 mb-md-0">
                <x-core::card>
                    <x-core::card.header>
                        <div class="d-flex justify-content-between align-items-center w-100">
                            <div class="d-flex align-items-center">
                                <x-core::icon name="ti ti-shopping-cart" class="me-2" />
                                <x-core::card.title>{{ trans('plugins/pos-pro::pos.cart') }}</x-core::card.title>
                            </div>
                            <x-core::card.actions>
                                <button type="button" id="clear-cart" class="btn btn-ghost-danger btn-icon" {{ $cart['count'] === 0 ? 'disabled' : '' }} title="{{ trans('plugins/pos-pro::pos.clear_cart') }}" data-bs-toggle="tooltip">
                                    <x-core::icon name="ti ti-trash" />
                                </button>
                            </x-core::card.actions>
                        </div>
                    </x-core::card.header>
                    <x-core::card.body class="p-0">
                        <div class="cart-container">
                            <!-- Cart Items -->
                            <div class="cart-items-wrapper">
                                <div id="cart-items">
                                    @include('plugins/pos-pro::partials.cart', ['cart' => $cart, 'customers' => $customers])
                                </div>
                            </div>

                            <!-- Order Notes container - will be shown/hidden by JavaScript -->
                            <div class="mb-3 notes-container" style="{{ $cart['count'] > 0 ? '' : 'display: none;' }}">
                                <div class="card card-sm">
                                    <div class="card-body">
                                        <h3 class="card-title text-muted fs-6">
                                            <x-core::icon name="ti ti-notes" class="me-1" />
                                            {{ trans('plugins/pos-pro::pos.notes') }}
                                        </h3>
                                        <textarea id="order-notes" class="form-control" rows="2" placeholder="{{ trans('plugins/pos-pro::pos.enter_notes') }}"></textarea>
                                    </div>
                                </div>
                            </div>

                            <!-- Checkout Button -->
                            <div class="px-3 pb-3">
                                <x-core::button type="button" id="checkout-button" color="primary" class="w-100 btn-lg" :disabled="$cart['count'] === 0">
                                    <x-core::icon name="ti ti-cash-register" class="me-1" /> {{ trans('plugins/pos-pro::pos.checkout') }}
                                </x-core::button>
                            </div>
                        </div>
                    </x-core::card.body>
                </x-core::card>
            </div>

            <!-- Products Section - Will appear below cart on mobile -->
            <div class="col-md-8 order-2 order-md-1">
                <x-core::card>
                    <x-core::card.header>
                        <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center w-100 gap-2">
                            <x-core::card.title>{{ trans('plugins/pos-pro::pos.products') }}</x-core::card.title>
                            <div class="d-flex flex-grow-1 flex-md-grow-0">
                                <div class="barcode-scanner-button me-2">
                                    <x-core::button type="button" id="toggle-barcode-scanner" color="secondary" class="btn-icon" data-bs-toggle="tooltip" title="{{ trans('plugins/pos-pro::pos.scan_barcode') }}">
                                        <x-core::icon name="ti ti-barcode" />
                                    </x-core::button>
                                </div>
                                <div class="input-icon flex-grow-1">
                                    <input type="text" id="search-product" class="form-control" placeholder="{{ trans('plugins/pos-pro::pos.search_products_by_name_sku_barcode') }}">
                                    <span class="input-icon-addon" id="search-icon-addon" role="button">
                                        <x-core::icon name="ti ti-search" id="search-icon" />
                                    </span>
                                </div>
                            </div>
                        </div>
                    </x-core::card.header>
                    <x-core::card.body>
                        <!-- Barcode Scanner Container -->
                        <div id="barcode-scanner-container" class="barcode-scanner-container mb-3"></div>

                        <div id="products-grid" class="row">
                            @include('plugins/pos-pro::partials.products', ['products' => $products])
                        </div>
                    </x-core::card.body>
                </x-core::card>
            </div>
        </div>
    </div>
</div>

<!-- Quick Shop Modal -->
<x-core::modal id="quick-shop-modal" :title="trans('plugins/pos-pro::pos.select_options')" class="modal-dialog-padded">
    <!-- Content will be loaded dynamically -->
</x-core::modal>

<!-- Add Customer Modal -->
@include('plugins/pos-pro::partials.add-customer-modal')

<!-- Coupon Modal -->
@include('plugins/pos-pro::partials.modals.coupon-modal')

<!-- Discount Modal -->
@include('plugins/pos-pro::partials.modals.discount-modal')

<!-- Shipping Modal -->
@include('plugins/pos-pro::partials.modals.shipping-modal')

<!-- Clear Cart Confirmation Modal -->
@include('plugins/pos-pro::partials.modals.clear-cart-modal')

<!-- Success Modal -->
@include('plugins/pos-pro::partials.success-modal')

<!-- Checkout Modal -->
@include('plugins/pos-pro::partials.checkout-modal')

<!-- Register Modals -->
@include('plugins/pos-pro::partials.register-modal')
@stop

@push('footer')
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            window.initialCart = @json($cart);
            window.currency = '{{ get_application_currency()->title }}';
            window.currencySymbol = '{{ get_application_currency()->symbol }}';
            window.currencyIsPrefix = {{ get_application_currency()->is_prefix_symbol ? 'true' : 'false' }};

            // Update currency information after page load
            document.dispatchEvent(new CustomEvent('pos-pro.currency.updated', {
                detail: {
                    currency: window.currency,
                    symbol: window.currencySymbol,
                    isPrefix: window.currencyIsPrefix
                }
            }));

            // Define translations
            window.trans = {
                'plugins/pos-pro::pos.please_enter_coupon_code': '{{ trans('plugins/pos-pro::pos.please_enter_coupon_code') }}',
                'plugins/pos-pro::pos.discount_amount': '{{ trans('plugins/pos-pro::pos.discount_amount') }}',
                'plugins/pos-pro::pos.subtotal': '{{ trans('plugins/pos-pro::pos.subtotal') }}',
                'plugins/pos-pro::pos.shipping': '{{ trans('plugins/pos-pro::pos.shipping') }}',
                'plugins/pos-pro::pos.invalid_discount_amount': '{{ trans('plugins/pos-pro::pos.invalid_discount_amount') }}',
                'plugins/pos-pro::pos.invalid_shipping_amount': '{{ trans('plugins/pos-pro::pos.invalid_shipping_amount') }}',
                'plugins/pos-pro::pos.guest': '{{ trans('plugins/pos-pro::pos.guest') }}',
                'plugins/pos-pro::pos.cash': '{{ trans('plugins/pos-pro::pos.cash') }}',
                'plugins/pos-pro::pos.manual_discount': '{{ trans('plugins/pos-pro::pos.manual_discount') }}',
                'plugins/pos-pro::pos.address': '{{ trans('plugins/pos-pro::pos.address') }}',
                'plugins/pos-pro::pos.city': '{{ trans('plugins/pos-pro::pos.city') }}',
                'plugins/pos-pro::pos.state': '{{ trans('plugins/pos-pro::pos.state') }}',
                'plugins/pos-pro::pos.country': '{{ trans('plugins/pos-pro::pos.country') }}',
                'plugins/pos-pro::pos.zip_code': '{{ trans('plugins/pos-pro::pos.zip_code') }}',
                'plugins/pos-pro::pos.select_address': '{{ trans('plugins/pos-pro::pos.select_address') }}',
                'plugins/pos-pro::pos.order_address_information': '{{ trans('plugins/pos-pro::pos.order_address_information') }}',
                'plugins/pos-pro::pos.selected_address': '{{ trans('plugins/pos-pro::pos.selected_address') }}',
                'plugins/pos-pro::pos.custom_address': '{{ trans('plugins/pos-pro::pos.custom_address') }}',
                'plugins/pos-pro::pos.no_addresses_available': '{{ trans('plugins/pos-pro::pos.no_addresses_available') }}',
                'plugins/pos-pro::pos.loading_addresses': '{{ trans('plugins/pos-pro::pos.loading_addresses') }}',
                'plugins/pos-pro::pos.select_or_enter_address': '{{ trans('plugins/pos-pro::pos.select_or_enter_address') }}',
                'plugins/pos-pro::pos.address_address': '{{ trans('plugins/pos-pro::pos.address_address') }}',
                'plugins/pos-pro::pos.address_city': '{{ trans('plugins/pos-pro::pos.address_city') }}',
                'plugins/pos-pro::pos.address_state': '{{ trans('plugins/pos-pro::pos.address_state') }}',
                'plugins/pos-pro::pos.address_country': '{{ trans('plugins/pos-pro::pos.address_country') }}',
                'plugins/pos-pro::pos.address_zip_code': '{{ trans('plugins/pos-pro::pos.address_zip_code') }}',
                'plugins/pos-pro::pos.loading': '{{ trans('plugins/pos-pro::pos.loading') }}',
                'plugins/pos-pro::pos.loading_address_form': '{{ trans('plugins/pos-pro::pos.loading_address_form') }}',
                'plugins/pos-pro::pos.address_form_load_error': '{{ trans('plugins/pos-pro::pos.address_form_load_error') }}',
                'plugins/pos-pro::pos.pickup_in_store_help': '{{ trans('plugins/pos-pro::pos.pickup_in_store_help') }}',
                'plugins/pos-pro::pos.ship_to_address_help': '{{ trans('plugins/pos-pro::pos.ship_to_address_help') }}',
                'plugins/pos-pro::pos.confirm_close_order': '{{ trans('plugins/pos-pro::pos.confirm_close_order') }}'
            };

            // Define BotbleVariables for notifications
            window.BotbleVariables = window.BotbleVariables || {
                languages: {
                    notices_msg: {
                        error: '{{ trans('core/base::notices.error_header') }}',
                        success: '{{ trans('core/base::notices.success_header') }}'
                    }
                }
            };
        });
    </script>
@endpush
