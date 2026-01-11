<x-core::modal id="discount-modal" :title="trans('plugins/pos-pro::pos.apply_discount')">
    <div class="mb-3">
        <label class="form-label">{{ trans('plugins/pos-pro::pos.discount_type') }}</label>
        <div class="form-selectgroup">
            <label class="form-selectgroup-item">
                <input type="radio" name="discount-type" value="fixed" class="form-selectgroup-input" checked>
                <span class="form-selectgroup-label">{{ trans('plugins/pos-pro::pos.fixed_amount') }}</span>
            </label>
            <label class="form-selectgroup-item">
                <input type="radio" name="discount-type" value="percentage" class="form-selectgroup-input">
                <span class="form-selectgroup-label">{{ trans('plugins/pos-pro::pos.percentage') }}</span>
            </label>
        </div>
    </div>

    <div class="mb-3">
        <label for="discount-amount-input" class="form-label">{{ trans('plugins/pos-pro::pos.discount_amount') }}</label>
        <div class="input-group">
            <input type="number" class="form-control" id="discount-amount-input" min="0" step="0.01" placeholder="{{ trans('plugins/pos-pro::pos.enter_discount_amount') }}">
            <span class="input-group-text" id="discount-symbol">{{ get_application_currency()->symbol }}</span>
        </div>
        <div class="invalid-feedback" id="discount-error-msg"></div>
    </div>

    <div class="mb-3">
        <label for="discount-description-input" class="form-label">{{ trans('plugins/pos-pro::pos.discount_description') }}</label>
        <input type="text" class="form-control" id="discount-description-input" placeholder="{{ trans('plugins/pos-pro::pos.enter_discount_description') }}">
    </div>

    <x-slot:footer>
        <div class="w-100 d-flex justify-content-between">
            @if(isset($cart['manual_discount']) && $cart['manual_discount'] > 0)
                <button type="button" class="btn btn-danger" id="remove-discount-btn">
                    <x-core::icon name="ti ti-trash" class="me-1" /> {{ trans('plugins/pos-pro::pos.remove_discount') }}
                </button>
            @else
                <div></div>
            @endif
            <div>
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                    {{ trans('core/base::forms.cancel') }}
                </button>
                <button type="button" class="btn btn-primary" id="apply-discount-btn">
                    <x-core::icon name="ti ti-discount" class="me-1" /> {{ trans('plugins/pos-pro::pos.apply_discount') }}
                </button>
            </div>
        </div>
    </x-slot:footer>
</x-core::modal>
