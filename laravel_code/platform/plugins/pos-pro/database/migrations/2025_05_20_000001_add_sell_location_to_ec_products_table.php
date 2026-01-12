<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class () extends Migration {
    public function up(): void
    {
        if (! Schema::hasColumn('ec_products', 'is_available_in_pos')) {
            Schema::table('ec_products', function (Blueprint $table): void {
                $table->boolean('is_available_in_pos')->default(true)->after('stock_status');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('ec_products', 'is_available_in_pos')) {
            Schema::table('ec_products', function (Blueprint $table): void {
                $table->dropColumn('is_available_in_pos');
            });
        }
    }
};
