<?php

namespace Botble\PosPro\Http\Controllers;

use Botble\Base\Http\Controllers\BaseController;
use Botble\Base\Http\Responses\BaseHttpResponse;
use Botble\PosPro\Models\PosRegister;
use Botble\PosPro\Services\RegisterService;
use Illuminate\Http\Request;

class RegisterController extends BaseController
{
    public function __construct(protected RegisterService $registerService)
    {
    }

    public function status(BaseHttpResponse $response)
    {
        //$userId = auth()->id();
        $userId = $this->getAuthUserId();

        $result = $this->registerService->getRegisterStatus($userId);

        return $response
            ->setData($result)
            ->toApiResponse();
    }

    public function open(Request $request, BaseHttpResponse $response)
    {
        $request->validate([
            'cash_start' => ['required', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);

        //$userId = auth()->id();
        $userId = $this->getAuthUserId();
        $cashStart = (float) $request->input('cash_start', 0);
        $notes = $request->input('notes');

        $result = $this->registerService->openRegister($userId, $cashStart, $notes);

        if ($result['error'] ?? false) {
            return $response
                ->setError()
                ->setMessage($result['message'])
                ->toApiResponse();
        }

        return $response
            ->setData($result)
            ->setMessage($result['message'])
            ->toApiResponse();
    }

    public function close(Request $request, BaseHttpResponse $response)
    {
        $request->validate([
            'actual_cash' => ['required', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);

        //$userId = auth()->id();
        $userId = $this->getAuthUserId();
        $actualCash = (float) $request->input('actual_cash', 0);
        $notes = $request->input('notes');

        $result = $this->registerService->closeRegister($userId, $actualCash, $notes);

        if ($result['error'] ?? false) {
            return $response
                ->setError()
                ->setMessage($result['message'])
                ->toApiResponse();
        }

        return $response
            ->setData($result)
            ->setMessage($result['message'])
            ->toApiResponse();
    }

    public function history(BaseHttpResponse $response)
    {
        //$userId = auth()->id();
        $userId = $this->getAuthUserId();

        $registers = $this->registerService->getRegisterHistory($userId);

        return $response
            ->setData(['registers' => $registers])
            ->toApiResponse();
    }

    public function index()
    {
        $this->pageTitle(trans('plugins/pos-pro::pos.register_history'));

        $registers = PosRegister::query()
            ->with('user')
            ->latest('opened_at')
            ->paginate(20);

        return view('plugins/pos-pro::registers.index', compact('registers'));
    }

    protected function getAuthUserId(): int
    {
        if (auth()->check()) {
            return auth()->id(); // Admin
        }

        if (auth('customer')->check()) {
            return auth('customer')->id(); // Vendor
        }

        abort(401);
    }
}
