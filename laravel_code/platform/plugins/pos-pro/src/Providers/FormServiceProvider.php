<?php

namespace Botble\PosPro\Providers;

use Botble\Base\Facades\AdminHelper;
use Botble\Base\Forms\FieldOptions\CheckboxFieldOption;
use Botble\Base\Forms\FieldOptions\OnOffFieldOption;
use Botble\Base\Forms\Fields\CheckboxField;
use Botble\Base\Forms\Fields\OnOffCheckboxField;
use Botble\Base\Supports\ServiceProvider;
use Botble\Ecommerce\Models\Product;
use Botble\Marketplace\Models\Store;

class FormServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        add_filter(BASE_FILTER_BEFORE_RENDER_FORM, function ($form, $data) {
            if ($data instanceof Product && $data->is_variation == 0) {
                $isAvailableInPos = $data->is_available_in_pos ?? true;

                $form
                    ->add(
                        'is_available_in_pos',
                        CheckboxField::class,
                        CheckboxFieldOption::make()
                            ->label(trans('plugins/pos-pro::pos.is_available_in_pos.label'))
                            ->checked($isAvailableInPos)
                            ->helperText(trans('plugins/pos-pro::pos.is_available_in_pos.helper'))
                    );
            }

            if ($data instanceof Store && setting('pos_pro_vendor_enabled', true) && AdminHelper::isInAdmin(true)) {
                $posEnabled = $data->pos_enabled ?? true;

                $form
                    ->add(
                        'pos_enabled',
                        OnOffCheckboxField::class,
                        OnOffFieldOption::make()
                            ->label(trans('plugins/pos-pro::pos.store_pos_enabled'))
                            ->value($posEnabled)
                            ->helperText(trans('plugins/pos-pro::pos.store_pos_enabled_helper'))
                            ->colspan(3)
                    );
            }

            return $form;
        }, 120, 2);

        add_action([BASE_ACTION_AFTER_CREATE_CONTENT, BASE_ACTION_AFTER_UPDATE_CONTENT], function ($screen, $request, $data): void {
            if ($data instanceof Product) {
                if ($data->is_variation == 1) {
                    return;
                }

                $data->is_available_in_pos = (bool) $request->input('is_available_in_pos');
                $data->save();
            }

            if ($data instanceof Store && setting('pos_pro_vendor_enabled', true) && AdminHelper::isInAdmin(true)) {
                $data->pos_enabled = $request->has('pos_enabled') ? (bool) $request->input('pos_enabled') : true;
                $data->saveQuietly();
            }
        }, 120, 3);
    }
}
