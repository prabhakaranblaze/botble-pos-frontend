<?php

namespace Botble\Ecommerce\Models;

use Botble\Base\Models\BaseModel;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class OrderTaxInformation extends BaseModel
{
    use SoftDeletes;
    protected $table = 'ec_order_tax_information';

    protected $fillable = [
        'order_id',
        'company_name',
        'company_address',
        'company_tax_code',
        'company_email',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }
}
