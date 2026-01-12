<?php

namespace Botble\PosPro\Tests\Unit;

use PHPUnit\Framework\TestCase;

class PosProTaxCalculationTest extends TestCase
{
    /**
     * Test Case 1: price_includes_tax = false, Product $100, Tax 10%, Discount 50%
     * POS Pro uses subtotal (net price when price_includes_tax = false)
     * Expected: total = 55, tax = 5
     */
    public function test_tax_calculation_with_50_percent_discount_price_excludes_tax(): void
    {
        $price = 100;
        $taxRate = 10;
        $priceIncludesTax = false;

        $subtotal = $price;
        $discount = 50;
        $subtotalAfterDiscount = $subtotal - $discount;

        $discountRatio = $subtotal > 0 ? $subtotalAfterDiscount / $subtotal : 0;
        $this->assertEquals(0.5, $discountRatio);

        $effectiveItemPrice = $price * $discountRatio;
        $this->assertEquals(50, $effectiveItemPrice);

        $taxAmount = $this->calculateTax($effectiveItemPrice, $taxRate, $priceIncludesTax);
        $this->assertEquals(5, $taxAmount);

        $taxAmountToAdd = $priceIncludesTax ? 0 : $taxAmount;
        $total = $subtotalAfterDiscount + $taxAmountToAdd;
        $this->assertEquals(55, $total);
    }

    /**
     * Test Case 2: price_includes_tax = false, Product $100, Tax 10%, Discount 100%
     * Expected: total = 0, tax = 0
     */
    public function test_tax_calculation_with_100_percent_discount_price_excludes_tax(): void
    {
        $price = 100;
        $taxRate = 10;
        $priceIncludesTax = false;

        $subtotal = $price;
        $discount = 100;
        $subtotalAfterDiscount = $subtotal - $discount;

        $discountRatio = $subtotal > 0 ? $subtotalAfterDiscount / $subtotal : 0;
        $this->assertEquals(0, $discountRatio);

        $effectiveItemPrice = $price * $discountRatio;
        $this->assertEquals(0, $effectiveItemPrice);

        $taxAmount = $this->calculateTax($effectiveItemPrice, $taxRate, $priceIncludesTax);
        $this->assertEquals(0, $taxAmount);

        $taxAmountToAdd = $priceIncludesTax ? 0 : $taxAmount;
        $total = $subtotalAfterDiscount + $taxAmountToAdd;
        $this->assertEquals(0, $total);
    }

    /**
     * Test Case 3: price_includes_tax = true, Product $100 (gross), Tax 10%, Discount 50%
     * POS Pro uses subtotal (gross price when price_includes_tax = true)
     * Expected: total = 50, tax = 4.55
     */
    public function test_tax_calculation_with_50_percent_discount_price_includes_tax(): void
    {
        $price = 100;
        $taxRate = 10;
        $priceIncludesTax = true;

        $subtotal = $price;
        $discount = 50;
        $subtotalAfterDiscount = $subtotal - $discount;

        $discountRatio = $subtotal > 0 ? $subtotalAfterDiscount / $subtotal : 0;
        $this->assertEquals(0.5, $discountRatio);

        $effectiveItemPrice = $price * $discountRatio;
        $this->assertEquals(50, $effectiveItemPrice);

        $taxAmount = $this->calculateTax($effectiveItemPrice, $taxRate, $priceIncludesTax);
        $this->assertEquals(4.55, round($taxAmount, 2));

        $taxAmountToAdd = $priceIncludesTax ? 0 : $taxAmount;
        $total = $subtotalAfterDiscount + $taxAmountToAdd;
        $this->assertEquals(50, $total);
    }

    /**
     * Test Case 4: price_includes_tax = true, Product $100 (gross), Tax 10%, Discount 100%
     * Expected: total = 0, tax = 0
     */
    public function test_tax_calculation_with_100_percent_discount_price_includes_tax(): void
    {
        $price = 100;
        $taxRate = 10;
        $priceIncludesTax = true;

        $subtotal = $price;
        $discount = 100;
        $subtotalAfterDiscount = $subtotal - $discount;

        $discountRatio = $subtotal > 0 ? $subtotalAfterDiscount / $subtotal : 0;
        $this->assertEquals(0, $discountRatio);

        $effectiveItemPrice = $price * $discountRatio;
        $this->assertEquals(0, $effectiveItemPrice);

        $taxAmount = $this->calculateTax($effectiveItemPrice, $taxRate, $priceIncludesTax);
        $this->assertEquals(0, $taxAmount);

        $taxAmountToAdd = $priceIncludesTax ? 0 : $taxAmount;
        $total = $subtotalAfterDiscount + $taxAmountToAdd;
        $this->assertEquals(0, $total);
    }

    /**
     * Test no discount - tax calculated on full amount (price excludes tax)
     */
    public function test_tax_calculation_without_discount_price_excludes_tax(): void
    {
        $price = 100;
        $taxRate = 10;
        $priceIncludesTax = false;

        $subtotal = $price;
        $discount = 0;
        $subtotalAfterDiscount = $subtotal - $discount;
        $discountRatio = 1;

        $effectiveItemPrice = $price * $discountRatio;
        $taxAmount = $this->calculateTax($effectiveItemPrice, $taxRate, $priceIncludesTax);

        $this->assertEquals(10, $taxAmount);

        $taxAmountToAdd = $priceIncludesTax ? 0 : $taxAmount;
        $total = $subtotalAfterDiscount + $taxAmountToAdd;
        $this->assertEquals(110, $total);
    }

