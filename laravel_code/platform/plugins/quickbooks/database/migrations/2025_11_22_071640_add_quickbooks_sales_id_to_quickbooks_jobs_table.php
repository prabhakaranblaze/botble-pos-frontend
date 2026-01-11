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
        Schema::table('quickbooks_jobs', function (Blueprint $table) {
            $table->string('qb_sales_receipt_id')->nullable()->after('fail_count')->comment('QuickBooks Sales Receipt ID');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('quickbooks_jobs', function (Blueprint $table) {
            $table->dropColumn('qb_sales_receipt_id');
        });
    }
};
