<?php

namespace Botble\PosPro\Forms;

use Botble\ACL\Models\User;
use Botble\Base\Forms\FieldOptions\OnOffFieldOption;
use Botble\Base\Forms\FieldOptions\SelectFieldOption;
use Botble\Base\Forms\FieldOptions\TextFieldOption;
use Botble\Base\Forms\Fields\OnOffField;
use Botble\Base\Forms\Fields\SelectField;
use Botble\Base\Forms\Fields\TextField;
use Botble\Base\Forms\FormAbstract;
use Botble\PosPro\Http\Requests\PosDeviceConfigRequest;
use Botble\PosPro\Models\PosDeviceConfig;

class PosDeviceConfigForm extends FormAbstract
{
    public function setup(): void
    {
        $users = User::query()
            ->select(['id', 'first_name', 'last_name', 'username'])
            ->get()
            ->mapWithKeys(function ($user) {
                return [$user->id => $user->name . ' (' . $user->username . ')'];
            })
            ->toArray();

        $this
            ->model(PosDeviceConfig::class)
            ->setValidatorClass(PosDeviceConfigRequest::class)
            ->setFormOption('id', 'pos-device-config-form')
            ->setMethod('POST')
            ->columns()
            ->add(
                'user_id',
                SelectField::class,
                SelectFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.device_user'))
                    ->helperText(trans('plugins/pos-pro::pos.device_user_help'))
                    ->choices(['' => trans('plugins/pos-pro::pos.select_user')] + $users)
                    ->required()
                    ->colspan(2)
            )
            ->add(
                'device_ip',
                TextField::class,
                TextFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.device_ip'))
                    ->helperText(trans('plugins/pos-pro::pos.device_ip_help'))
                    ->placeholder('192.168.1.100')
                    ->maxLength(45)
                    ->colspan(1)
            )
            ->add(
                'device_name',
                TextField::class,
                TextFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.device_name'))
                    ->helperText(trans('plugins/pos-pro::pos.device_name_help'))
                    ->placeholder('Receipt Printer')
                    ->maxLength(255)
                    ->colspan(1)
            )
            ->add(
                'is_active',
                OnOffField::class,
                OnOffFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.device_active'))
                    ->helperText(trans('plugins/pos-pro::pos.device_active_help'))
                    ->defaultValue(true)
                    ->colspan(2)
            );
    }
}
