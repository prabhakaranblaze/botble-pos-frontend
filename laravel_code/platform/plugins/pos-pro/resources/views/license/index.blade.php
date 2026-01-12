@extends(BaseHelper::getAdminMasterLayoutTemplate())

@section('content')
    @if(session('warning'))
        <div class="alert alert-warning alert-dismissible fade show" role="alert">
            <div class="d-flex align-items-center">
                <x-core::icon name="ti ti-alert-triangle" class="me-2" />
                <div>
                    <strong>{{ trans('plugins/pos-pro::pos.license.access_denied') }}</strong>
                    <p class="mb-0 mt-1">{{ session('warning') }}</p>
                </div>
            </div>
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
    @endif

    <div class="row">
        <div class="col-md-8">
            <div class="card">
                <div class="card-header">
                    <h4 class="card-title">{{ trans('plugins/pos-pro::pos.license.title') }}</h4>
                </div>
                <div class="card-body">
                    @if($isLicenseVerified && $licenseData)
                        @include('plugins/pos-pro::license.partials.activated', ['licenseData' => $licenseData])
                    @else
                        @include('plugins/pos-pro::license.partials.form')
                    @endif
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title">{{ trans('plugins/pos-pro::pos.license.help_title') }}</h5>
                </div>
                <div class="card-body">
                    <div class="mb-3">
                        <h6>{{ trans('plugins/pos-pro::pos.license.what_is_purchase_code') }}</h6>
                        <p class="text-muted small">{{ trans('plugins/pos-pro::pos.license.purchase_code_description') }}</p>
                    </div>

                    <div class="mb-3">
                        <h6>{{ trans('plugins/pos-pro::pos.license.where_to_find') }}</h6>
                        <p class="text-muted small">{{ trans('plugins/pos-pro::pos.license.find_purchase_code_description') }}</p>
                        <a href="https://help.market.envato.com/hc/en-us/articles/202822600-Where-Is-My-Purchase-Code"
                           target="_blank" class="btn btn-sm btn-outline-primary">
                            {{ trans('plugins/pos-pro::pos.license.learn_more') }}
                        </a>
                    </div>

                    <div class="mb-3">
                        <h6>{{ trans('plugins/pos-pro::pos.license.license_terms') }}</h6>
                        <p class="text-muted small">{{ trans('plugins/pos-pro::pos.license.license_terms_description') }}</p>
                        <a href="https://codecanyon.net/licenses/standard"
                           target="_blank" class="btn btn-sm btn-outline-secondary">
                            {{ trans('plugins/pos-pro::pos.license.view_license_terms') }}
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>
@endsection

@push('footer')
    <link rel="stylesheet" href="{{ asset('vendor/core/plugins/pos-pro/css/license-activation.css') }}?v={{ time() }}">

    {{-- JavaScript translations --}}
    <script>
    window.posTranslations = window.posTranslations || {};
    window.posTranslations = {
        somethingWentWrong: '{{ trans("plugins/pos-pro::pos.js.something_went_wrong") }}',
        deactivateLicenseConfirm: '{{ trans("plugins/pos-pro::pos.js.deactivate_license_confirm") }}',
        showPurchaseCode: '{{ trans("plugins/pos-pro::pos.js.show_purchase_code") }}',
        hidePurchaseCode: '{{ trans("plugins/pos-pro::pos.js.hide_purchase_code") }}'
    };
    </script>

    <script src="{{ asset('vendor/core/plugins/pos-pro/js/license-activation.js') }}?v={{ time() }}"></script>
@endpush
