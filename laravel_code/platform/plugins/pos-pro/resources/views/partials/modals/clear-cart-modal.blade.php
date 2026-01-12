<x-core::modal
    id="clear-cart-modal"
    :title="trans('plugins/pos-pro::pos.clear_cart')"
    type="warning"
    size="sm"
    :body-attrs="['class' => 'text-center py-4']"
>
    <x-core::icon name="ti ti-trash" class="text-warning" size="lg" />
    <h5 class="mt-3">{{ trans('plugins/pos-pro::pos.confirm_clear_cart') }}</h5>
    <p class="text-muted">{{ trans('plugins/pos-pro::pos.confirm_clear_cart_message') }}</p>

    <x-slot:footer>
        <div class="w-100 d-flex justify-content-center gap-2">
            <x-core::button data-bs-dismiss="modal">
                {{ trans('core/base::forms.cancel') }}
            </x-core::button>
            <x-core::button color="danger" id="confirm-clear-cart-btn">
                <x-core::icon name="ti ti-trash" class="me-1" /> {{ trans('plugins/pos-pro::pos.clear_cart') }}
            </x-core::button>
        </div>
    </x-slot:footer>
</x-core::modal>
