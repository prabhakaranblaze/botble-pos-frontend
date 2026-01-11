<?php

namespace Botble\Quickbooks\Models;

use Botble\Base\Casts\SafeContent;
use Botble\Base\Enums\BaseStatusEnum;
use Botble\Base\Models\BaseModel;
use Botble\Ecommerce\Models\Order;
use Illuminate\Database\Eloquent\Relations\HasMany;

class QuickbooksJob extends BaseModel
{
    protected $table = 'quickbooks_jobs';

    protected $fillable = [
        'order_id',
        'amount',
        'payload',
        'quickbook_response',
        'status',
        'post_url',
        'environment',
        'fail_count',
        'qb_sales_receipt_id',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id');
    }
}
