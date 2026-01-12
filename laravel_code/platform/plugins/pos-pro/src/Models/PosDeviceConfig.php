<?php

namespace Botble\PosPro\Models;

use Botble\ACL\Models\User;
use Botble\Base\Models\BaseModel;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PosDeviceConfig extends BaseModel
{
    protected $table = 'pos_device_configs';

    protected $fillable = [
        'user_id',
        'device_ip',
        'device_name',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public static function getForUser(int $userId): ?self
    {
        return static::query()->where('user_id', $userId)
            ->where('is_active', true)
            ->first();
    }

    public static function setForUser(int $userId, ?string $deviceIp, ?string $deviceName = null): self
    {
        return static::query()->updateOrCreate(['user_id' => $userId], [
            'device_ip' => $deviceIp,
            'device_name' => $deviceName,
            'is_active' => ! empty($deviceIp),
        ]);
    }

    public function isValidPrivateIp(): bool
    {
        if (! $this->device_ip || ! filter_var($this->device_ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
            return false;
        }

        $privateRanges = [
            '10.0.0.0/8',
            '172.16.0.0/12',
            '192.168.0.0/16',
            '127.0.0.0/8',
        ];

        foreach ($privateRanges as $range) {
            if ($this->ipInRange($this->device_ip, $range)) {
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
