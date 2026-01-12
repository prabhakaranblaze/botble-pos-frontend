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
             $table->integer('fail_count')->default(0)->after('environment');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('quickbooks_jobs', function (Blueprint $table) {
            $table->dropColumn('fail_count');
        });
    }
};
