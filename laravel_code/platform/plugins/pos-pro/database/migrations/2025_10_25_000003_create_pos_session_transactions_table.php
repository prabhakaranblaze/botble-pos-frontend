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
        Schema::create('pos_session_transactions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('session_id');
            $table->unsignedBigInteger('order_id')->nullable(); // Link to ec_orders
            $table->string('transaction_code')->unique(); // e.g., "TRX-2025-10-25-001"
            
            // Transaction details
            $table->enum('type', ['sale', 'refund', 'withdrawal', 'deposit'])->default('sale');
            $table->decimal('amount', 15, 2);
            $table->enum('payment_method', ['cash', 'card', 'digital_wallet', 'other']);
            
            // Payment details
            $table->json('payment_details')->nullable(); // Card details, transaction ID, etc.
            
            // Cash handling
            $table->decimal('cash_received', 15, 2)->nullable(); // For cash payments
            $table->decimal('change_given', 15, 2)->nullable();
            
            // Additional info
            $table->text('notes')->nullable();
            $table->unsignedBigInteger('user_id'); // Cashier who processed
            
            $table->timestamps();

            $table->foreign('session_id')
                ->references('id')
                ->on('pos_sessions')
                ->onDelete('cascade');
            
            $table->foreign('order_id')
                ->references('id')
                ->on('ec_orders')
                ->onDelete('set null');
            
            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->onDelete('cascade');
            
            $table->index(['session_id', 'created_at']);
            $table->index(['type', 'payment_method']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pos_session_transactions');
    }
};
