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
        Schema::create('quickbooks_jobs', function (Blueprint $table) {
            $table->id();
            $table->integer('order_id')->default(0)->nullable();
            $table->decimal('amount', 10, 2)->nullable(); 
            $table->text('payload')->nullable();
            $table->text('quickbook_response')->nullable();
            $table->integer('status')->default(0)->comment('0->not triggered, 1->success, 2->failed, 3->deleted')->nullable();
            $table->text('post_url')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('quickbooks_jobs');
    }
};
