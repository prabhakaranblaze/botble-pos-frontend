<x-core::modal
    id="add-customer-modal"
    :title="trans('plugins/pos-pro::pos.create_new_customer')"
    button-id="confirm-add-customer-button"
    :button-label="trans('plugins/pos-pro::pos.save')"
>
    <div class="add-customer-form">
        <div class="row">
            <div class="col-md-6 mb-3">
                <label class="form-label required">{{ trans('plugins/pos-pro::pos.customer_name') }}</label>
                <input type="text" class="form-control" id="customer-name" name="name">
            </div>
            <div class="col-md-6 mb-3">
                <label class="form-label required">{{ trans('plugins/pos-pro::pos.customer_phone') }}</label>
                <input type="text" class="form-control" id="customer-phone" name="phone">
            </div>
            <div class="col-md-6 mb-3">
                <label class="form-label">{{ trans('plugins/pos-pro::pos.email') }}</label>
                <input type="email" class="form-control" id="customer-email" name="email">
            </div>
            <div class="col-md-6 mb-3">
                <label class="form-label">{{ trans('plugins/pos-pro::pos.address') }}</label>
                <input type="text" class="form-control" id="customer-address" name="address">
            </div>
        </div>
    </div>
</x-core::modal>