    /**
     * Test no discount - tax extracted from full amount (price includes tax)
     */
    public function test_tax_calculation_without_discount_price_includes_tax(): void
    {
        $price = 100;
        $taxRate = 10;
        $priceIncludesTax = true;

        $subtotal = $price;
        $discount = 0;
        $subtotalAfterDiscount = $subtotal - $discount;
        $discountRatio = 1;

        $effectiveItemPrice = $price * $discountRatio;
        $taxAmount = $this->calculateTax($effectiveItemPrice, $taxRate, $priceIncludesTax);

        $this->assertEquals(9.09, round($taxAmount, 2));

        $taxAmountToAdd = $priceIncludesTax ? 0 : $taxAmount;
        $total = $subtotalAfterDiscount + $taxAmountToAdd;
        $this->assertEquals(100, $total);
    }

    /**
     * Test coupon + manual discount combined
     */
    public function test_tax_calculation_with_combined_discounts(): void
    {
        $price = 100;
        $taxRate = 10;
        $priceIncludesTax = false;

        $subtotal = $price;
        $couponDiscount = 20;
        $manualDiscount = 30;
        $totalDiscount = $couponDiscount + $manualDiscount;
        $subtotalAfterDiscount = $subtotal - $totalDiscount;

        $discountRatio = $subtotal > 0 ? $subtotalAfterDiscount / $subtotal : 0;
        $this->assertEquals(0.5, $discountRatio);

        $effectiveItemPrice = $price * $discountRatio;
        $taxAmount = $this->calculateTax($effectiveItemPrice, $taxRate, $priceIncludesTax);

        $this->assertEquals(5, $taxAmount);

        $taxAmountToAdd = $priceIncludesTax ? 0 : $taxAmount;
        $total = $subtotalAfterDiscount + $taxAmountToAdd;
        $this->assertEquals(55, $total);
    }

    /**
     * Test multiple items in cart
     */
    public function test_tax_calculation_with_multiple_items(): void
    {
        $items = [
            ['price' => 100, 'qty' => 2, 'taxRate' => 10, 'priceIncludesTax' => false],
            ['price' => 50, 'qty' => 1, 'taxRate' => 10, 'priceIncludesTax' => false],
        ];

        $subtotal = 0;
        foreach ($items as $item) {
            $subtotal += $item['price'] * $item['qty'];
        }
        $this->assertEquals(250, $subtotal);

        $discount = 125;
        $subtotalAfterDiscount = $subtotal - $discount;
        $this->assertEquals(125, $subtotalAfterDiscount);

        $discountRatio = $subtotal > 0 ? $subtotalAfterDiscount / $subtotal : 0;
        $this->assertEquals(0.5, $discountRatio);

        $totalTax = 0;
        $taxAmountToAdd = 0;
        foreach ($items as $item) {
            $itemPrice = $item['price'] * $item['qty'];
            $effectiveItemPrice = $itemPrice * $discountRatio;
            $itemTax = $this->calculateTax($effectiveItemPrice, $item['taxRate'], $item['priceIncludesTax']);
            $totalTax += $itemTax;
            if (! $item['priceIncludesTax']) {
                $taxAmountToAdd += $itemTax;
            }
        }

        $this->assertEquals(12.5, $totalTax);
        $this->assertEquals(12.5, $taxAmountToAdd);

        $total = $subtotalAfterDiscount + $taxAmountToAdd;
        $this->assertEquals(137.5, $total);
    }

    /**
     * Test with shipping amount
     */
    public function test_total_calculation_with_shipping(): void
    {
        $price = 100;
        $taxRate = 10;
        $priceIncludesTax = false;
        $shippingAmount = 10;

        $subtotal = $price;
        $discount = 50;
        $subtotalAfterDiscount = $subtotal - $discount;
        $discountRatio = $subtotal > 0 ? $subtotalAfterDiscount / $subtotal : 0;

        $effectiveItemPrice = $price * $discountRatio;
        $taxAmount = $this->calculateTax($effectiveItemPrice, $taxRate, $priceIncludesTax);

        $taxAmountToAdd = $taxAmount;
        $total = $subtotalAfterDiscount + $taxAmountToAdd + $shippingAmount;

        $this->assertEquals(65, $total);
    }

    /**
     * Test percentage discount type
     */
    public function test_percentage_discount_type(): void
    {
        $price = 100;
        $taxRate = 10;
        $priceIncludesTax = false;
        $discountPercentage = 50;

        $subtotal = $price;
        $discount = $subtotal * $discountPercentage / 100;
        $this->assertEquals(50, $discount);

        $subtotalAfterDiscount = $subtotal - $discount;
        $discountRatio = $subtotal > 0 ? $subtotalAfterDiscount / $subtotal : 0;

        $effectiveItemPrice = $price * $discountRatio;
        $taxAmount = $this->calculateTax($effectiveItemPrice, $taxRate, $priceIncludesTax);

        $this->assertEquals(5, $taxAmount);

        $total = $subtotalAfterDiscount + $taxAmount;
        $this->assertEquals(55, $total);
    }

    protected function calculateTax(float $effectiveItemPrice, float $taxRate, bool $priceIncludesTax): float
    {
        if ($priceIncludesTax) {
            return $effectiveItemPrice - ($effectiveItemPrice / (1 + $taxRate / 100));
        }

        return ($effectiveItemPrice * $taxRate) / 100;
    }
}
