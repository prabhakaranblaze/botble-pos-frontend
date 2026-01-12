<?php

namespace Botble\PosPro\Providers;

use Botble\Ecommerce\Events\OrderCreated;
use Botble\PosPro\Listeners\SendOrderToLocalDeviceListener;
use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

class EventServiceProvider extends ServiceProvider
{
    protected $listen = [
        OrderCreated::class => [
            SendOrderToLocalDeviceListener::class,
        ],
    ];
}
