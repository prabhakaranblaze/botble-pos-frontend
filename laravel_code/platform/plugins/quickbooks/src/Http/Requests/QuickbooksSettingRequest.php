<?php

namespace Botble\Quickbooks\Http\Requests;

use Botble\Support\Http\Requests\Request;

class QuickbooksSettingRequest extends Request
{
    public function rules(): array
    {
        return [
            'qb_client_id' => 'required|string',
            'qb_client_secret' => 'required|string',
            'qb_redirect_uri' => 'required|url',
        ];
    }
}
