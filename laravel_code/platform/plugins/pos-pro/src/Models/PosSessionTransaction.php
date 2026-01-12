<?php

namespace Botble\PosPro\Models;

use Botble\ACL\Models\User;
use Botble\Base\Models\BaseModel;
use Botble\Ecommerce\Models\Order;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PosSessionTransaction extends BaseModel
{
    /**
     * The table associated with the model.
     */
    protected $table = 'pos_session_transactions';

    /**
     * The attributes that are mass assignable.
     */
    protected $fillable = [
        'session_id',
        'order_id',
        'transaction_code',
        'type',
        'amount',
        'payment_method',
        'payment_details',
        'cash_received',
        'change_given',
        'notes',
        'user_id',
    ];

    /**
     * The attributes that should be cast.
     */
    protected $casts = [
        'amount' => 'decimal:2',
        'cash_received' => 'decimal:2',
        'change_given' => 'decimal:2',
        'payment_details' => 'json',
    ];

    /**
     * Get the session this transaction belongs to.
     */
    public function session(): BelongsTo
    {
        return $this->belongsTo(PosSession::class, 'session_id');
    }

    /**
     * Get the order associated with this transaction (if any).
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * Get the user who processed this transaction.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Scope to get only sales.
     */
    public function scopeSales($query)
    {
        return $query->where('type', 'sale');
    }

    /**
     * Scope to get only refunds.
     */
    public function scopeRefunds($query)
    {
        return $query->where('type', 'refund');
    }

    /**
     * Scope to filter by payment method.
     */
    public function scopeByPaymentMethod($query, string $method)
    {
        return $query->where('payment_method', $method);
    }

    /**
     * Scope to filter by session.
     */
    public function scopeForSession($query, int $sessionId)
    {
        return $query->where('session_id', $sessionId);
    }

    /**
     * Check if transaction is a sale.
     */
    public function isSale(): bool
    {
        return $this->type === 'sale';
    }

    /**
     * Check if transaction is a refund.
     */
    public function isRefund(): bool
    {
        return $this->type === 'refund';
    }

    /**
     * Check if transaction is cash payment.
     */
    public function isCashPayment(): bool
    {
        return $this->payment_method === 'cash';
    }

    /**
     * Check if transaction is card payment.
     */
    public function isCardPayment(): bool
    {
        return $this->payment_method === 'card';
    }
}
