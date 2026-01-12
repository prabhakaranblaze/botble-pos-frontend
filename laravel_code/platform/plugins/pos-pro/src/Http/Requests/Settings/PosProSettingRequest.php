<?php

namespace Botble\PosPro\Http\Requests\Settings;

use Botble\Base\Rules\OnOffRule;
use Botble\PosPro\Enums\ReceiptWidthEnum;
use Botble\Support\Http\Requests\Request;
use Illuminate\Validation\Rule;

class PosProSettingRequest extends Request
{
    public function rules(): array
    {
        return [
            'pos_pro_enabled' => new OnOffRule(),
            'pos_pro_active_payment_methods' => ['required', 'array', 'min:1'],
            'pos_pro_active_payment_methods.*' => ['required', 'string', 'in:cash,card,other'],
            'pos_pro_default_payment_method' => [
                'required',
                'string',
                'in:cash,card,other',
                function ($attribute, $value, $fail): void {
                    $activeMethods = $this->input('pos_pro_active_payment_methods', []);
                    if (! in_array($value, $activeMethods)) {
                        $fail(trans('validation.in_array', [
                            'attribute' => trans('plugins/pos-pro::pos.settings.default_payment_method'),
                            'other' => trans('plugins/pos-pro::pos.settings.active_payment_methods'),
                        ]));
                    }
                },
            ],
            'pos_pro_auto_apply_discount' => new OnOffRule(),
            'pos_pro_auto_add_shipping' => new OnOffRule(),
            'pos_pro_default_shipping_amount' => ['nullable', 'numeric', 'min:0'],
            'pos_pro_remember_customer_selection' => new OnOffRule(),
            'pos_pro_print_receipt' => new OnOffRule(),
            'pos_pro_require_register' => new OnOffRule(),
            'pos_pro_separate_vendor_orders' => new OnOffRule(),
            'pos_pro_vendor_enabled' => new OnOffRule(),
            // Receipt & Printer Settings
            'pos_pro_receipt_width' => ['nullable', 'string', Rule::in(array_keys(ReceiptWidthEnum::labels()))],
            'pos_pro_auto_print_thermal' => new OnOffRule(),
            'pos_pro_receipt_show_logo' => new OnOffRule(),
            'pos_pro_receipt_show_store_info' => new OnOffRule(),
            'pos_pro_receipt_show_vat' => new OnOffRule(),
            'pos_pro_receipt_show_cashier' => new OnOffRule(),
            'pos_pro_receipt_show_customer' => new OnOffRule(),
            'pos_pro_receipt_footer_text' => ['nullable', 'string', 'max:500'],
        ];
    }
}
