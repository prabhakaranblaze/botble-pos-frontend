<?php

namespace Botble\PosPro\Database\Seeders;

use Botble\ACL\Models\User;
use Botble\Base\Supports\BaseSeeder;
use Botble\PosPro\Models\PosDeviceConfig;

class PosDeviceConfigSeeder extends BaseSeeder
{
    public function run(): void
    {
        $user = User::query()
            ->where('super_user', true)
            ->orWhereHas('roles', function ($query): void {
                $query->where('slug', 'super-user');
            })
            ->first();

        if ($user) {
            PosDeviceConfig::query()->create([
                'user_id' => $user->id,
                'device_ip' => '192.168.1.100',
                'device_name' => 'Demo Receipt Printer',
                'is_active' => true,
            ]);

            $this->command->info('Created demo POS device configuration for user: ' . $user->name);
        } else {
            $this->command->warn('No admin user found to create demo device configuration');
        }
    }
}
