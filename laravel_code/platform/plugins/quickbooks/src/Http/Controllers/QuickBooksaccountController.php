<?php

namespace Botble\Quickbooks\Http\Controllers;

use Botble\Base\Http\Controllers\BaseController;
use Botble\Base\Http\Responses\BaseHttpResponse;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Botble\Quickbooks\Services\QuickBooksService;
use QuickBooksOnline\API\DataService\DataService;
use Illuminate\Support\Facades\Storage;
use Botble\Quickbooks\Models\QuickbooksToken;
use Botble\Quickbooks\Tables\QuickbooksAccountTable;

class QuickBooksaccountController extends BaseController
{
    public function QuickbooksAccounts(QuickbooksAccountTable $dataTable)
    {
        $this->pageTitle(trans('plugins/quickbooks::qbs.accounts.title'));
        
        return $dataTable->renderTable();
    }


}
