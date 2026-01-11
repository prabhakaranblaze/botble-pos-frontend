<div class="alert alert-warning">
    <div class="d-flex align-items-center">
        <x-core::icon name="ti ti-alert-triangle" class="me-2" />
        <div>
            <strong>{{ trans('plugins/pos-pro::pos.license.activation_required') }}</strong>
            <p class="mb-0 mt-1">{{ trans('plugins/pos-pro::pos.license.description') }}</p>
        </div>
    </div>
</div>

<form id="license-activation-form" data-action="{{ route('pos-pro.license.activate') }}">
    <div class="mb-4">
        <label for="purchase_code" class="form-label">
            {{ trans('plugins/pos-pro::pos.license.purchase_code_label') }}
            <span class="text-danger">*</span>
        </label>
        <input type="text"
               class="form-control form-control-lg"
               id="purchase_code"
               name="purchase_code"
               placeholder="{{ trans('plugins/pos-pro::pos.license.purchase_code_placeholder') }}"
               required>
        <div class="form-text">
            <x-core::icon name="ti ti-info-circle" class="me-1" />
            <a href="https://help.market.envato.com/hc/en-us/articles/202822600-Where-Is-My-Purchase-Code" target="_blank">
                {{ trans('plugins/pos-pro::pos.license.purchase_code_helper') }}
            </a>
        </div>
    </div>

    <div class="mb-4">
        <div class="form-check">
            <input class="form-check-input"
                   type="checkbox"
                   id="license_rules_agreement"
                   name="license_rules_agreement"
                   required>
            <label class="form-check-label" for="license_rules_agreement">
                {{ trans('plugins/pos-pro::pos.license.agreement_text') }}
                <a href="https://codecanyon.net/licenses/standard" target="_blank" rel="nofollow">
                    {{ trans('plugins/pos-pro::pos.license.more_info') }}
                </a>.
            </label>
        </div>
    </div>

    <div class="d-flex justify-content-between align-items-center">
        <button type="submit" class="btn btn-primary btn-lg" id="activate-license-btn">
            <span class="spinner-border spinner-border-sm d-none me-2" role="status"></span>
            <x-core::icon name="ti ti-key" class="me-2" />
            {{ trans('plugins/pos-pro::pos.license.activate') }}
        </button>

        <div class="text-muted small">
            {{ trans('plugins/pos-pro::pos.license.secure_activation') }}
        </div>
    </div>
</form>

<hr class="my-4">

<div class="row">
    <div class="col-md-6">
        <h6 class="text-muted">{{ trans('plugins/pos-pro::pos.license.need_help') }}</h6>
        <p class="small text-muted">{{ trans('plugins/pos-pro::pos.license.need_help_description') }}</p>
    </div>
    <div class="col-md-6">
        <h6 class="text-muted">{{ trans('plugins/pos-pro::pos.license.reset_license') }}</h6>
        <p class="small text-muted">{{ trans('plugins/pos-pro::pos.license.need_reset') }}</p>
    </div>
</div>
