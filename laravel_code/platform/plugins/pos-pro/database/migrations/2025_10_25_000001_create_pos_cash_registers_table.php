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
        Schema::create('pos_cash_registers', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // e.g., "Register 1", "Main Counter"
            $table->string('code')->unique(); // e.g., "REG-001"
            $table->unsignedBigInteger('store_id');
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->decimal('initial_float', 15, 2)->default(0); // Starting cash amount
            $table->timestamps();

            $table->foreign('store_id')
                ->references('id')
                ->on('mp_stores')
                ->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pos_cash_registers');
    }
};
