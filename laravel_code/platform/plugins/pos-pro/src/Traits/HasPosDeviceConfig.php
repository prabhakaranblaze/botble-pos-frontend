<?php

namespace Botble\PosPro\Traits;

use Botble\PosPro\Models\PosDeviceConfig;
use Illuminate\Database\Eloquent\Relations\HasOne;

trait HasPosDeviceConfig
{
    public function posDeviceConfig(): HasOne
    {
        return $this->hasOne(PosDeviceConfig::class);
    }

    public function getPosDeviceIpAttribute(): ?string
    {
        return $this->posDeviceConfig?->device_ip;
    }

    public function getPosDeviceNameAttribute(): ?string
    {
        return $this->posDeviceConfig?->device_name;
    }

    public function hasPosDeviceConfig(): bool
    {
        return $this->posDeviceConfig &&
               $this->posDeviceConfig->is_active &&
               ! empty($this->posDeviceConfig->device_ip);
    }

    public function setPosDeviceConfig(?string $deviceIp, ?string $deviceName = null): PosDeviceConfig
    {
        return PosDeviceConfig::setForUser($this->id, $deviceIp, $deviceName);
    }
}
