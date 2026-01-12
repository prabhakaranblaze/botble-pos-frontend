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
            $table->Integer('status')->comment('0: Pending, 1: In Progress, 2: Success, 3: Failed, 4: Deleted')->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('quickbooks_jobs', function (Blueprint $table) {
            $table->tinyInteger('status')->comment('')->change();
        });
    }
};
