<option value="">{{ trans('plugins/pos-pro::pos.guest') }}</option>
@foreach($customers as $customer)
    <option value="{{ $customer->id }}" data-email="{{ $customer->email }}" data-phone="{{ $customer->phone }}">
        {{ $customer->name }} ({{ $customer->phone }})
    </option>
@endforeach
