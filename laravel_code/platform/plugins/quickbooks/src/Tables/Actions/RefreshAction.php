<?php

namespace Botble\Quickbooks\Tables\Actions;

class RefreshAction extends Action
{
    public static function make(string $name = 'refresh'): static
    {
        return parent::make($name)
            ->label(trans('plugins/quickbooks::qbs.crons.refresh')) 
            ->color('primary')
            ->icon('ti ti-refresh');
    }
}

