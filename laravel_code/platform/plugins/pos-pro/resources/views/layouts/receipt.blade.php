@php
    use Botble\Language\Facades\Language;

    $mobileDetect = new \Detection\MobileDetect();
    $isMobile = $mobileDetect->isMobile();
    $routePrefix = $routePrefix ?? 'pos-pro';
    $isVendor = $routePrefix === 'marketplace.vendor.pos';

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
        <!-- Header -->
        <div class="navbar-expand-md">
            <div class="navbar navbar-light">
                <div class="container-fluid d-block">
                    <div class="d-flex align-items-center justify-content-between py-3">
                        <div class="d-flex align-items-center">
                            <x-core::button
                                tag="a"
                                href="{{ route($routePrefix . '.index') }}"
                                color="secondary"
                                icon="ti ti-arrow-left"
                                class="me-3"
                            >
                                {{ trans('plugins/pos-pro::pos.back') }}
                            </x-core::button>
                            <h1 class="h3 mb-0">@yield('header-title', trans('plugins/pos-pro::pos.receipt'))</h1>
                        </div>
                        <div class="d-flex align-items-center">
                            <!-- Dark/Light Mode Toggle -->
                            <div class="nav-item me-3">
                                @include('core/base::layouts.partials.theme-toggle')
                            </div>

                            <div class="nav-item dropdown">
                                <a href="#" class="nav-link d-flex lh-1 text-reset p-0" data-bs-toggle="dropdown" aria-label="Open user menu">
                                    <span class="avatar avatar-sm" style="background-image: url({{ $posContext['user']['avatar_url'] }});"></span>
                                    <div class="d-none d-xl-block ps-2">
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

        <!-- Main Content -->
        <div class="container-fluid py-4">
            @yield('content')
        </div>
    </div>

    @push('header')
        <link href="{{ asset('vendor/core/plugins/pos-pro/css/app.css') }}?v=1.2.3" rel="stylesheet">
    @endpush
</x-core::layouts.base>
