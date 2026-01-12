<?php

namespace Botble\Ecommerce\Models;

use Botble\Base\Models\BaseModel;
use Illuminate\Database\Eloquent\SoftDeletes;

class Cart extends BaseModel
{
    use SoftDeletes;
    protected $table = 'ec_cart';
}
