<?php

namespace Botble\PosPro\Providers;

use Botble\Base\Facades\Html;
use Botble\Base\Supports\ServiceProvider;
use Botble\Payment\Enums\PaymentMethodEnum;

class HookServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        $this->app->booted(function (): void {
            add_filter(BASE_FILTER_ENUM_ARRAY, function ($values, $class) {
                if ($class == PaymentMethodEnum::class) {
                    $values['POS_PRO_CASH'] = POS_PRO_CASH_PAYMENT_METHOD_NAME;
                    $values['POS_PRO_CARD'] = POS_PRO_CARD_PAYMENT_METHOD_NAME;
                    $values['POS_PRO_OTHER'] = POS_PRO_OTHER_PAYMENT_METHOD_NAME;
                }

                return $values;
            }, 20, 2);

            add_filter(BASE_FILTER_ENUM_LABEL, function ($value, $class) {
                if ($class == PaymentMethodEnum::class) {
                    if ($value == POS_PRO_CASH_PAYMENT_METHOD_NAME) {
                        return trans('plugins/pos-pro::pos.cash');
                    }

                    if ($value == POS_PRO_CARD_PAYMENT_METHOD_NAME) {
                        return trans('plugins/pos-pro::pos.card');
                    }

                    if ($value == POS_PRO_OTHER_PAYMENT_METHOD_NAME) {
                        return trans('plugins/pos-pro::pos.other');
                    }
                }

                return $value;
            }, 20, 2);

            add_filter(BASE_FILTER_ENUM_HTML, function ($value, $class) {
                if ($class == PaymentMethodEnum::class) {
                    if ($value == POS_PRO_CASH_PAYMENT_METHOD_NAME) {
                        return Html::tag(
                            'span',
                            PaymentMethodEnum::getLabel($value),
                            ['class' => 'label-info status-label']
                        )->toHtml();
                    }

                    if ($value == POS_PRO_CARD_PAYMENT_METHOD_NAME) {
                        return Html::tag(
                            'span',
                            PaymentMethodEnum::getLabel($value),
                            ['class' => 'label-primary status-label']
                        )->toHtml();
                    }

                    if ($value == POS_PRO_OTHER_PAYMENT_METHOD_NAME) {
                        return Html::tag(
                            'span',
                            PaymentMethodEnum::getLabel($value),
                            ['class' => 'label-warning status-label']
                        )->toHtml();
                    }
                }

                return $value;
            }, 20, 2);
        });
    }
}
