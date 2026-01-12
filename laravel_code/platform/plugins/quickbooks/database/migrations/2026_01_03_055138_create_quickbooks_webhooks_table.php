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
        Schema::create('quickbooks_webhooks', function (Blueprint $table) {
            $table->id();
            $table->string('webhook_id')->nullable(); // corresponds to 'id'
            $table->string('event_id')->nullable();
            $table->string('specversion')->nullable();
            $table->string('source')->nullable();
            $table->string('event_type')->nullable(); // corresponds to 'type'
            $table->string('intuit_entity_id')->nullable();
            $table->string('intuit_account_id')->nullable();
            $table->string('datacontenttype')->nullable();
            $table->timestamp('event_time')->nullable(); // corresponds to 'time'
            $table->text('payload')->nullable(); // 'data' JSON
            $table->text('headers')->nullable(); // full request headers
            $table->string('environment')->default('sandbox');
            $table->enum('status', ['pending', 'processed', 'failed'])->default('pending');
            $table->timestamps(); // created_at & updated_at
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('quickbooks_webhooks');
    }
};
