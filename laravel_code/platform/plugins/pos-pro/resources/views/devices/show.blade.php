@extends(BaseHelper::getAdminMasterLayoutTemplate())

@section('content')
    <div class="row">
        <div class="col-md-8">
            <div class="card">
                <div class="card-header">
                    <h4 class="card-title">{{ trans('plugins/pos-pro::pos.device_management.edit') }}</h4>
                </div>
                <div class="card-body">
                    <div class="row">
                        <div class="col-md-6">
                            <div class="form-group">
                                <label>{{ trans('plugins/pos-pro::pos.device_user') }}</label>
                                <p class="form-control-static">
                                    @if($posDevice->user)
                                        <a href="{{ route('users.profile.view', $posDevice->user->id) }}" target="_blank">
                                            {{ $posDevice->user->name }} ({{ $posDevice->user->username }})
                                        </a>
                                    @else
                                        —
                                    @endif
                                </p>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="form-group">
                                <label>{{ trans('plugins/pos-pro::pos.device_active') }}</label>
                                <p class="form-control-static">
                                    @if($posDevice->is_active)
                                        <span class="label label-success">{{ trans('core/base::base.yes') }}</span>
                                    @else
                                        <span class="label label-danger">{{ trans('core/base::base.no') }}</span>
                                    @endif
                                </p>
                            </div>
                        </div>
                    </div>
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="form-group">
                                <label>{{ trans('plugins/pos-pro::pos.device_ip') }}</label>
                                <p class="form-control-static">{{ $posDevice->device_ip ?: '—' }}</p>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="form-group">
                                <label>{{ trans('plugins/pos-pro::pos.device_name') }}</label>
                                <p class="form-control-static">{{ $posDevice->device_name ?: '—' }}</p>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6">
                            <div class="form-group">
                                <label>{{ trans('core/base::tables.created_at') }}</label>
                                <p class="form-control-static">{{ BaseHelper::formatDateTime($posDevice->created_at) }}</p>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="form-group">
                                <label>{{ trans('core/base::tables.updated_at') }}</label>
                                <p class="form-control-static">{{ BaseHelper::formatDateTime($posDevice->updated_at) }}</p>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="card-footer">
                    <a href="{{ route('pos-devices.edit', $posDevice) }}" class="btn btn-primary">
                        <i class="fa fa-edit"></i> {{ trans('core/base::forms.edit') }}
                    </a>
                    <a href="{{ route('pos-devices.index') }}" class="btn btn-secondary">
                        <i class="fa fa-arrow-left"></i> {{ trans('plugins/pos-pro::pos.back') }}
                    </a>
                </div>
            </div>
        </div>
        
        <div class="col-md-4">
            <div class="card">
                <div class="card-header">
                    <h4 class="card-title">{{ trans('plugins/pos-pro::pos.device_management.test') }}</h4>
                </div>
                <div class="card-body">
                    <p>{{ trans('plugins/pos-pro::pos.device_management.test_description') }}</p>
                    
                    @if($posDevice->device_ip && $posDevice->is_active)
                        <div class="alert alert-info">
                            <strong>{{ trans('plugins/pos-pro::pos.device_management.test_endpoint') }}:</strong><br>
                            <code>POST http://{{ $posDevice->device_ip }}/api</code>
                        </div>
                        
                        <p>{{ trans('plugins/pos-pro::pos.device_management.test_command') }}:</p>
                        <code>php artisan pos:test-local-device {{ $posDevice->user_id }} {order_id}</code>
                    @else
                        <div class="alert alert-warning">
                            {{ trans('plugins/pos-pro::pos.device_management.test_unavailable') }}
                        </div>
                    @endif
                </div>
            </div>
        </div>
    </div>
@endsection
