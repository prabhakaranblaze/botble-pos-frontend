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
        Schema::create('pos_denominations', function (Blueprint $table) {
            $table->id();
            $table->string('currency_code', 3)->default('USD'); // USD, EUR, INR, etc.
            $table->decimal('value', 15, 2); // 0.01, 0.05, 1, 5, 10, 20, 50, 100, etc.
            $table->enum('type', ['coin', 'note']);
            $table->string('label'); // e.g., "1 cent", "5 dollars", "10 rupees"
            $table->integer('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['currency_code', 'value', 'type']);
            $table->index(['currency_code', 'is_active']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pos_denominations');
    }
};
