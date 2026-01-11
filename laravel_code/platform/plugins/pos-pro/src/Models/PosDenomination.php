<?php

namespace Botble\PosPro\Models;

use Botble\Base\Models\BaseModel;
use Illuminate\Database\Eloquent\SoftDeletes;

class PosDenomination extends BaseModel
{
    /**
     * The table associated with the model.
     */
    use SoftDeletes;
    protected $table = 'pos_denominations';

    /**
     * The attributes that are mass assignable.
     */
    protected $fillable = [
        'currency_code',
        'value',
        'type',
        'label',
        'sort_order',
        'is_active',
    ];

    /**
     * The attributes that should be cast.
     */
    protected $casts = [
        'value' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    /**
     * Scope to get only active denominations.
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope to filter by currency.
     */
    public function scopeForCurrency($query, string $currencyCode)
    {
        return $query->where('currency_code', $currencyCode);
    }

    /**
     * Scope to get only coins.
     */
    public function scopeCoins($query)
    {
        return $query->where('type', 'coin');
    }

    /**
     * Scope to get only notes.
     */
    public function scopeNotes($query)
    {
        return $query->where('type', 'note');
    }

    /**
     * Scope to order by sort order.
     */
    public function scopeOrdered($query)
    {
        return $query->orderBy('sort_order');
    }

    /**
     * Check if denomination is a coin.
     */
    public function isCoin(): bool
    {
        return $this->type === 'coin';
    }

    /**
     * Check if denomination is a note.
     */
    public function isNote(): bool
    {
        return $this->type === 'note';
    }

    /**
     * Calculate total value for given count.
     */
    public function calculateTotal(int $count): float
    {
        return $this->value * $count;
    }
}
