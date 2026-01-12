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
        Schema::table('ec_orders', function (Blueprint $table) {
            if (!Schema::hasColumn('ec_orders', 'quickbooks_sales_receipt_id')) {
                $table->string('quickbooks_sales_receipt_id')->nullable();
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('ec_orders', function (Blueprint $table) {
            if (Schema::hasColumn('ec_orders', 'quickbooks_sales_receipt_id')) {
                $table->dropColumn('quickbooks_sales_receipt_id');
            }
        });
    }
};
