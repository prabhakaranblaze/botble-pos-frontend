<?php

namespace Botble\PosPro\Tables;

use Botble\Base\Facades\Html;
use Botble\PosPro\Models\PosDeviceConfig;
use Botble\Table\Abstracts\TableAbstract;
use Botble\Table\Actions\DeleteAction;
use Botble\Table\Actions\EditAction;
use Botble\Table\BulkActions\DeleteBulkAction;
use Botble\Table\BulkChanges\CreatedAtBulkChange;
use Botble\Table\BulkChanges\NameBulkChange;
use Botble\Table\BulkChanges\StatusBulkChange;
use Botble\Table\Columns\CreatedAtColumn;
use Botble\Table\Columns\FormattedColumn;
use Botble\Table\Columns\IdColumn;
use Botble\Table\Columns\StatusColumn;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\Relation;
use Illuminate\Database\Query\Builder as QueryBuilder;

class PosDeviceConfigTable extends TableAbstract
{
    public function setup(): void
    {
        $this
            ->model(PosDeviceConfig::class)
            ->addActions([
                EditAction::make()->route('pos-devices.edit'),
                DeleteAction::make()->route('pos-devices.destroy'),
            ]);
    }

    public function query(): Relation|Builder|QueryBuilder
    {
        $query = $this
            ->getModel()
            ->query()
            ->select([
                'id',
                'user_id',
                'device_ip',
                'device_name',
                'is_active',
                'created_at',
            ])
            ->with(['user:id,first_name,last_name,username']);

        return $this->applyScopes($query);
    }

    public function columns(): array
    {
        return [
            IdColumn::make(),
            FormattedColumn::make('user_id')
                ->title(trans('plugins/pos-pro::pos.device_user'))
                ->alignStart()
                ->renderUsing(function (FormattedColumn $column) {
                    $item = $column->getItem();

                    if (! $item->user) {
                        return '—';
                    }

                    return Html::link(
                        route('users.profile.view', $item->user->id),
                        $item->user->name,
                        ['target' => '_blank']
                    );
                }),
            FormattedColumn::make('device_ip')
                ->title(trans('plugins/pos-pro::pos.device_ip'))
                ->alignStart()
                ->renderUsing(function (FormattedColumn $column) {
                    $item = $column->getItem();

                    return $item->device_ip ?: '—';
                }),
            FormattedColumn::make('device_name')
                ->title(trans('plugins/pos-pro::pos.device_name'))
                ->alignStart()
                ->renderUsing(function (FormattedColumn $column) {
                    $item = $column->getItem();

                    return $item->device_name ?: '—';
                }),
            StatusColumn::make('is_active')
                ->title(trans('plugins/pos-pro::pos.device_active'))
                ->renderUsing(function (StatusColumn $column) {
                    $item = $column->getItem();

                    return $item->is_active
                        ? Html::tag('span', trans('core/base::base.yes'), ['class' => 'label-success status-label'])
                        : Html::tag('span', trans('core/base::base.no'), ['class' => 'label-danger status-label']);
                }),
            CreatedAtColumn::make(),
        ];
    }

    public function buttons(): array
    {
        return $this->addCreateButton(route('pos-devices.create'), 'pos-devices.create');
    }

    public function bulkActions(): array
    {
        return [
            DeleteBulkAction::make()->permission('pos-devices.destroy'),
        ];
    }

    public function getBulkChanges(): array
    {
        return [
            NameBulkChange::make(),
            StatusBulkChange::make(),
            CreatedAtBulkChange::make(),
        ];
    }
}
