@php
    $currencies = get_all_currencies();
    $currentCurrency = get_application_currency();
@endphp

@if ($currencies->count() > 1)
    <div class="dropdown">
        <a href="#" class="nav-link px-0 d-flex align-items-center gap-2" data-bs-toggle="dropdown" aria-label="Open currency menu">
            <span class="currency-symbol">{{ $currentCurrency->symbol }}</span>
            <span class="d-none d-md-inline">{{ $currentCurrency->title }}</span>
        </a>
        <div class="dropdown-menu dropdown-menu-end dropdown-menu-arrow">
            @foreach ($currencies as $currency)
                @if ($currency->id !== $currentCurrency->id)
                    <a href="{{ route(($routePrefix ?? 'pos-pro') . '.switch-currency', ['currency' => $currency->title]) }}" class="dropdown-item d-flex align-items-center gap-2">
                        <span class="currency-symbol">{{ $currency->symbol }}</span>
                        {{ $currency->title }}
                    </a>
                @endif
            @endforeach
        </div>
    </div>
@endif
