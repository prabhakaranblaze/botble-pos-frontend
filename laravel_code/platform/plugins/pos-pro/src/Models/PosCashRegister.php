<?php

namespace Botble\PosPro\Models;

use Botble\Base\Models\BaseModel;
use Botble\Marketplace\Models\Store;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class PosCashRegister extends BaseModel
{
    /**
     * The table associated with the model.
     */
    use SoftDeletes;
    protected $table = 'pos_cash_registers';

    /**
     * The attributes that are mass assignable.
     */
    protected $fillable = [
        'name',
        'code',
        'store_id',
        'description',
        'is_active',
        'initial_float',
    ];

    /**
     * The attributes that should be cast.
     */
    protected $casts = [
        'is_active' => 'boolean',
        'initial_float' => 'decimal:2',
    ];

    /**
     * Get the store that owns the cash register.
     */
    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    /**
     * Get all sessions for this cash register.
     */
    public function sessions(): HasMany
    {
        return $this->hasMany(PosSession::class, 'cash_register_id');
    }

    /**
     * Get the current open session for this register.
     */
    public function currentSession()
    {
        return $this->sessions()
            ->where('status', 'open')
            ->latest('opened_at')
            ->first();
    }

    /**
     * Check if register has an open session.
     */
    public function hasOpenSession(): bool
    {
        return $this->currentSession() !== null;
    }

    /**
     * Scope to get only active registers.
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope to filter by store.
     */
    public function scopeForStore($query, int $storeId)
    {
        return $query->where('store_id', $storeId);
    }
}
