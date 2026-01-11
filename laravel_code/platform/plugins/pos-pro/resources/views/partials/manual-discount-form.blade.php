@if(!isset($cart['manual_discount']) || $cart['manual_discount'] <= 0)
    <div class="manual-discount-form mb-3">
        <div class="card card-sm">
            <div class="card-body">
                <h3 class="card-title text-muted fs-6">{{ trans('plugins/pos-pro::pos.manual_discount') }}</h3>
                <div class="mb-2">
                    <div class="input-group input-group-flat">
                        <input type="number" class="form-control form-control-sm discount-amount" min="0" step="0.01" placeholder="{{ trans('plugins/pos-pro::pos.enter_discount_amount') }}">
                    </div>
                </div>
                <div class="mb-2">
                    <input type="text" class="form-control form-control-sm discount-description" placeholder="{{ trans('plugins/pos-pro::pos.enter_discount_description') }}">
                </div>
                <div class="d-flex justify-content-end">
                    <button type="button" class="btn btn-sm btn-primary apply-manual-discount">
                        {{ trans('plugins/pos-pro::pos.apply_discount') }}
                    </button>
                </div>
                <div class="discount-error-msg mt-1">
                    <span class="text-danger small"></span>
                </div>
            </div>
        </div>
    </div>
@else
    <div class="manual-discount-form mb-3">
        <div class="card card-sm bg-primary-lt">
            <div class="card-body p-2">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="d-flex align-items-center">
                            <x-core::icon name="ti ti-discount" class="me-2 text-primary" />
                            <div>
                                <div class="fw-medium">{{ trans('plugins/pos-pro::pos.manual_discount') }}</div>
                                <div class="text-muted small">{{ trans('plugins/pos-pro::pos.discount_amount') }}: {{ $cart['manual_discount_formatted'] }}</div>
                                @if($cart['manual_discount_description'])
                                    <div class="text-muted small">{{ $cart['manual_discount_description'] }}</div>
                                @endif
                            </div>
                        </div>
                    </div>
                    <button type="button" class="btn btn-sm btn-ghost-danger remove-manual-discount">
                        <x-core::icon name="ti ti-x" />
                    </button>
                </div>
            </div>
        </div>
    </div>
@endif
