<x-core::modal
    id="open-register-modal"
    :title="trans('plugins/pos-pro::pos.open_register')"
    button-id="confirm-open-register"
    :button-label="trans('plugins/pos-pro::pos.open_register')"
>
    <div class="open-register-form">
        <div class="mb-3">
            <label class="form-label required">{{ trans('plugins/pos-pro::pos.starting_cash') }}</label>
            <div class="input-group">
                <span class="input-group-text">{{ get_application_currency()->symbol }}</span>
                <input type="number" class="form-control" id="register-cash-start" name="cash_start" min="0" step="0.01" value="0">
            </div>
            <small class="form-hint">{{ trans('plugins/pos-pro::pos.starting_cash_hint') }}</small>
        </div>
        <div class="mb-3">
            <label class="form-label">{{ trans('plugins/pos-pro::pos.notes') }}</label>
            <textarea class="form-control" id="register-open-notes" name="notes" rows="2"></textarea>
        </div>
    </div>
</x-core::modal>

<x-core::modal
    id="close-register-modal"
    :title="trans('plugins/pos-pro::pos.close_register')"
    button-id="confirm-close-register"
    :button-label="trans('plugins/pos-pro::pos.close_register')"
>
    <div class="close-register-form">
        <div class="card card-sm mb-3 bg-light">
            <div class="card-body">
                <div class="row text-center">
                    <div class="col-4">
                        <div class="text-muted small">{{ trans('plugins/pos-pro::pos.starting_cash') }}</div>
                        <div class="fw-bold" id="close-register-start">{{ get_application_currency()->symbol }}0.00</div>
                    </div>
                    <div class="col-4">
                        <div class="text-muted small">{{ trans('plugins/pos-pro::pos.cash_sales') }}</div>
                        <div class="fw-bold text-success" id="close-register-sales">{{ get_application_currency()->symbol }}0.00</div>
                    </div>
                    <div class="col-4">
                        <div class="text-muted small">{{ trans('plugins/pos-pro::pos.expected_cash') }}</div>
                        <div class="fw-bold text-primary" id="close-register-expected">{{ get_application_currency()->symbol }}0.00</div>
                    </div>
                </div>
            </div>
        </div>
        <div class="mb-3">
            <label class="form-label required">{{ trans('plugins/pos-pro::pos.actual_cash') }}</label>
            <div class="input-group">
                <span class="input-group-text">{{ get_application_currency()->symbol }}</span>
                <input type="number" class="form-control" id="register-actual-cash" name="actual_cash" min="0" step="0.01" value="0">
            </div>
            <small class="form-hint">{{ trans('plugins/pos-pro::pos.actual_cash_hint') }}</small>
        </div>
        <div class="mb-3">
            <label class="form-label">{{ trans('plugins/pos-pro::pos.difference') }}</label>
            <div class="input-group">
                <span class="input-group-text">{{ get_application_currency()->symbol }}</span>
                <input type="text" class="form-control" id="register-difference" readonly value="0.00">
            </div>
        </div>
        <div class="mb-3">
            <label class="form-label">{{ trans('plugins/pos-pro::pos.notes') }}</label>
            <textarea class="form-control" id="register-close-notes" name="notes" rows="2"></textarea>
        </div>
    </div>
</x-core::modal>
