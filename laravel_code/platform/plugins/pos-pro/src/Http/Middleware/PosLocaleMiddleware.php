<?php

namespace Botble\PosPro\Http\Middleware;

use Botble\Language\Facades\Language;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;

class PosLocaleMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        if (is_plugin_active('language') && Session::has('pos_locale')) {
            $locale = Session::get('pos_locale');

            if (Language::getActiveLanguage()->where('lang_code', $locale)->count() > 0) {
                app()->setLocale($locale);
            }
        }

        return $next($request);
    }
}
