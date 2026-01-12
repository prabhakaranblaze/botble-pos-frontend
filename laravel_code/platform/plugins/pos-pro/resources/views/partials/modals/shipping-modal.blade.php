<x-core::modal id="shipping-modal" :title="trans('plugins/pos-pro::pos.update_shipping')">
    <div class="mb-3">
        <label for="shipping-amount-input" class="form-label">{{ trans('plugins/pos-pro::pos.shipping_amount') }}</label>
        <div class="input-group">
            <input type="number" class="form-control" id="shipping-amount-input" min="0" step="0.01" value="{{ $cart['shipping_amount'] ?? 0 }}" placeholder="{{ trans('plugins/pos-pro::pos.enter_shipping_amount') }}">
            <span class="input-group-text">{{ get_application_currency()->symbol }}</span>
        </div>
        <div class="invalid-feedback" id="shipping-error-msg"></div>
    </div>

    <x-slot:footer>
        <div class="w-100 d-flex justify-content-end">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                {{ trans('core/base::forms.cancel') }}
            </button>
            <button type="button" class="btn btn-primary ms-2" id="update-shipping-btn">
                <x-core::icon name="ti ti-truck-delivery" class="me-1" /> {{ trans('plugins/pos-pro::pos.update_shipping') }}
            </button>
        </div>
    </x-slot:footer>
</x-core::modal>
