<?php

namespace Botble\PosPro\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class VendorPosAccessMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        $store = auth('customer')->user()?->store;

        abort_unless($store, 403, trans('plugins/marketplace::marketplace.store_not_found'));

        abort_unless($store->pos_enabled, 403, trans('plugins/pos-pro::pos.vendor_pos_disabled'));

        return $next($request);
    }
}
