<?php

namespace Botble\Quickbooks\Http\Controllers;

use Botble\Base\Http\Controllers\BaseController;
use Botble\Base\Http\Responses\BaseHttpResponse;
use Botble\Quickbooks\Forms\QuickbooksSettingForm;
use Botble\Quickbooks\Http\Requests\QuickbooksSettingRequest;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Botble\Quickbooks\Services\QuickBooksService;
use QuickBooksOnline\API\DataService\DataService;
use Illuminate\Support\Facades\Storage;
use Botble\Quickbooks\Models\QuickbooksToken;
use Botble\Quickbooks\Models\QuickbooksJob;
use Botble\Slug\Models\Slug;
use Botble\Setting\Facades\Setting;
use Botble\Quickbooks\Tables\CronTable;
use Botble\Setting\Commands\ProcessQuickbooksJobsCommand;

class QuickBookscronController extends BaseController
{
    public function cronLogs(CronTable $dataTable)
    {
        $this->pageTitle(trans('plugins/quickbooks::qbs.crons.title'));
        
        return $dataTable->renderTable();
    }

    public function refresh($id)
    {

        $success = ProcessQuickbooksJobsCommand::processJobById($id);
        
        if ($success) {
            return $this->httpResponse()->setError(false)->setMessage('Sales receipt created in Quickbooks');
        } else {
            \Log::info('QuickBooks job processed', ['job_id' => $id, 'success' => $success]);
            return $this->httpResponse()->setError()->setMessage('Failed to create the sales receipt. For more details, click View to check the error log');
        }

    }

    public function viewCron(Request $request)
    {
        $cron = QuickbooksJob::find($request->id);

        if (!$cron) {
            return response()->json(['error' => 'Not found'], 404);
        }

        return response()->json([
            'post_url' => $cron->post_url,
            'payload' => json_decode($cron->payload), // assuming stored as JSON
            'quickbook_response' => json_decode($cron->quickbook_response) // assuming stored as JSON
        ]);
    }


}
