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
        Schema::create('pos_sessions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('cash_register_id');
            $table->unsignedBigInteger('user_id'); // Cashier who opened the session
            $table->unsignedBigInteger('store_id');
            
            // Session details
            $table->string('session_code')->unique(); // e.g., "SES-2025-10-25-001"
            $table->dateTime('opened_at');
            $table->dateTime('closed_at')->nullable();
            
            // Opening cash details
            $table->decimal('opening_cash', 15, 2); // Initial cash in drawer
            $table->json('opening_denominations')->nullable(); // Breakdown of bills/coins
            $table->text('opening_notes')->nullable();
            
            // Closing cash details
            $table->decimal('closing_cash', 15, 2)->nullable(); // Final cash in drawer
            $table->json('closing_denominations')->nullable();
            $table->text('closing_notes')->nullable();
            
            // Session summary (calculated on close)
            $table->decimal('expected_cash', 15, 2)->nullable(); // Opening + cash sales - cash withdrawals
            $table->decimal('cash_difference', 15, 2)->nullable(); // closing_cash - expected_cash
            $table->decimal('total_sales', 15, 2)->nullable();
            $table->integer('total_transactions')->nullable();
            
            // Payment method breakdowns
            $table->decimal('cash_sales', 15, 2)->nullable();
            $table->decimal('card_sales', 15, 2)->nullable();
            $table->decimal('other_sales', 15, 2)->nullable();
            
            // Status
            $table->enum('status', ['open', 'closed', 'suspended'])->default('open');
            
            $table->timestamps();

            $table->foreign('cash_register_id')
                ->references('id')
                ->on('pos_cash_registers')
                ->onDelete('cascade');
            
            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->onDelete('cascade');
            
            $table->foreign('store_id')
                ->references('id')
                ->on('mp_stores')
                ->onDelete('cascade');
            
            $table->index(['status', 'opened_at']);
            $table->index(['cash_register_id', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pos_sessions');
    }
};
