@php
    use Botble\Language\Facades\Language;

    $mobileDetect = new \Detection\MobileDetect();

    $isMobile = $mobileDetect->isMobile();
    $routePrefix = $routePrefix ?? 'pos-pro';
    $isVendor = $routePrefix === 'marketplace.vendor.pos';

    // Default posContext for backward compatibility
    $posContext = $posContext ?? [
        'user' => [
            'name' => auth()->user()?->name ?? '',
            'email' => auth()->user()?->email ?? '',
            'avatar_url' => auth()->user()?->avatar_url ?? '',
        ],
        'urls' => [
            'dashboard' => route('dashboard.index'),
            'profile' => auth()->check() ? route('users.profile.view', auth()->id()) : '#',
            'logout' => route('access.logout'),
        ],
    ];
@endphp

<x-core::layouts.base body-class="border-top-wide border-primary d-flex flex-column">
    <x-slot:title>
        @yield('title')
    </x-slot:title>

    <div class="pos-container">
        <!-- Floating exit fullscreen button (visible only in fullscreen mode) -->
        <button id="exit-fullscreen-floating" class="btn btn-icon btn-light position-fixed" aria-label="Exit fullscreen mode">
            <x-core::icon name="ti ti-minimize" />
            <span class="ms-2 d-none d-sm-inline">{{ trans('plugins/pos-pro::pos.exit_fullscreen') }}</span>
        </button>

        <!-- Mobile menu toggle button (visible only on small screens) -->
        <div class="d-md-none d-flex justify-content-between align-items-center p-3 mobile-header">
            <div class="d-flex align-items-center">
                <x-core::button
                    tag="a"
                    href="{{ $posContext['urls']['dashboard'] }}"
                    color="secondary"
                    icon="ti ti-arrow-left"
                    class="me-3 btn-sm"
                >
                    {{ __('Back') }}
                </x-core::button>
                <h1 class="h4 mb-0">@yield('header-title', 'POS System')</h1>
            </div>
            <button
                type="button"
                class="btn btn-icon btn-primary"
                data-bs-toggle="offcanvas"
                data-bs-target="#mobile-menu-offcanvas"
                aria-controls="mobile-menu-offcanvas"
            >
                <x-core::icon name="ti ti-menu-2" />
            </button>
        </div>

        <!-- Off-canvas menu for mobile -->
        <x-core::offcanvas
            id="mobile-menu-offcanvas"
            class="mobile-menu-offcanvas"
            placement="end"
            backdrop="true"
            style="--bb-offcanvas-width: 85%"
        >
            <x-core::offcanvas.header class="mobile-menu-header">
                <x-core::offcanvas.title>
                    <x-core::icon name="ti ti-menu-2" class="me-2" />
                    {{ __('Menu') }}
                </x-core::offcanvas.title>
                <x-core::offcanvas.close-button />
            </x-core::offcanvas.header>
            <x-core::offcanvas.body>
                <!-- User Profile Card at the top -->
                <div class="user-profile-card mb-3">
                    <div class="d-flex align-items-center">
                        <div class="avatar-wrapper me-3">
                            <span class="avatar avatar-md" style="background-image: url({{ $posContext['user']['avatar_url'] }});"></span>
                        </div>
                        <div class="user-info">
                            <h6 class="mb-0">{{ $posContext['user']['name'] }}</h6>
                            <p class="text-muted mb-0 small">{{ $posContext['user']['email'] }}</p>
                        </div>
                    </div>
                </div>

                <!-- Menu Items -->
                <div class="mobile-menu-items">
                    <!-- Main Menu Items -->
                    <div class="menu-section">
                        <a href="{{ route($routePrefix . '.index') }}" class="menu-item">
                            <div class="menu-item-icon">
                                <x-core::icon name="ti ti-devices" />
                            </div>
                            <div class="menu-item-content">
                                <div class="menu-item-title">{{ trans('plugins/pos-pro::pos.pos') }}</div>
                                <div class="menu-item-description">{{ trans('plugins/pos-pro::pos.manage_pos') }}</div>
                            </div>
                        </a>

                        @if(!$isVendor)
                        <a href="{{ route('pos-pro.reports.index') }}" class="menu-item">
                            <div class="menu-item-icon">
                                <x-core::icon name="ti ti-chart-bar" />
                            </div>
                            <div class="menu-item-content">
                                <div class="menu-item-title">{{ trans('plugins/pos-pro::pos.reports.title') }}</div>
                                <div class="menu-item-description">{{ trans('plugins/pos-pro::pos.reports.description') }}</div>
                            </div>
                        </a>

                        <a href="{{ route('pos-pro.settings.edit') }}" class="menu-item">
                            <div class="menu-item-icon">
                                <x-core::icon name="ti ti-settings" />
                            </div>
                            <div class="menu-item-content">
                                <div class="menu-item-title">{{ trans('plugins/pos-pro::pos.settings.title') }}</div>
                                <div class="menu-item-description">{{ trans('plugins/pos-pro::pos.settings.description') }}</div>
                            </div>
                        </a>
                        @endif
                    </div>

                    <!-- Customer Display Button (Mobile) -->
                    <button id="open-customer-display-mobile" class="menu-item w-100 text-start border-0 bg-transparent"
                        data-customer-display-url="{{ route($routePrefix . '.customer-display') }}">
                        <div class="menu-item-icon">
                            <x-core::icon name="ti ti-device-tv" />
                        </div>
                        <div class="menu-item-content">
                            <div class="menu-item-title">{{ trans('plugins/pos-pro::pos.customer_display') }}</div>
                            <div class="menu-item-description">{{ trans('plugins/pos-pro::pos.open_customer_display') }}</div>
                        </div>
                    </button>

                    <!-- Register Status Button (Mobile) -->
                    <button id="register-status-btn-mobile" class="menu-item w-100 text-start border-0 bg-transparent">
                        <div class="menu-item-icon">
                            <x-core::icon name="ti ti-cash-register" />
                        </div>
                        <div class="menu-item-content">
                            <div class="menu-item-title d-flex align-items-center">
                                {{ trans('plugins/pos-pro::pos.cash_register') }}
                                <span class="badge {{ isset($registerStatus) && $registerStatus['is_open'] ? 'bg-green text-white' : 'bg-red text-white' }} ms-2" id="register-status-badge-mobile">
                                    {{ isset($registerStatus) && $registerStatus['is_open'] ? trans('plugins/pos-pro::pos.open') : trans('plugins/pos-pro::pos.closed') }}
                                </span>
                            </div>
                            <div class="menu-item-description" id="register-status-text-mobile">
                                {{ isset($registerStatus) && $registerStatus['is_open'] ? trans('plugins/pos-pro::pos.click_to_close_register') : trans('plugins/pos-pro::pos.click_to_open_register') }}
                            </div>
                        </div>
                    </button>

                    <!-- Clock and Calculator Row -->
                    <div class="menu-item clock-calc-row">
                        <div class="d-flex align-items-center w-100 justify-content-between">
                            <!-- Clock Display -->
                            <div id="pos-clock-mobile" class="px-3 py-2 bg-light rounded d-flex align-items-center gap-2 font-monospace fw-bold text-muted">
                                <x-core::icon name="ti ti-clock" />
                                <span id="pos-clock-time-mobile">--:--:--</span>
                            </div>

                            <!-- Calculator Button -->
                            <button class="btn btn-outline-primary d-flex align-items-center gap-2"
                                data-bs-toggle="modal"
                                data-bs-target="#calculator-modal"
                                data-bs-dismiss="offcanvas">
                                <x-core::icon name="ti ti-calculator" />
                                {{ trans('plugins/pos-pro::pos.calculator') }}
                            </button>
                        </div>
                    </div>

                    <!-- Settings Row -->
                    <div class="menu-item settings-row">
                        <div class="d-flex align-items-center w-100 justify-content-between">
                            <!-- Currency Switcher -->
                            @if (get_all_currencies()->count() > 1)
                                <div class="nav-item me-3">
                                    @include('plugins/pos-pro::partials.currency-switcher')
                                </div>
                            @endif

                            <!-- Language Switcher - only show if multiple languages are available -->
                            @if (is_plugin_active('language') && count(Language::getActiveLanguage()) > 1 && $isMobile)
                                <div class="nav-item me-3">
                                    @include('plugins/pos-pro::partials.language-switcher')
                                </div>
                            @endif

                            <!-- Dark/Light Mode Toggle -->
                            <div class="nav-item me-3">
                                @include('core/base::layouts.partials.theme-toggle')
                            </div>
                        </div>
                    </div>

                    <!-- User Actions -->
                    <div class="menu-item user-actions-row">
                        <div class="d-flex justify-content-between w-100">
                            <a href="{{ $posContext['urls']['profile'] }}" class="btn btn-outline-primary flex-grow-1 me-2">
                                <x-core::icon name="ti ti-user" class="me-1" />
                                {{ __('Profile') }}
                            </a>
                            <a href="{{ $posContext['urls']['logout'] }}" class="btn btn-outline-danger flex-grow-1">
                                <x-core::icon name="ti ti-logout" class="me-1" />
                                {{ __('Logout') }}
                            </a>
                        </div>
                    </div>
                </div>
            </x-core::offcanvas.body>
        </x-core::offcanvas>

        <!-- Header with back button (visible on medium screens and up) -->
        <div class="navbar-expand-md d-none d-md-block">
            <div class="collapse navbar-collapse" id="navbar-menu">
                <div class="navbar navbar-light">
                    <div class="container-fluid d-block">
                        <div class="d-flex align-items-center justify-content-between py-2">
                            <div class="d-flex align-items-center">
                                <x-core::button
                                    tag="a"
                                    href="{{ $posContext['urls']['dashboard'] }}"
                                    color="secondary"
                                    icon="ti ti-arrow-left"
                                    class="me-3 btn-sm"
                                    :title="__('Back to Dashboard')"
                                >
                                    <span class="d-none d-xl-inline">{{ __('Back to Dashboard') }}</span>
                                    <span class="d-xl-none">{{ __('Back') }}</span>
                                </x-core::button>
                                <h1 class="h4 mb-0 d-none d-lg-block">@yield('header-title', 'POS System')</h1>
                            </div>
                            <div class="d-flex align-items-center gap-1">
                                <!-- Register Status Button - Always visible as it's important -->
                                <div class="nav-item">
                                    <button id="register-status-btn"
                                        class="btn btn-ghost-primary btn-sm d-flex align-items-center gap-1"
                                        aria-label="{{ trans('plugins/pos-pro::pos.register_status') }}"
                                        title="{{ trans('plugins/pos-pro::pos.register_status') }}">
                                        <x-core::icon name="ti ti-cash-register" />
                                        <span class="badge {{ isset($registerStatus) && $registerStatus['is_open'] ? 'bg-green text-white' : 'bg-red text-white' }}" id="register-status-badge">
                                            {{ isset($registerStatus) && $registerStatus['is_open'] ? trans('plugins/pos-pro::pos.open') : trans('plugins/pos-pro::pos.closed') }}
                                        </span>
                                        <span class="d-none d-xxl-inline" id="register-status-text">
                                            {{ isset($registerStatus) && $registerStatus['is_open'] ? trans('plugins/pos-pro::pos.register_open') : trans('plugins/pos-pro::pos.register_closed') }}
                                        </span>
                                    </button>
                                </div>

                                <!-- Divider -->
                                <div class="vr mx-1 d-none d-lg-block"></div>

                                <!-- Currency Switcher - visible on lg+ -->
                                @if (get_all_currencies()->count() > 1)
                                    <div class="nav-item d-none d-lg-block me-1">
                                        @include('plugins/pos-pro::partials.currency-switcher')
                                    </div>
                                @endif

                                <!-- Language Switcher - visible on lg+ -->
                                @if (is_plugin_active('language') && count(Language::getActiveLanguage()) > 1)
                                    <div class="nav-item d-none d-lg-block">
                                        @include('plugins/pos-pro::partials.language-switcher')
                                    </div>
                                @endif

                                <!-- Current Time Display - visible on xl+ -->
                                <div class="nav-item d-none d-xl-block">
                                    <div id="pos-clock" class="btn btn-ghost-secondary btn-sm d-flex align-items-center gap-1 font-monospace fw-bold text-muted">
                                        <x-core::icon name="ti ti-clock" />
                                        <span id="pos-clock-time">--:--:--</span>
                                    </div>
                                </div>

                                <!-- Customer Display Button - Important, always visible -->
                                <div class="nav-item">
                                    <button id="open-customer-display"
                                        class="btn btn-ghost-secondary btn-sm d-flex align-items-center gap-1"
                                        aria-label="{{ trans('plugins/pos-pro::pos.open_customer_display') }}"
                                        data-customer-display-url="{{ route($routePrefix . '.customer-display') }}"
                                        title="{{ trans('plugins/pos-pro::pos.open_customer_display') }}">
                                        <x-core::icon name="ti ti-device-tv" />
                                        <span class="d-none d-xl-inline">{{ trans('plugins/pos-pro::pos.customer_display') }}</span>
                                    </button>
                                </div>

                                <!-- Tools Dropdown - groups Calculator, Fullscreen, Theme, Currency -->
                                <div class="nav-item dropdown">
                                    <button class="btn btn-ghost-secondary btn-sm d-flex align-items-center gap-1"
                                        data-bs-toggle="dropdown"
                                        aria-label="{{ __('Tools') }}"
                                        title="{{ __('Tools') }}">
                                        <x-core::icon name="ti ti-tools" />
                                        <span class="d-none d-xl-inline">{{ __('Tools') }}</span>
                                        <x-core::icon name="ti ti-chevron-down" class="ms-1" style="font-size: 0.75rem;" />
                                    </button>
                                    <div class="dropdown-menu dropdown-menu-end">
                                        <!-- Calculator -->
                                        <button id="calculator-toggle"
                                            class="dropdown-item d-flex align-items-center gap-2"
                                            data-bs-toggle="modal"
                                            data-bs-target="#calculator-modal">
                                            <x-core::icon name="ti ti-calculator" />
                                            {{ trans('plugins/pos-pro::pos.calculator') }}
                                        </button>

                                        <!-- Full Screen Toggle -->
                                        <button id="fullscreen-toggle"
                                            class="dropdown-item d-flex align-items-center gap-2"
                                            data-fullscreen-text="{{ trans('plugins/pos-pro::pos.fullscreen') }}"
                                            data-exit-fullscreen-text="{{ trans('plugins/pos-pro::pos.exit_fullscreen') }}">
                                            <x-core::icon name="ti ti-maximize" id="fullscreen-icon" />
                                            <span id="fullscreen-text">{{ trans('plugins/pos-pro::pos.fullscreen') }}</span>
                                        </button>

                                        <div class="dropdown-divider"></div>

                                        <!-- Dark/Light Mode Toggle -->
                                        @if (AdminHelper::themeMode() === 'dark')
                                            <a href="{{ route('toggle-theme-mode', ['theme' => 'light']) }}"
                                                class="dropdown-item d-flex align-items-center gap-2"
                                                title="{{ trans('core/base::forms.enable_light_mode') }}">
                                                <x-core::icon name="ti ti-sun" />
                                                {{ trans('core/base::forms.enable_light_mode') }}
                                            </a>
                                        @else
                                            <a href="{{ route('toggle-theme-mode', ['theme' => 'dark']) }}"
                                                class="dropdown-item d-flex align-items-center gap-2"
                                                title="{{ trans('core/base::forms.enable_dark_mode') }}">
                                                <x-core::icon name="ti ti-moon" />
                                                {{ trans('core/base::forms.enable_dark_mode') }}
                                            </a>
                                        @endif

                                        <!-- Currency & Language Switcher for smaller screens -->
                                        <div class="d-lg-none">
                                            @if (get_all_currencies()->count() > 1)
                                                <div class="dropdown-item d-flex align-items-center gap-2">
                                                    @include('plugins/pos-pro::partials.currency-switcher')
                                                </div>
                                            @endif

                                            @if (is_plugin_active('language') && count(Language::getActiveLanguage()) > 1)
                                                <div class="dropdown-item d-flex align-items-center gap-2">
                                                    @include('plugins/pos-pro::partials.language-switcher')
                                                </div>
                                            @endif
                                        </div>
                                    </div>
                                </div>

                                <!-- User Profile Dropdown -->
                                <div class="nav-item dropdown">
                                    <a href="#" class="nav-link d-flex lh-1 text-reset p-0 ps-2" data-bs-toggle="dropdown" aria-label="Open user menu">
                                        <span class="avatar avatar-sm" style="background-image: url({{ $posContext['user']['avatar_url'] }});"></span>
                                        <div class="d-none d-xxl-block ps-2">
                                            <div>{{ $posContext['user']['name'] }}</div>
                                            <div class="mt-1 small text-muted">{{ $posContext['user']['email'] }}</div>
                                        </div>
                                    </a>
                                    <div class="dropdown-menu dropdown-menu-end dropdown-menu-arrow">
                                        <a href="{{ $posContext['urls']['profile'] }}" class="dropdown-item">
                                            <x-core::icon name="ti ti-user" class="me-2" />
                                            {{ __('Profile') }}
                                        </a>
                                        <div class="dropdown-divider"></div>
                                        <a href="{{ $posContext['urls']['logout'] }}" class="dropdown-item">
                                            <x-core::icon name="ti ti-logout" class="me-2" />
                                            {{ __('Logout') }}
                                        </a>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Main Content -->
        <div class="container-fluid py-4">
            @yield('content')
        </div>

        <!-- Calculator Modal -->
        @include('plugins/pos-pro::partials.calculator-modal')
    </div>

    @push('header')
        <link href="{{ asset('vendor/core/plugins/pos-pro/css/app.css') }}?v=1.2.3" rel="stylesheet">
        <link href="{{ asset('vendor/core/plugins/pos-pro/css/responsive.css') }}?v=1.2.3" rel="stylesheet">
    @endpush

    @push('footer')
        <script src="{{ asset('vendor/core/plugins/pos-pro/js/variables.js') }}?v=1.2.3"></script>
        <script src="{{ asset('vendor/core/plugins/pos-pro/js/app.js') }}?v=1.2.3"></script>
        <script src="{{ asset('vendor/core/plugins/pos-pro/js/barcode-scanner.js') }}?v=1.2.3"></script>
        <script src="{{ asset('vendor/core/plugins/pos-pro/js/responsive.js') }}?v=1.2.3"></script>
        <script src="{{ asset('vendor/core/plugins/pos-pro/js/clock-calculator.js') }}?v=1.2.3"></script>
    @endpush
</x-core::layouts.base>
