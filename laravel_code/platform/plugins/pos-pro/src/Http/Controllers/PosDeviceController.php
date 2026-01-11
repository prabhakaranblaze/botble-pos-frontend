<?php

namespace Botble\PosPro\Http\Controllers;

use Botble\Base\Events\CreatedContentEvent;
use Botble\Base\Events\DeletedContentEvent;
use Botble\Base\Events\UpdatedContentEvent;
use Botble\Base\Facades\PageTitle;
use Botble\Base\Http\Controllers\BaseController;
use Botble\Base\Http\Responses\BaseHttpResponse;
use Botble\PosPro\Forms\PosDeviceConfigForm;
use Botble\PosPro\Http\Requests\PosDeviceConfigRequest;
use Botble\PosPro\Models\PosDeviceConfig;
use Botble\PosPro\Tables\PosDeviceConfigTable;
use Exception;
use Illuminate\Http\Request;

class PosDeviceController extends BaseController
{
    public function index(PosDeviceConfigTable $table)
    {
        PageTitle::setTitle(trans('plugins/pos-pro::pos.device_management.title'));

        return $table->renderTable();
    }

    public function create()
    {
        PageTitle::setTitle(trans('plugins/pos-pro::pos.device_management.create'));

        return PosDeviceConfigForm::create()->renderForm();
    }

    public function store(PosDeviceConfigRequest $request, BaseHttpResponse $response)
    {
        $deviceConfig = PosDeviceConfig::query()->create($request->validated());

        event(new CreatedContentEvent(POS_DEVICE_CONFIG_MODULE_SCREEN_NAME, $request, $deviceConfig));

        return $response
            ->setNextUrl(route('pos-devices.edit', $deviceConfig->id))
            ->setMessage(trans('core/base::notices.create_success_message'));
    }

    public function show(PosDeviceConfig $posDevice)
    {
        PageTitle::setTitle(trans('plugins/pos-pro::pos.device_management.edit'));

        return view('plugins/pos-pro::devices.show', compact('posDevice'));
    }

    public function edit(PosDeviceConfig $posDevice)
    {
        PageTitle::setTitle(trans('plugins/pos-pro::pos.device_management.edit'));

        return PosDeviceConfigForm::createFromModel($posDevice)->renderForm();
    }

    public function update(PosDeviceConfig $posDevice, PosDeviceConfigRequest $request, BaseHttpResponse $response)
    {
        $posDevice->fill($request->validated());
        $posDevice->save();

        event(new UpdatedContentEvent(POS_DEVICE_CONFIG_MODULE_SCREEN_NAME, $request, $posDevice));

        return $response
            ->setNextUrl(route('pos-devices.edit', $posDevice->id))
            ->setMessage(trans('core/base::notices.update_success_message'));
    }

    public function destroy(PosDeviceConfig $posDevice, Request $request, BaseHttpResponse $response)
    {
        try {
            $posDevice->delete();

            event(new DeletedContentEvent(POS_DEVICE_CONFIG_MODULE_SCREEN_NAME, $request, $posDevice));

            return $response->setMessage(trans('core/base::notices.delete_success_message'));
        } catch (Exception $exception) {
            return $response
                ->setError()
                ->setMessage($exception->getMessage());
        }
    }

    public function deletes(Request $request, BaseHttpResponse $response)
    {
        $ids = $request->input('ids');
        if (empty($ids)) {
            return $response
                ->setError()
                ->setMessage(trans('core/base::notices.no_select'));
        }

        foreach ($ids as $id) {
            $posDevice = PosDeviceConfig::query()->findOrFail($id);
            $posDevice->delete();
        }

        return $response->setMessage(trans('core/base::notices.delete_success_message'));
    }
}
