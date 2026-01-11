<?php

namespace Botble\Quickbooks;

use Botble\Menu\Models\MenuNode;
use Botble\Quickbooks\Models\QuickbooksToken;
use Botble\PluginManagement\Abstracts\PluginOperationAbstract;
use Botble\Setting\Facades\Setting;
use Illuminate\Support\Facades\Schema;

class Plugin extends PluginOperationAbstract
{
    public static function activated(): void
    {
        Setting::set([
            'quickbooks_connect' => 0,
            'quickbooks_sales_receipt_delete' => 0,
        ])->save();

    }

    public static function deactivated(): void
    {
        Setting::set([
            'quickbooks_connect' => 0,
            'quickbooks_sales_receipt_delete' => 0,
        ])->save();

        QuickbooksToken::truncate();
    }

    public static function remove(): void
    {
        Setting::delete([
            'quickbooks_connect',
            'quickbooks_sales_receipt_delete',
        ]);
    }
}
