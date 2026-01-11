<?php

namespace Botble\Quickbooks\Models;

use Botble\Base\Casts\SafeContent;
use Botble\Base\Enums\BaseStatusEnum;
use Botble\Base\Models\BaseModel;
use Illuminate\Database\Eloquent\Relations\HasMany;

class QuickbooksToken extends BaseModel
{
    protected $table = 'quickbooks_tokens';

    protected $fillable = [
        'access_token',
        'refresh_token',
        'realm_id',
        'environment'
    ];
}
