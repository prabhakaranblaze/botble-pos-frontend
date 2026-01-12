<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('quickbooks_webhooks', function (Blueprint $table) {
             $table->text('sync_response')->nullable()->after('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('quickbooks_webhooks', function (Blueprint $table) {
             $table->dropColumn('sync_response');
        });
    }
};
