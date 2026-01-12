<?php

namespace Botble\PosPro\Forms\Settings;

use Botble\Base\Forms\FieldOptions\HtmlFieldOption;
use Botble\Base\Forms\FieldOptions\MultiChecklistFieldOption;
use Botble\Base\Forms\FieldOptions\OnOffFieldOption;
use Botble\Base\Forms\FieldOptions\SelectFieldOption;
use Botble\Base\Forms\FieldOptions\TextareaFieldOption;
use Botble\Base\Forms\FieldOptions\TextFieldOption;
use Botble\Base\Forms\Fields\HtmlField;
use Botble\Base\Forms\Fields\MultiCheckListField;
use Botble\Base\Forms\Fields\OnOffCheckboxField;
use Botble\Base\Forms\Fields\SelectField;
use Botble\Base\Forms\Fields\TextareaField;
use Botble\Base\Forms\Fields\TextField;
use Botble\PosPro\Enums\ReceiptWidthEnum;
use Botble\PosPro\Http\Requests\Settings\PosProSettingRequest;
use Botble\Setting\Forms\SettingForm;

class PosProSettingForm extends SettingForm
{
    public function setup(): void
    {
        parent::setup();

        $activePaymentMethods = $this->getSettingValue('pos_pro_active_payment_methods');

        if ($activePaymentMethods) {
            $activePaymentMethods = json_decode($activePaymentMethods, true);
        } else {
            $activePaymentMethods = ['cash', 'card', 'other'];
        }

        $this
            ->setSectionTitle(trans('plugins/pos-pro::pos.settings.title'))
            ->setSectionDescription(trans('plugins/pos-pro::pos.settings.description'))
            ->setValidatorClass(PosProSettingRequest::class)
            ->add(
                'pos_pro_enabled',
                OnOffCheckboxField::class,
                OnOffFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.settings.enable'))
                    ->value($this->getSettingValue('pos_pro_enabled', true))
                    ->attributes([
                        'data-bb-toggle' => 'collapse',
                        'data-bb-target' => '#pos-pro-settings',
                    ])
            )
            ->add('open_wrapper', HtmlField::class, [
                'html' => sprintf(
                    '<div id="pos-pro-settings" style="display: %s">',
                    $this->getSettingValue('pos_pro_enabled', true) ? 'block' : 'none'
                ),
            ])
            ->add(
                'pos_pro_active_payment_methods[]',
                MultiCheckListField::class,
                MultiChecklistFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.settings.active_payment_methods'))
                    ->choices([
                        'cash' => trans('plugins/pos-pro::pos.cash'),
                        'card' => trans('plugins/pos-pro::pos.card'),
                        'other' => trans('plugins/pos-pro::pos.other'),
                    ])
                    ->selected($activePaymentMethods)
                    ->helperText(trans('plugins/pos-pro::pos.settings.active_payment_methods_helper'))
            )
            ->add(
                'pos_pro_default_payment_method',
                SelectField::class,
                SelectFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.settings.default_payment_method'))
                    ->choices([
                        'cash' => trans('plugins/pos-pro::pos.cash'),
                        'card' => trans('plugins/pos-pro::pos.card'),
                        'other' => trans('plugins/pos-pro::pos.other'),
                    ])
                    ->selected($this->getSettingValue('pos_pro_default_payment_method', 'cash'))
                    ->helperText(trans('plugins/pos-pro::pos.settings.default_payment_method_helper'))
            )
            ->add(
                'pos_pro_auto_apply_discount',
                OnOffCheckboxField::class,
                OnOffFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.settings.auto_apply_discount'))
                    ->value($this->getSettingValue('pos_pro_auto_apply_discount', false))
                    ->helperText(trans('plugins/pos-pro::pos.settings.auto_apply_discount_helper'))
            )
            ->add(
                'pos_pro_auto_add_shipping',
                OnOffCheckboxField::class,
                OnOffFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.settings.auto_add_shipping'))
                    ->value($this->getSettingValue('pos_pro_auto_add_shipping', false))
                    ->helperText(trans('plugins/pos-pro::pos.settings.auto_add_shipping_helper'))
            )
            ->add(
                'pos_pro_default_shipping_amount',
                TextField::class,
                TextFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.settings.default_shipping_amount'))
                    ->value($this->getSettingValue('pos_pro_default_shipping_amount', 0))
                    ->helperText(trans('plugins/pos-pro::pos.settings.default_shipping_amount_helper'))
            )
            ->add(
                'pos_pro_remember_customer_selection',
                OnOffCheckboxField::class,
                OnOffFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.settings.remember_customer_selection'))
                    ->value($this->getSettingValue('pos_pro_remember_customer_selection', true))
                    ->helperText(trans('plugins/pos-pro::pos.settings.remember_customer_selection_helper'))
            )
            ->add(
                'pos_pro_print_receipt',
                OnOffCheckboxField::class,
                OnOffFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.settings.print_receipt'))
                    ->value($this->getSettingValue('pos_pro_print_receipt', true))
                    ->helperText(trans('plugins/pos-pro::pos.settings.print_receipt_helper'))
            )
            ->add(
                'pos_pro_require_register',
                OnOffCheckboxField::class,
                OnOffFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.settings.require_register'))
                    ->value($this->getSettingValue('pos_pro_require_register', false))
                    ->helperText(trans('plugins/pos-pro::pos.settings.require_register_helper'))
            )
            ->when(is_plugin_active('marketplace'), function ($form): void {
                $form->add(
                    'pos_pro_separate_vendor_orders',
                    OnOffCheckboxField::class,
                    OnOffFieldOption::make()
                        ->label(trans('plugins/pos-pro::pos.settings.separate_vendor_orders'))
                        ->value($this->getSettingValue('pos_pro_separate_vendor_orders', true))
                        ->helperText(trans('plugins/pos-pro::pos.settings.separate_vendor_orders_helper'))
                )
                ->add(
                    'pos_pro_vendor_enabled',
                    OnOffCheckboxField::class,
                    OnOffFieldOption::make()
                        ->label(trans('plugins/pos-pro::pos.settings.vendor_enabled'))
                        ->value($this->getSettingValue('pos_pro_vendor_enabled', true))
                        ->helperText(trans('plugins/pos-pro::pos.settings.vendor_enabled_helper'))
                );
            })
            // Receipt & Printer Settings Section
            ->add(
                'receipt_section_header',
                HtmlField::class,
                HtmlFieldOption::make()
                    ->content('<hr class="my-4"><h4 class="mb-3"><i class="ti ti-printer me-2"></i>' . trans('plugins/pos-pro::pos.receipt_settings.section_title') . '</h4><p class="text-muted mb-3">' . trans('plugins/pos-pro::pos.receipt_settings.section_description') . '</p>')
            )
            ->add(
                'pos_pro_receipt_width',
                SelectField::class,
                SelectFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.receipt_settings.receipt_width'))
                    ->choices(ReceiptWidthEnum::labels())
                    ->selected($this->getSettingValue('pos_pro_receipt_width', ReceiptWidthEnum::THERMAL_80MM))
                    ->helperText(trans('plugins/pos-pro::pos.receipt_settings.receipt_width_helper'))
            )
            ->add(
                'pos_pro_auto_print_thermal',
                OnOffCheckboxField::class,
                OnOffFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.receipt_settings.auto_print_thermal'))
                    ->value($this->getSettingValue('pos_pro_auto_print_thermal', true))
                    ->helperText(trans('plugins/pos-pro::pos.receipt_settings.auto_print_thermal_helper'))
            )
            ->add(
                'pos_pro_receipt_show_logo',
                OnOffCheckboxField::class,
                OnOffFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.receipt_settings.show_logo'))
                    ->value($this->getSettingValue('pos_pro_receipt_show_logo', true))
                    ->helperText(trans('plugins/pos-pro::pos.receipt_settings.show_logo_helper'))
            )
            ->add(
                'pos_pro_receipt_show_store_info',
                OnOffCheckboxField::class,
                OnOffFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.receipt_settings.show_store_info'))
                    ->value($this->getSettingValue('pos_pro_receipt_show_store_info', true))
                    ->helperText(trans('plugins/pos-pro::pos.receipt_settings.show_store_info_helper'))
            )
            ->add(
                'pos_pro_receipt_show_vat',
                OnOffCheckboxField::class,
                OnOffFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.receipt_settings.show_vat'))
                    ->value($this->getSettingValue('pos_pro_receipt_show_vat', true))
                    ->helperText(trans('plugins/pos-pro::pos.receipt_settings.show_vat_helper'))
            )
            ->add(
                'pos_pro_receipt_show_cashier',
                OnOffCheckboxField::class,
                OnOffFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.receipt_settings.show_cashier'))
                    ->value($this->getSettingValue('pos_pro_receipt_show_cashier', true))
                    ->helperText(trans('plugins/pos-pro::pos.receipt_settings.show_cashier_helper'))
            )
            ->add(
                'pos_pro_receipt_show_customer',
                OnOffCheckboxField::class,
                OnOffFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.receipt_settings.show_customer'))
                    ->value($this->getSettingValue('pos_pro_receipt_show_customer', true))
                    ->helperText(trans('plugins/pos-pro::pos.receipt_settings.show_customer_helper'))
            )
            ->add(
                'pos_pro_receipt_footer_text',
                TextareaField::class,
                TextareaFieldOption::make()
                    ->label(trans('plugins/pos-pro::pos.receipt_settings.footer_text'))
                    ->value($this->getSettingValue('pos_pro_receipt_footer_text', trans('plugins/pos-pro::pos.thank_you_message')))
                    ->helperText(trans('plugins/pos-pro::pos.receipt_settings.footer_text_helper'))
                    ->attributes(['rows' => 3])
            )
            ->add('close_wrapper', HtmlField::class, [
                'html' => '</div>',
            ]);
    }

    protected function getSettingValue(string $key, $default = null)
    {
        return setting($key, $default);
    }
}
