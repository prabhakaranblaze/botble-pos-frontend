<?php

namespace Botble\PosPro;

use Botble\PluginManagement\Abstracts\PluginOperationAbstract;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class Plugin extends PluginOperationAbstract
{
    public static function remove(): void
    {
        Schema::dropIfExists('pos_device_configs');

        if (Schema::hasColumn('ec_products', 'is_available_in_pos')) {
            Schema::table('ec_products', function (Blueprint $table): void {
                $table->dropColumn('is_available_in_pos');
            });
        }
    }
}
