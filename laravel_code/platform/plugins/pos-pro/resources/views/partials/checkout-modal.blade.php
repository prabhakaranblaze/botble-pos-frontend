<x-core::modal
    id="checkout-modal"
    :title="trans('plugins/pos-pro::pos.checkout')"
    size="xl"
    class="checkout-modal-responsive"
>
    <form id="checkout-form">
        <div class="row g-3">
            <!-- Order Information - Will stack on mobile -->
            <div class="col-lg-8 col-md-12">
                <x-core::card>
                    <x-core::card.header class="bg-light-subtle">
                        <x-core::card.title>
                            <div class="d-flex align-items-center">
                                <x-core::icon name="ti ti-clipboard-list" class="me-2 text-primary" />
                                {{ trans('plugins/pos-pro::pos.order_information') }}
                            </div>
                        </x-core::card.title>
                    </x-core::card.header>
                    <x-core::card.body>
                        <x-core::datagrid>
                            <!-- Customer Information -->
                            <x-core::datagrid.item>
                                <x-slot:title>
                                    <div class="d-flex align-items-center">
                                        <x-core::icon name="ti ti-user" class="me-1 text-primary" />
                                        {{ trans('plugins/pos-pro::pos.customer') }}
                                    </div>
                                </x-slot:title>
                                <div id="checkout-customer-info" class="d-flex align-items-center">
                                    <x-core::icon name="ti ti-user-circle" class="me-1 text-muted" />
                                    {{ trans('plugins/pos-pro::pos.guest') }}
                                </div>
                                <!-- Hidden input to store customer ID -->
                                <input type="hidden" id="checkout-customer-id" name="customer_id" value="">
                            </x-core::datagrid.item>

                            <!-- Customer Address Information -->
                            <x-core::datagrid.item id="customer-address-section">
                                <x-slot:title>
                                    <div class="d-flex align-items-center w-100">
                                        <x-core::icon name="ti ti-map-pin" class="me-1 text-primary" />
                                        <span class="text-nowrap">{{ trans('plugins/pos-pro::pos.address') }}</span>
                                    </div>
                                </x-slot:title>
                                <div id="address-form-container">
                                    <!-- Address form will be loaded dynamically -->
                                    <div class="text-center py-3">
                                        <div class="spinner-border spinner-border-sm text-primary" role="status">
                                            <span class="visually-hidden">{{ trans('plugins/pos-pro::pos.loading') }}...</span>
                                        </div>
                                        <div class="mt-2 text-muted">{{ trans('plugins/pos-pro::pos.loading_address_form') }}</div>
                                    </div>
                                </div>
                            </x-core::datagrid.item>

                            <!-- Shipping Option -->
                            <x-core::datagrid.item>
                                <x-slot:title>
                                    <div class="d-flex align-items-center">
                                        <x-core::icon name="ti ti-truck" class="me-1 text-primary" />
                                        {{ trans('plugins/pos-pro::pos.delivery_option') }}
                                    </div>
                                </x-slot:title>
                                <div class="w-100">
                                    <div class="row g-2">
                                        <div class="col-md-6 col-12">
                                            <label class="form-check form-check-inline">
                                                <input class="form-check-input" type="radio" name="delivery_option" value="pickup" checked>
                                                <span class="form-check-label">
                                                    <x-core::icon name="ti ti-building-store" class="me-1 text-success" />
                                                    {{ trans('plugins/pos-pro::pos.pickup_in_store') }}
                                                </span>
                                            </label>
                                        </div>
                                        <div class="col-md-6 col-12">
                                            <label class="form-check form-check-inline">
                                                <input class="form-check-input" type="radio" name="delivery_option" value="shipping">
                                                <span class="form-check-label">
                                                    <x-core::icon name="ti ti-truck-delivery" class="me-1 text-info" />
                                                    {{ trans('plugins/pos-pro::pos.ship_to_address') }}
                                                </span>
                                            </label>
                                        </div>
                                    </div>
                                    <div class="mt-2">
                                        <small class="text-muted" id="delivery-option-help">
                                            {{ trans('plugins/pos-pro::pos.pickup_in_store_help') }}
                                        </small>
                                    </div>
                                </div>
                            </x-core::datagrid.item>

                            <!-- Payment Method Information -->
                            <x-core::datagrid.item>
                                <x-slot:title>
                                    <div class="d-flex align-items-center">
                                        <x-core::icon name="ti ti-credit-card" class="me-1 text-primary" />
                                        {{ trans('plugins/pos-pro::pos.payment_method') }}
                                    </div>
                                </x-slot:title>
                                <div id="checkout-payment-method-info" class="d-flex align-items-center">
                                    <x-core::icon name="ti ti-cash" class="me-1 text-success" />
                                    {{ trans('plugins/pos-pro::pos.cash') }}
                                </div>
                                <!-- Hidden input to store payment method -->
                                <input type="hidden" id="checkout-payment-method" name="payment_method" value="cash">
                            </x-core::datagrid.item>

                            <!-- Notes -->
                            <x-core::datagrid.item>
                                <x-slot:title>
                                    <div class="d-flex align-items-center">
                                        <x-core::icon name="ti ti-notes" class="me-1 text-primary" />
                                        {{ trans('plugins/pos-pro::pos.notes') }}
                                    </div>
                                </x-slot:title>
                                <div class="w-100">
                                    <textarea class="form-control" name="notes" rows="4" style="min-height: 100px;" placeholder="{{ trans('plugins/pos-pro::pos.notes_placeholder') }}"></textarea>
                                </div>
                            </x-core::datagrid.item>
                        </x-core::datagrid>
                    </x-core::card.body>
                </x-core::card>
            </div>

            <!-- Order Summary - Will stack on mobile -->
            <div class="col-lg-4 col-md-12">
                <x-core::card class="shadow-sm order-summary-card">
                    <x-core::card.header class="bg-primary-subtle">
                        <x-core::card.title>
                            <div class="d-flex align-items-center">
                                <x-core::icon name="ti ti-receipt" class="me-2 text-primary" />
                                {{ trans('plugins/pos-pro::pos.order_summary') }}
                            </div>
                        </x-core::card.title>
                    </x-core::card.header>
                    <x-core::card.body>
                        <x-core::datagrid>
                            <x-core::datagrid.item>
                                <x-slot:title>{{ trans('plugins/pos-pro::pos.subtotal') }}</x-slot:title>
                                <div id="modal-subtotal">{{ format_price($cart['subtotal']) }}</div>
                            </x-core::datagrid.item>

                            <x-core::datagrid.item>
                                <x-slot:title>{{ trans('plugins/pos-pro::pos.tax') }}</x-slot:title>
                                <div id="modal-tax">{{ format_price($cart['tax']) }}</div>
                            </x-core::datagrid.item>

                            <x-core::datagrid.item>
                                <x-slot:title>{{ trans('plugins/pos-pro::pos.shipping') }}</x-slot:title>
                                <div id="modal-shipping">{{ format_price($cart['shipping_amount'] ?? 0) }}</div>
                            </x-core::datagrid.item>

                            @if(isset($cart['coupon_discount']) && $cart['coupon_discount'] > 0)
                            <x-core::datagrid.item>
                                <x-slot:title>
                                    <div class="d-flex align-items-center">
                                        <x-core::icon name="ti ti-discount-check" class="me-1 text-primary" />
                                        {{ trans('plugins/pos-pro::pos.coupon_discount') }}
                                        @if(isset($cart['coupon_code']))
                                            <x-core::badge color="primary" lite class="ms-1">{{ $cart['coupon_code'] }}</x-core::badge>
                                        @endif
                                    </div>
                                </x-slot:title>
                                <div class="text-danger">-{{ format_price($cart['coupon_discount']) }}</div>
                            </x-core::datagrid.item>
                            @endif

                            {{-- Manual discount is dynamically added by JavaScript --}}

                            <x-core::datagrid.item>
                                <x-slot:title>
                                    <div class="fw-bold">{{ trans('plugins/pos-pro::pos.total') }}</div>
                                </x-slot:title>
                                <div class="fw-bold fs-4 text-primary" id="modal-total">{{ format_price($cart['total']) }}</div>
                            </x-core::datagrid.item>
                        </x-core::datagrid>
                    </x-core::card.body>
                </x-core::card>

                <!-- Cash Payment Section - Only visible for cash payment -->
                <x-core::card class="shadow-sm mt-3" id="cash-payment-section">
                    <x-core::card.header class="bg-success-subtle">
                        <x-core::card.title>
                            <div class="d-flex align-items-center">
                                <x-core::icon name="ti ti-cash" class="me-2 text-success" />
                                {{ trans('plugins/pos-pro::pos.cash_payment') }}
                            </div>
                        </x-core::card.title>
                    </x-core::card.header>
                    <x-core::card.body>
                        <!-- Cash Received Input -->
                        <div class="mb-3">
                            <label class="form-label fw-medium">{{ trans('plugins/pos-pro::pos.cash_received') }}</label>
                            <div class="input-group input-group-lg">
                                <span class="input-group-text">{{ get_application_currency()->symbol }}</span>
                                <input type="number"
                                    class="form-control form-control-lg text-end fw-bold"
                                    id="cash-received-input"
                                    name="cash_received"
                                    min="0"
                                    step="0.01"
                                    placeholder="0.00"
                                    autocomplete="off">
                            </div>
                        </div>

                        <!-- Quick Cash Buttons -->
                        <div class="mb-3">
                            <label class="form-label text-muted small">{{ trans('plugins/pos-pro::pos.quick_cash') }}</label>
                            <div class="d-flex flex-wrap gap-2" id="quick-cash-buttons">
                                <button type="button" class="btn btn-outline-success quick-cash-btn" data-amount="exact">
                                    {{ trans('plugins/pos-pro::pos.exact') }}
                                </button>
                            </div>
                        </div>

                        <!-- Change Display -->
                        <div class="border-top pt-3">
                            <div class="d-flex justify-content-between align-items-center">
                                <span class="fs-5">{{ trans('plugins/pos-pro::pos.change_to_return') }}</span>
                                <span class="fs-2 fw-bold" id="change-amount">{{ get_application_currency()->symbol }}0.00</span>
                            </div>
                            <div id="change-status" class="text-end mt-2 d-none">
                                <span class="badge bg-danger fs-6 text-white">{{ trans('plugins/pos-pro::pos.insufficient_cash') }}</span>
                            </div>
                        </div>
                    </x-core::card.body>
                </x-core::card>
            </div>
        </div>
    </form>

    <x-slot:footer>
        <div class="d-flex flex-column flex-sm-row justify-content-between w-100 gap-2">
            <x-core::button data-bs-dismiss="modal" class="btn-link link-secondary order-2 order-sm-1">
                <x-core::icon name="ti ti-x" class="me-1" />
                {{ trans('plugins/pos-pro::pos.cancel') }}
            </x-core::button>
            <x-core::button color="primary" id="complete-order-btn" class="order-1 order-sm-2">
                <x-core::icon name="ti ti-check" class="me-1" />
                {{ trans('plugins/pos-pro::pos.complete_order') }}
            </x-core::button>
        </div>
    </x-slot:footer>
</x-core::modal>

