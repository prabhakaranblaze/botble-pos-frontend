<?php

namespace Botble\PosPro\Http\Requests;

use Botble\Support\Http\Requests\Request;
use Illuminate\Validation\Rule;

class PosDeviceConfigRequest extends Request
{
    public function rules(): array
    {
        $rules = [
            'user_id' => [
                'required',
                'integer',
                'exists:users,id',
                Rule::unique('pos_device_configs', 'user_id')->ignore($this->route('pos_device')?->id),
            ],
            'device_ip' => [
                'nullable',
                'string',
                'max:45',
                'regex:/^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/',
                function ($attribute, $value, $fail): void {
                    if ($value && ! $this->isPrivateIp($value)) {
                        $fail(trans('plugins/pos-pro::pos.device_ip_private_only'));
                    }
                },
            ],
            'device_name' => [
                'nullable',
                'string',
                'max:255',
            ],
            'is_active' => [
                'boolean',
            ],
        ];

        return $rules;
    }

    public function attributes(): array
    {
        return [
            'user_id' => trans('plugins/pos-pro::pos.device_user'),
            'device_ip' => trans('plugins/pos-pro::pos.device_ip'),
            'device_name' => trans('plugins/pos-pro::pos.device_name'),
            'is_active' => trans('plugins/pos-pro::pos.device_active'),
        ];
    }

    protected function isPrivateIp(string $ip): bool
    {
        if (! filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
            return false;
        }

        $privateRanges = [
            '10.0.0.0/8',
            '172.16.0.0/12',
            '192.168.0.0/16',
            '127.0.0.0/8',
        ];

        foreach ($privateRanges as $range) {
            if ($this->ipInRange($ip, $range)) {
                return true;
            }
        }

        return false;
    }

    protected function ipInRange(string $ip, string $range): bool
    {
        [$subnet, $bits] = explode('/', $range);
        $ip = ip2long($ip);
        $subnet = ip2long($subnet);
        $mask = -1 << (32 - $bits);
        $subnet &= $mask;

        return ($ip & $mask) == $subnet;
    }
}
