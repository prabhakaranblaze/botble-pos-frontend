<?php

namespace Botble\PosPro\Providers;

use Botble\PosPro\Commands\DemoDataCommand;
use Botble\PosPro\Commands\TestLocalDeviceCommand;
use Illuminate\Support\ServiceProvider;

class CommandServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        if ($this->app->runningInConsole()) {
            $this->commands([
                DemoDataCommand::class,
                TestLocalDeviceCommand::class,
            ]);
        }
    }
}
