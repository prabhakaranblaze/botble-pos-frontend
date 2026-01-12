<div class="alert alert-success" data-deactivate-url="{{ route('pos-pro.license.deactivate') }}">
    <div class="d-flex align-items-center">
        <x-core::icon name="ti ti-circle-check" class="me-3 fs-2" />
        <div class="flex-grow-1">
            <h5 class="mb-1">{{ trans('plugins/pos-pro::pos.license.activated_title') }}</h5>
            <p class="mb-0">{{ trans('plugins/pos-pro::pos.license.license_active_description') }}</p>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-md-6">
        <div class="card border-0 bg-light">
            <div class="card-body">
                <h6 class="card-title text-muted">{{ trans('plugins/pos-pro::pos.license.purchase_code_label') }}</h6>
                <div class="d-flex align-items-center">
                    @if(isset($licenseData['purchase_code']))
                        @php
                            $purchaseCode = $licenseData['purchase_code'];

                            if (\Botble\Base\Facades\BaseHelper::hasDemoModeEnabled()) {
                                $purchaseCode = 'DEMO_PURCHASE_CODE';
                            }
                        @endphp
                        <p class="card-text font-monospace mb-0 me-2" id="purchase-code-display">
                            {{ Str::mask($purchaseCode, '*', 4) ?? 'N/A' }}
                        </p>

                        <button type="button" class="btn btn-sm btn-outline-secondary" id="toggle-purchase-code"
                                data-full-code="{{ $purchaseCode }}"
                                data-masked-code="{{ Str::mask($purchaseCode, '*', 4) }}"
                                title="{{ trans('plugins/pos-pro::pos.license.toggle_visibility') }}">
                            <span id="show-icon">
                                <x-core::icon name="ti ti-eye" class="me-0" />
                            </span>
                            <span id="hide-icon" style="display: none;">
                                <x-core::icon name="ti ti-eye-off" class="me-0" />
                            </span>
                        </button>
                    @endif
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-6">
        <div class="card border-0 bg-light">
            <div class="card-body">
                <h6 class="card-title text-muted">{{ trans('plugins/pos-pro::pos.license.activated_at') }}</h6>
                <p class="card-text">{{ $licenseData['activated_at'] }}</p>
            </div>
        </div>
    </div>
</div>

<div class="row mt-4">
    <div class="col-md-6">
        <div class="d-flex align-items-center text-success">
            <x-core::icon name="ti ti-shield-check" class="me-2" />
            <span>{{ trans('plugins/pos-pro::pos.license.license_valid') }}</span>
        </div>
    </div>
    <div class="col-md-6">
        <div class="d-flex align-items-center text-success">
            <x-core::icon name="ti ti-refresh" class="me-2" />
            <span>{{ trans('plugins/pos-pro::pos.license.updates_enabled') }}</span>
        </div>
    </div>
</div>

<hr class="my-4">

<div class="d-flex justify-content-between align-items-center">
    <div>
        <h6>{{ trans('plugins/pos-pro::pos.license.manage_license') }}</h6>
        <p class="text-muted small mb-0">{{ trans('plugins/pos-pro::pos.license.manage_license_description') }}</p>
    </div>
    <button type="button" class="btn btn-outline-warning" id="deactivate-license-btn">
        <x-core::icon name="ti ti-key-off" class="me-2" />
        {{ trans('plugins/pos-pro::pos.license.deactivate') }}
    </button>
</div>

<div class="alert alert-info mt-4">
    <div class="d-flex">
        <x-core::icon name="ti ti-info-circle" class="me-2 mt-1" />
        <div>
            <strong>{{ trans('plugins/pos-pro::pos.license.important_note') }}</strong>
            <p class="mb-0 mt-1 small">{{ trans('plugins/pos-pro::pos.license.deactivation_note') }}</p>
        </div>
    </div>
</div>
