<?php

namespace Botble\PosPro\Tables;

use Botble\Base\Facades\Html;
use Botble\Ecommerce\Models\Order;
use Botble\Table\Abstracts\TableAbstract;
use Botble\Table\Actions\ViewAction;
use Botble\Table\BulkChanges\CreatedAtBulkChange;
use Botble\Table\Columns\CreatedAtColumn;
use Botble\Table\Columns\FormattedColumn;
use Botble\Table\Columns\IdColumn;
use Botble\Table\Columns\StatusColumn;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\Relation;
use Illuminate\Database\Query\Builder as QueryBuilder;

class PosOrderTable extends TableAbstract
{
    public function setup(): void
    {
        $this
            ->model(Order::class)
            ->addActions([
                ViewAction::make()->route('orders.edit'),
            ]);
    }

    public function query(): Relation|Builder|QueryBuilder
    {
        $query = $this
            ->getModel()
            ->query()
            ->select([
                'id',
                'code',
                'user_id',
                'amount',
                'payment_id',
                'status',
                'created_at',
            ])
            ->whereHas('payment', function ($q): void {
                $q->whereIn('payment_channel', [
                    POS_PRO_CASH_PAYMENT_METHOD_NAME,
                    POS_PRO_CARD_PAYMENT_METHOD_NAME,
                    POS_PRO_OTHER_PAYMENT_METHOD_NAME,
                ]);
            })
            ->with(['payment', 'user'])
            ->latest();

        return $this->applyScopes($query);
    }

    public function columns(): array
    {
        return [
            IdColumn::make(),
            FormattedColumn::make('code')
                ->title(trans('plugins/pos-pro::pos.order_code'))
                ->alignStart()
                ->renderUsing(function (FormattedColumn $column) {
                    $item = $column->getItem();

                    return Html::link(
                        route('orders.edit', $item->id),
                        $item->code,
                        ['target' => '_blank']
                    )->toHtml();
                }),
            FormattedColumn::make('user_id')
                ->title(trans('plugins/pos-pro::pos.customer'))
                ->alignStart()
                ->orderable(false)
                ->renderUsing(function (FormattedColumn $column) {
                    $item = $column->getItem();

                    if ($item->user_id && $item->user) {
                        return Html::link(
                            route('customers.edit', $item->user_id),
                            $item->user->name,
                            ['target' => '_blank']
                        )->toHtml();
                    }

                    return trans('plugins/pos-pro::pos.guest');
                }),
            FormattedColumn::make('amount')
                ->title(trans('plugins/pos-pro::pos.total'))
                ->alignEnd()
                ->renderUsing(function (FormattedColumn $column) {
                    return format_price($column->getItem()->amount);
                }),
            FormattedColumn::make('payment_id')
                ->title(trans('plugins/pos-pro::pos.payment_method'))
                ->alignStart()
                ->orderable(false)
                ->renderUsing(function (FormattedColumn $column) {
                    $item = $column->getItem();

                    if (! $item->payment || ! $item->payment->payment_channel) {
                        return '—';
                    }

                    return $item->payment->payment_channel->toHtml();
                }),
            StatusColumn::make()
                ->alignStart(),
            CreatedAtColumn::make(),
        ];
    }

    public function buttons(): array
    {
        return [];
    }

    public function bulkActions(): array
    {
        return [];
    }

    public function getBulkChanges(): array
    {
        return [
            CreatedAtBulkChange::make(),
        ];
    }

    public function htmlDrawCallbackFunction(): ?string
    {
        return parent::htmlDrawCallbackFunction() . '$("[data-bs-toggle=tooltip]").tooltip();';
    }
}
