<?php

namespace Botble\Quickbooks\Models;

use Botble\Base\Models\BaseModel;

class QuickbooksWebhook extends BaseModel
{
    protected $table = 'quickbooks_webhooks';

    protected $fillable = [
        'webhook_id',
        'event_id',
        'specversion',
        'source',
        'event_type',
        'intuit_entity_id',
        'intuit_account_id',
        'datacontenttype',
        'event_time',
        'payload',
        'headers',
        'environment',
        'status',
        'sync_response',
    ];

    protected $casts = [
        'payload' => 'array',
        'headers' => 'array',
        'event_time' => 'datetime',
    ];
}
