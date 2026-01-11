@php
    $languages = Language::getActiveLanguage(['lang_id', 'lang_name', 'lang_code', 'lang_flag']);
    $currentLocale = app()->getLocale();
@endphp

@if ($languages->count() > 1)
    <div class="dropdown">
        <a href="#" class="nav-link px-0 d-flex align-items-center gap-2" data-bs-toggle="dropdown" aria-label="Open language menu">
            @php
                $currentLanguage = $languages->where('lang_code', $currentLocale)->first();
                if (!$currentLanguage) {
                    $currentLanguage = $languages->first();
                }
            @endphp
            {!! language_flag($currentLanguage->lang_flag, $currentLanguage->lang_name) !!}
            <span class="d-none d-md-inline">{{ $currentLanguage->lang_name }}</span>
        </a>
        <div class="dropdown-menu dropdown-menu-end dropdown-menu-arrow">
            @foreach ($languages as $language)
                @if ($language->lang_code !== $currentLocale)
                    <a href="{{ route(($routePrefix ?? 'pos-pro') . '.switch-language', ['locale' => $language->lang_code]) }}" class="dropdown-item d-flex align-items-center gap-2">
                        {!! language_flag($language->lang_flag, $language->lang_name) !!}
                        {{ $language->lang_name }}
                    </a>
                @endif
            @endforeach
        </div>
    </div>
@endif
