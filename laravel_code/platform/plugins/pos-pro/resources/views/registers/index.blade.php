@extends(BaseHelper::getAdminMasterLayoutTemplate())

@section('content')
    <x-core::card>
        <x-core::card.header>
            <h4 class="card-title">{{ trans('plugins/pos-pro::pos.register_history') }}</h4>
        </x-core::card.header>
        <x-core::card.body>
            <div class="table-responsive">
                <table class="table table-striped table-hover">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>{{ trans('plugins/pos-pro::pos.cashier') }}</th>
                            <th>{{ trans('plugins/pos-pro::pos.starting_cash') }}</th>
                            <th>{{ trans('plugins/pos-pro::pos.expected_cash') }}</th>
                            <th>{{ trans('plugins/pos-pro::pos.actual_cash') }}</th>
                            <th>{{ trans('plugins/pos-pro::pos.difference') }}</th>
                            <th>{{ trans('plugins/pos-pro::pos.opened_at') }}</th>
                            <th>{{ trans('plugins/pos-pro::pos.closed_at') }}</th>
                            <th>{{ trans('plugins/pos-pro::pos.status') }}</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($registers as $register)
                            <tr>
                                <td>{{ $register->id }}</td>
                                <td>{{ $register->user?->name ?? 'N/A' }}</td>
                                <td>{{ format_price($register->cash_start) }}</td>
                                <td>{{ $register->cash_end ? format_price($register->cash_end) : '-' }}</td>
                                <td>{{ $register->actual_cash ? format_price($register->actual_cash) : '-' }}</td>
                                <td>
                                    @if($register->isClosed())
                                        <span class="badge {{ $register->difference >= 0 ? 'bg-green text-white' : 'bg-red text-white' }}">
                                            {{ $register->difference >= 0 ? '+' : '' }}{{ format_price($register->difference) }}
                                        </span>
                                    @else
                                        -
                                    @endif
                                </td>
                                <td>{{ BaseHelper::formatDateTime($register->opened_at) }}</td>
                                <td>{{ $register->closed_at ? BaseHelper::formatDateTime($register->closed_at) : '-' }}</td>
                                <td>
                                    <span class="badge {{ $register->isOpen() ? 'bg-green text-white' : 'bg-secondary text-white' }}">
                                        {{ $register->isOpen() ? trans('plugins/pos-pro::pos.register_open') : trans('plugins/pos-pro::pos.register_closed') }}
                                    </span>
                                </td>
                            </tr>
                        @endforeach

                        @if($registers->isEmpty())
                            <tr>
                                <td colspan="9" class="text-center">{{ trans('plugins/pos-pro::pos.no_register_history') }}</td>
                            </tr>
                        @endif
                    </tbody>
                </table>
            </div>

            <div class="mt-3">
                {{ $registers->links() }}
            </div>
        </x-core::card.body>
    </x-core::card>
@stop
