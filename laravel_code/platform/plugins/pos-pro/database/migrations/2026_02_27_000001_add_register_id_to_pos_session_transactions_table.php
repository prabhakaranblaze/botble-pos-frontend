<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Add register_id column to pos_session_transactions
     * This links transactions to pos_registers (the simpler session model)
     * while keeping the existing session_id FK to pos_sessions optional.
     */
    public function up(): void
    {
        Schema::table('pos_session_transactions', function (Blueprint $table) {
            // Make session_id nullable since we now use register_id
            $table->dropForeign(['session_id']);
            $table->unsignedBigInteger('session_id')->nullable()->change();
            $table->foreign('session_id')
                ->references('id')
                ->on('pos_sessions')
                ->onDelete('set null');

            // Add register_id linking to pos_registers
            $table->unsignedBigInteger('register_id')->nullable()->after('session_id');
            $table->foreign('register_id')
                ->references('id')
                ->on('pos_registers')
                ->onDelete('set null');

            $table->index('register_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('pos_session_transactions', function (Blueprint $table) {
            $table->dropForeign(['register_id']);
            $table->dropIndex(['register_id']);
            $table->dropColumn('register_id');

            $table->dropForeign(['session_id']);
            $table->unsignedBigInteger('session_id')->nullable(false)->change();
            $table->foreign('session_id')
                ->references('id')
                ->on('pos_sessions')
                ->onDelete('cascade');
        });
    }
};
