<?php
namespace Botble\Quickbooks\Providers;

use Illuminate\Support\ServiceProvider;
use Botble\Base\Traits\LoadAndPublishDataTrait;
use Botble\Base\Facades\DashboardMenu;
use Botble\Base\Supports\DashboardMenuItem;
use Botble\Base\Facades\Assets;

class QuickbooksServiceProvider extends ServiceProvider
{
    use LoadAndPublishDataTrait;

    public function boot()
    {
        $this
            ->setNamespace('plugins/quickbooks')
            ->loadAndPublishTranslations()
            ->loadAndPublishConfigurations(['permissions'])
            ->loadAndPublishViews()
            ->loadRoutes()
            ->loadMigrations();

        $this->loadViewsFrom(__DIR__ . '/../../resources/views', 'quickbooks');

        DashboardMenu::default()->beforeRetrieving(function (): void {
            DashboardMenu::make()
                ->registerItem(
                    DashboardMenuItem::make()
                        ->id('quickbooks')
                        ->priority(10)
                        ->name('QuickBooks')
                        ->icon('fa fa-q')
                        ->url('#')
                        ->permissions(['quickbooks.index'])
                )
                ->registerItem(
                    DashboardMenuItem::make()
                        ->id('quickbooks-settings')
                        ->priority(1)
                        ->parentId('quickbooks')
                        ->name('Settings')
                        ->icon('fa fa-cog')
                        ->route('quickbooks.settings')
                        ->permissions(['quickbooks.setting'])
                )
                ->registerItem(
                    DashboardMenuItem::make()
                        ->id('quickbooks-crons')
                        ->priority(2)
                        ->parentId('quickbooks')
                        ->name('Crons')
                        ->icon('fa fa-clock')
                        ->route('quickbooks.crons')
                        ->permissions(['quickbooks.cron'])
                )
                ->registerItem(
                    DashboardMenuItem::make()
                        ->id('quickbooks-products')
                        ->priority(3)
                        ->parentId('quickbooks')
                        ->name('Products')
                        ->icon('fa fa-cube')
                        ->route('quickbooks.products')
                        ->permissions(['quickbooks.product'])
                )
                ->registerItem(
                    DashboardMenuItem::make()
                        ->id('quickbooks-categories')
                        ->priority(4)
                        ->parentId('quickbooks')
                        ->name('Categories')
                        ->icon('fa fa-tags')
                        ->route('quickbooks.categories')
                        ->permissions(['quickbooks.category'])
                )
                ->registerItem(
                    DashboardMenuItem::make()
                        ->id('quickbooks-accounts')
                        ->priority(5)
                        ->parentId('quickbooks')
                        ->name('Accounts')
                        ->icon('fa fa-bank')
                        ->route('quickbooks.accounts')
                        ->permissions(['quickbooks.account'])
                );
        });

        $this->publishes([
            __DIR__ . '/../../assets' => public_path('vendor/plugins/quickbooks/assets'),
        ], 'public');

        Assets::addScripts(['jquery']);
        Assets::addScriptsDirectly('vendor/plugins/quickbooks/assets/js/cronlog.js');
    }

    public function register()
    {
        $this->mergeConfigFrom(
            __DIR__ . '/../../config/quickbooks-status.php',
            'quickbooks_status'
        );
        
        $this->mergeConfigFrom(
            __DIR__ . '/../../config/quickbooks-accounts.php',
            'quickbooks-accounts'
        );
    }
}