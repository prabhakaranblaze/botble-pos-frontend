<?php

namespace Botble\PosPro\Models;

use Botble\ACL\Models\User;
use Botble\Base\Models\BaseModel;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PosRegister extends BaseModel
{
    protected $table = 'pos_registers';

    protected $fillable = [
        'user_id',
        'cash_start',
        'cash_end',
        'actual_cash',
        'difference',
        'opened_at',
        'closed_at',
        'status',
        'notes',
    ];

    protected $casts = [
        'cash_start' => 'decimal:2',
        'cash_end' => 'decimal:2',
        'actual_cash' => 'decimal:2',
        'difference' => 'decimal:2',
        'opened_at' => 'datetime',
        'closed_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function scopeOpen(Builder $query): Builder
    {
        return $query->where('status', 'open');
    }

    public function scopeClosed(Builder $query): Builder
    {
        return $query->where('status', 'closed');
    }

    public function scopeForUser(Builder $query, int $userId): Builder
    {
        return $query->where('user_id', $userId);
    }

    public function isOpen(): bool
    {
        return $this->status === 'open';
    }

    public function isClosed(): bool
    {
        return $this->status === 'closed';
    }

    public static function getOpenRegisterForUser(int $userId): ?self
    {
        return static::query()
            ->forUser($userId)
            ->open()
            ->first();
    }

    public static function hasOpenRegister(int $userId): bool
    {
        return static::query()
            ->forUser($userId)
            ->open()
            ->exists();
    }
}
