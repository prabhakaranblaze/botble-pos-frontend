<?php

namespace Botble\PosPro\Models;

use Botble\ACL\Models\User;
use Botble\Base\Models\BaseModel;
use Botble\Marketplace\Models\Store;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PosSession extends BaseModel
{
    /**
     * The table associated with the model.
     */
    protected $table = 'pos_sessions';

    /**
     * The attributes that are mass assignable.
     */
    protected $fillable = [
        'cash_register_id',
        'user_id',
        'store_id',
        'session_code',
        'opened_at',
        'closed_at',
        'opening_cash',
        'opening_denominations',
        'opening_notes',
        'closing_cash',
        'closing_denominations',
        'closing_notes',
        'expected_cash',
        'cash_difference',
        'total_sales',
        'total_transactions',
        'cash_sales',
        'card_sales',
        'other_sales',
        'status',
    ];

    /**
     * The attributes that should be cast.
     */
    protected $casts = [
        'opened_at' => 'datetime',
        'closed_at' => 'datetime',
        'opening_cash' => 'decimal:2',
        'closing_cash' => 'decimal:2',
        'expected_cash' => 'decimal:2',
        'cash_difference' => 'decimal:2',
        'total_sales' => 'decimal:2',
        'cash_sales' => 'decimal:2',
        'card_sales' => 'decimal:2',
        'other_sales' => 'decimal:2',
        'opening_denominations' => 'json',
        'closing_denominations' => 'json',
    ];

    /**
     * Get the cash register that owns this session.
     */
    public function cashRegister(): BelongsTo
    {
        return $this->belongsTo(PosCashRegister::class, 'cash_register_id');
    }

    /**
     * Get the user (cashier) who opened the session.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the store this session belongs to.
     */
    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    /**
     * Get all transactions in this session.
     */
    public function transactions(): HasMany
    {
        return $this->hasMany(PosSessionTransaction::class, 'session_id');
    }

    /**
     * Scope to get only open sessions.
     */
    public function scopeOpen($query)
    {
        return $query->where('status', 'open');
    }

    /**
     * Scope to get only closed sessions.
     */
    public function scopeClosed($query)
    {
        return $query->where('status', 'closed');
    }

    /**
     * Scope to filter by store.
     */
    public function scopeForStore($query, int $storeId)
    {
        return $query->where('store_id', $storeId);
    }

    /**
     * Scope to filter by user.
     */
    public function scopeForUser($query, int $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     * Check if session is open.
     */
    public function isOpen(): bool
    {
        return $this->status === 'open';
    }

    /**
     * Check if session is closed.
     */
    public function isClosed(): bool
    {
        return $this->status === 'closed';
    }

    /**
     * Calculate session summary before closing.
     */
    public function calculateSummary(): array
    {
        $transactions = $this->transactions;

        $summary = [
            'total_transactions' => $transactions->count(),
            'total_sales' => $transactions->where('type', 'sale')->sum('amount'),
            'cash_sales' => $transactions->where('type', 'sale')->where('payment_method', 'cash')->sum('amount'),
            'card_sales' => $transactions->where('type', 'sale')->where('payment_method', 'card')->sum('amount'),
            'other_sales' => $transactions->where('type', 'sale')->whereNotIn('payment_method', ['cash', 'card'])->sum('amount'),
            'total_refunds' => $transactions->where('type', 'refund')->sum('amount'),
            'withdrawals' => $transactions->where('type', 'withdrawal')->sum('amount'),
            'deposits' => $transactions->where('type', 'deposit')->sum('amount'),
        ];

        // Calculate expected cash
        $summary['expected_cash'] = $this->opening_cash 
            + $summary['cash_sales'] 
            + $summary['deposits']
            - $summary['withdrawals']
            - $transactions->where('type', 'refund')->where('payment_method', 'cash')->sum('amount');

        return $summary;
    }

    /**
     * Close the session with final cash count.
     */
    public function close(float $closingCash, ?array $closingDenominations = null, ?string $closingNotes = null): void
    {
        $summary = $this->calculateSummary();

        $this->update([
            'closed_at' => now(),
            'closing_cash' => $closingCash,
            'closing_denominations' => $closingDenominations,
            'closing_notes' => $closingNotes,
            'expected_cash' => $summary['expected_cash'],
            'cash_difference' => $closingCash - $summary['expected_cash'],
            'total_sales' => $summary['total_sales'],
            'total_transactions' => $summary['total_transactions'],
            'cash_sales' => $summary['cash_sales'],
            'card_sales' => $summary['card_sales'],
            'other_sales' => $summary['other_sales'],
            'status' => 'closed',
        ]);
    }
}
