<?php

namespace Botble\PosPro\Enums;

use Botble\Base\Supports\Enum;
use Illuminate\Support\HtmlString;

/**
 * @method static ReceiptWidthEnum THERMAL_58MM()
 * @method static ReceiptWidthEnum THERMAL_80MM()
 * @method static ReceiptWidthEnum A4()
 */
class ReceiptWidthEnum extends Enum
{
    public const THERMAL_58MM = '58mm';

    public const THERMAL_80MM = '80mm';

    public const A4 = 'A4';

    public static function labels(): array
    {
        return [
            self::THERMAL_58MM => trans('plugins/pos-pro::pos.receipt_settings.width_58mm'),
            self::THERMAL_80MM => trans('plugins/pos-pro::pos.receipt_settings.width_80mm'),
            self::A4 => trans('plugins/pos-pro::pos.receipt_settings.width_a4'),
        ];
    }

    public function label(): string
    {
        return self::labels()[$this->value] ?? $this->value;
    }

    public function toHtml(): HtmlString
    {
        $color = match ($this->value) {
            self::THERMAL_58MM => 'warning',
            self::THERMAL_80MM => 'success',
            self::A4 => 'info',
            default => 'secondary',
        };

        return new HtmlString(sprintf(
            '<span class="badge bg-%s">%s</span>',
            $color,
            $this->label()
        ));
    }

    public static function getWidthInMm(string $value): int
    {
        return match ($value) {
            self::THERMAL_58MM => 58,
            self::THERMAL_80MM => 80,
            self::A4 => 210,
            default => 80,
        };
    }

    public static function getCssWidth(string $value): string
    {
        return match ($value) {
            self::THERMAL_58MM => '58mm',
            self::THERMAL_80MM => '78mm',
            self::A4 => '210mm',
            default => '78mm',
        };
    }

    public static function getFontSize(string $value): int
    {
        return match ($value) {
            self::THERMAL_58MM => 11,
            self::THERMAL_80MM => 13,
            self::A4 => 12,
            default => 13,
        };
    }

    public static function getDescription(string $value): string
    {
        return match ($value) {
            self::THERMAL_58MM => trans('plugins/pos-pro::pos.receipt_settings.width_58mm_desc'),
            self::THERMAL_80MM => trans('plugins/pos-pro::pos.receipt_settings.width_80mm_desc'),
            self::A4 => trans('plugins/pos-pro::pos.receipt_settings.width_a4_desc'),
            default => '',
        };
    }
}
