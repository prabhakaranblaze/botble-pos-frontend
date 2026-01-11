<?php

namespace Botble\PosPro\Providers;

use Botble\Base\Facades\DashboardMenu;
use Botble\Base\Facades\PanelSectionManager;
use Botble\Base\PanelSections\PanelSectionItem;
use Botble\Base\Supports\ServiceProvider as BaseServiceProvider;
use Botble\Base\Traits\LoadAndPublishDataTrait;
use Botble\Ecommerce\PanelSections\SettingEcommercePanelSection;
use Botble\PosPro\Facades\PosProHelper;
use Botble\PosPro\Http\Middleware\PosLocaleMiddleware;
use Botble\PosPro\Http\Middleware\VendorPosAccessMiddleware;
use Botble\PosPro\Support\PosProHelper as PosProHelperSupport;
use Illuminate\Foundation\AliasLoader;

class PosProServiceProvider extends BaseServiceProvider
{
    use LoadAndPublishDataTrait;

    public function register(): void
    {
        if (! is_plugin_active('ecommerce')) {
            return;
        }

        $this->app->register(CommandServiceProvider::class);
        $this->app->register(HookServiceProvider::class);
        $this->app->register(FormServiceProvider::class);
        $this->app->register(EventServiceProvider::class);

        $this->app->singleton('pos-pro.helper', function () {
            return new PosProHelperSupport();
        });

        AliasLoader::getInstance()->alias('PosProHelper', PosProHelper::class);
    }

    public function boot(): void
    {
        if (! is_plugin_active('ecommerce')) {
            return;
        }

        $this
            ->setNamespace('plugins/pos-pro')
            ->loadAndPublishConfigurations(['permissions'])
            ->loadAndPublishTranslations()
            ->loadAndPublishViews()
            ->loadMigrations()
            ->loadRoutes()
            ->loadHelpers()
            ->publishAssets();

        if (is_plugin_active('marketplace') && setting('pos_pro_vendor_enabled', true)) {
            $this->loadRoutes(['vendor']);
        }

        $router = $this->app['router'];
        $router->aliasMiddleware('pos-locale', PosLocaleMiddleware::class);
        $router->aliasMiddleware('vendor-pos-access', VendorPosAccessMiddleware::class);

        PanelSectionManager::beforeRendering(function (): void {
            PanelSectionManager::default()
                ->registerItem(
                    SettingEcommercePanelSection::class,
                    fn () => PanelSectionItem::make('settings.ecommerce.pos')
                        ->setTitle(trans('plugins/pos-pro::pos.settings.title'))
                        ->withIcon('ti ti-cash-register')
                        ->withDescription(trans('plugins/pos-pro::pos.settings.description'))
                        ->withPriority(195)
                        ->withRoute('pos-pro.settings.edit')
                );
        });

        $this->app->booted(function (): void {
            if (is_plugin_active('marketplace') && setting('pos_pro_vendor_enabled', true)) {
                DashboardMenu::for('vendor')->beforeRetrieving(function (): void {
                    $store = auth('customer')->user()?->store;

                    if (! $store || ! $store->pos_enabled) {
                        return;
                    }

                    DashboardMenu::make()
                        ->registerItem([
                            'id' => 'cms-plugins-vendor-pos',
                            'priority' => 15,
                            'parent_id' => null,
                            'name' => trans('plugins/pos-pro::pos.name'),
                            'icon' => 'ti ti-cash-register',
                            'url' => fn () => route('marketplace.vendor.pos.index'),
                        ]);
                });
            }

            DashboardMenu::default()->beforeRetrieving(function (): void {
                DashboardMenu::make()
                    ->registerItem([
                        'id' => 'cms-plugins-pos-pro',
                        'priority' => 5,
                        'parent_id' => null,
                        'name' => 'plugins/pos-pro::pos.name',
                        'icon' => 'ti ti-cash-register',
                        'url' => fn () => route('pos-pro.index'),
                        'permissions' => ['pos.index'],
                    ])
                    ->registerItem([
                        'id' => 'cms-plugins-pos-pro-pos',
                        'priority' => 0,
                        'parent_id' => 'cms-plugins-pos-pro',
                        'name' => 'plugins/pos-pro::pos.pos',
                        'icon' => 'ti ti-devices',
                        'url' => fn () => route('pos-pro.index'),
                        'permissions' => ['pos.index'],
                    ])
                    ->registerItem([
                        'id' => 'cms-plugins-pos-pro-orders',
                        'priority' => 1,
                        'parent_id' => 'cms-plugins-pos-pro',
                        'name' => 'plugins/pos-pro::pos.orders',
                        'icon' => 'ti ti-receipt',
                        'url' => fn () => route('pos-pro.orders.index'),
                        'permissions' => ['pos.orders'],
                    ])
                    ->registerItem([
                        'id' => 'cms-plugins-pos-pro-devices',
                        'priority' => 2,
                        'parent_id' => 'cms-plugins-pos-pro',
                        'name' => 'plugins/pos-pro::pos.device_management.title',
                        'icon' => 'ti ti-router',
                        'url' => fn () => route('pos-devices.index'),
                        'permissions' => ['pos.devices'],
                    ])
                    ->registerItem([
                        'id' => 'cms-plugins-pos-pro-reports',
                        'priority' => 3,
                        'parent_id' => 'cms-plugins-pos-pro',
                        'name' => 'plugins/pos-pro::pos.reports.title',
                        'icon' => 'ti ti-chart-bar',
                        'url' => fn () => route('pos-pro.reports.index'),
                        'permissions' => ['pos.reports'],
                    ])
                    ->registerItem([
                        'id' => 'cms-plugins-pos-pro-registers',
                        'priority' => 4,
                        'parent_id' => 'cms-plugins-pos-pro',
                        'name' => 'plugins/pos-pro::pos.register_history',
                        'icon' => 'ti ti-cash-register',
                        'url' => fn () => route('pos-pro.registers.index'),
                        'permissions' => ['pos.registers'],
                    ])
                    ->registerItem([
                        'id' => 'cms-plugins-pos-pro-settings',
                        'priority' => 5,
                        'parent_id' => 'cms-plugins-pos-pro',
                        'name' => 'plugins/pos-pro::pos.settings.title',
                        'icon' => 'ti ti-settings',
                        'url' => fn () => route('pos-pro.settings.edit'),
                        'permissions' => ['pos.settings'],
                    ]);
            });
        });
    }
}
