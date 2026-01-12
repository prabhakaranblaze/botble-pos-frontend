<x-core::modal
    id="success-modal"
    :title="trans('plugins/pos-pro::pos.order_completed')"
    type="success"
    size="md"
    :body-attrs="['class' => 'text-center py-4']"
>
    <x-core::icon name="ti ti-circle-check" class="text-success" size="lg" />
    <h5 class="mt-3">{{ trans('plugins/pos-pro::pos.order_completed_successfully') }}</h5>
    <p class="text-muted">{{ trans('plugins/pos-pro::pos.order_number') }}: <span id="order-number"></span></p>
    <div id="multiple-orders-info" class="d-none">
        <small class="text-muted">{{ trans('plugins/pos-pro::pos.multiple_vendor_orders_created') }}</small>
    </div>

    <x-slot:footer>
        <div class="w-100 d-flex justify-content-center">
            <x-core::button color="primary" id="print-receipt-btn" class="me-2">
                <x-core::icon name="ti ti-printer" class="me-1" /> {{ trans('plugins/pos-pro::pos.print_receipt') }}
            </x-core::button>
            <x-core::button id="new-order-btn">
                <x-core::icon name="ti ti-plus" class="me-1" /> {{ trans('plugins/pos-pro::pos.new_order') }}
            </x-core::button>
        </div>
    </x-slot:footer>
</x-core::modal>

@push('footer')
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            window.currency = '{{ get_application_currency()->title }}';
        });
    </script>
@endpush
