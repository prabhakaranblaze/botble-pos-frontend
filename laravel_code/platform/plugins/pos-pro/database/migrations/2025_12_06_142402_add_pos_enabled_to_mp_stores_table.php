<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class () extends Migration {
    public function up(): void
    {
        if (! Schema::hasColumn('mp_stores', 'pos_enabled')) {
            Schema::table('mp_stores', function (Blueprint $table): void {
                $table->boolean('pos_enabled')->default(true)->after('is_verified');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('mp_stores', 'pos_enabled')) {
            Schema::table('mp_stores', function (Blueprint $table): void {
                $table->dropColumn('pos_enabled');
            });
        }
    }
};
