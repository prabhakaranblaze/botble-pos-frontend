<x-core::modal id="coupon-modal" :title="trans('plugins/pos-pro::pos.apply_coupon')">
    <div class="mb-3">
        <label for="coupon-code-input" class="form-label">{{ trans('plugins/pos-pro::pos.coupon_code') }}</label>
        <input type="text" class="form-control" id="coupon-code-input" placeholder="{{ trans('plugins/pos-pro::pos.enter_coupon_code') }}">
        <div class="invalid-feedback" id="coupon-error-msg"></div>
    </div>

    <x-slot:footer>
        <div class="w-100 d-flex justify-content-between">
            @if(isset($cart['coupon_code']))
                <button type="button" class="btn btn-danger" id="remove-coupon-btn">
                    <x-core::icon name="ti ti-trash" class="me-1" /> {{ trans('plugins/pos-pro::pos.remove_coupon') }}
                </button>
            @else
                <div></div>
            @endif
            <div>
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                    {{ trans('core/base::forms.cancel') }}
                </button>
                <button type="button" class="btn btn-primary" id="apply-coupon-btn">
                    <x-core::icon name="ti ti-discount-check" class="me-1" /> {{ trans('plugins/pos-pro::pos.apply') }}
                </button>
            </div>
        </div>
    </x-slot:footer>
</x-core::modal>
