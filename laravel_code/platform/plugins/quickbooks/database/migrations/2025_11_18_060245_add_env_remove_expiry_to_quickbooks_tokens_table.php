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
        Schema::table('quickbooks_tokens', function (Blueprint $table) {
            
            if (Schema::hasColumn('quickbooks_tokens', 'access_token_expiry')) {
                $table->dropColumn('access_token_expiry');
            }
            
            $table->enum('environment', ['sandbox', 'production'])
                ->default('sandbox')
                ->after('refresh_token'); 
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('quickbooks_tokens', function (Blueprint $table) {
            $table->dateTime('access_token_expiry')->nullable();

            $table->dropColumn('environment');
        });
    }
};
