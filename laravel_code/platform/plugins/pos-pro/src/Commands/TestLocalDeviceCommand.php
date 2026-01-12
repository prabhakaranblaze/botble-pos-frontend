<?php

namespace Botble\PosPro\Commands;

use Botble\ACL\Models\User;
use Botble\Ecommerce\Events\OrderCreated;
use Botble\Ecommerce\Models\Order;
use Botble\PosPro\Models\PosDeviceConfig;
use Illuminate\Console\Command;

class TestLocalDeviceCommand extends Command
{
    protected $signature = 'pos:test-local-device {user_id} {order_id}';

    protected $description = 'Test sending order data to local device';

    public function handle(): int
    {
        $userId = $this->argument('user_id');
        $orderId = $this->argument('order_id');

        $user = User::query()->find($userId);
        if (! $user) {
            $this->error("User with ID {$userId} not found");

            return 1;
        }

        $order = Order::query()->find($orderId);
        if (! $order) {
            $this->error("Order with ID {$orderId} not found");

            return 1;
        }

        $deviceConfig = PosDeviceConfig::getForUser($userId);

        $this->components->info("Testing local device API call for user: {$user->name}");
        $this->components->info('Device IP: ' . ($deviceConfig?->device_ip ?: 'Not set'));
        $this->components->info('Device Name: ' . ($deviceConfig?->device_name ?: 'Not set'));
        $this->components->info('Device Active: ' . ($deviceConfig?->is_active ? 'Yes' : 'No'));
        $this->components->info("Order: {$order->code}");

        auth()->login($user);
        event(new OrderCreated($order));

        $this->components->info('OrderCreated event fired. Check logs for API call results.');

        return 0;
    }
}
