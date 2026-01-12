@if(!isset($cart['coupon_code']))
    <div class="coupon-form mb-3">
        <div class="card card-sm">
            <div class="card-body">
                <h3 class="card-title text-muted fs-6">{{ trans('plugins/pos-pro::pos.have_coupon') }}</h3>
                <div class="input-group input-group-flat">
                    <input type="text" class="form-control form-control-sm coupon-code" placeholder="{{ trans('plugins/pos-pro::pos.enter_coupon_code') }}">
                    <span class="input-group-text p-0">
                        <button type="button" class="btn btn-sm btn-primary apply-coupon-code" data-url="{{ route(($routePrefix ?? 'pos-pro') . '.cart.apply-coupon') }}">
                            {{ trans('plugins/pos-pro::pos.apply') }}
                        </button>
                    </span>
                </div>
                <div class="coupon-error-msg mt-1">
                    <span class="text-danger small"></span>
                </div>
            </div>
        </div>
    </div>
@else
    <div class="coupon-form mb-3">
        <div class="card card-sm bg-primary-lt">
            <div class="card-body p-2">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="d-flex align-items-center">
                            <x-core::icon name="ti ti-discount-check" class="me-2 text-primary" />
                            <div>
                                <div class="fw-medium">{{ $cart['coupon_code'] }}</div>
                                @if($cart['coupon_discount'] > 0)
                                    <div class="text-muted small">{{ trans('plugins/pos-pro::pos.discount_amount') }}: {{ $cart['coupon_discount_formatted'] }}</div>
                                @endif
                            </div>
                        </div>
                    </div>
                    <button type="button" class="btn btn-sm btn-ghost-danger remove-coupon-code" data-url="{{ route(($routePrefix ?? 'pos-pro') . '.cart.remove-coupon') }}">
                        <x-core::icon name="ti ti-x" />
                    </button>
                </div>
            </div>
        </div>
    </div>
@endif
