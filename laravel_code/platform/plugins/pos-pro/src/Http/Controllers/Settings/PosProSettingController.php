<?php

namespace Botble\PosPro\Http\Controllers\Settings;

use Botble\PosPro\Forms\Settings\PosProSettingForm;
use Botble\PosPro\Http\Requests\Settings\PosProSettingRequest;
use Botble\Setting\Http\Controllers\SettingController;

class PosProSettingController extends SettingController
{
    public function edit()
    {
        $this->pageTitle(trans('plugins/pos-pro::pos.settings.title'));

        return PosProSettingForm::create()->renderForm();
    }

    public function update(PosProSettingRequest $request)
    {
        return $this->performUpdate($request->validated());
    }
}
