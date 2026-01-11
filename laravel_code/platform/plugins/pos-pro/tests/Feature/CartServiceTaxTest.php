<?php

namespace Botble\PosPro\Tests\Feature;

use Botble\Base\Enums\BaseStatusEnum;
use Botble\Base\Supports\BaseTestCase;
use Botble\Ecommerce\Models\Discount;
use Botble\Ecommerce\Models\Product;
use Botble\Ecommerce\Models\ProductVariation;
use Botble\Ecommerce\Models\Tax;
use Botble\PosPro\Services\CartService;
use Botble\Setting\Facades\Setting;
use Illuminate\Foundation\Testing\RefreshDatabase;

class CartServiceTaxTest extends BaseTestCase
{
    use RefreshDatabase;

    protected CartService $cartService;

    protected function setUp(): void
    {
        parent::setUp();

        $this->cartService = app(CartService::class);

        $this->setSetting('ecommerce_tax_enabled', 1);
        $this->setSetting('ecommerce_display_product_price_including_taxes', 1);
    }

    protected function setSetting(string $key, mixed $value): void
    {
        Setting::load(true);
        Setting::set($key, $value);
        Setting::save();
        Setting::load(true);
    }

    protected function createTax(float $percentage = 10): Tax
    {
        return Tax::query()->create([
            'title' => "Tax {$percentage}%",
            'percentage' => $percentage,
            'priority' => 0,
            'status' => BaseStatusEnum::PUBLISHED,
        ]);
    }

    protected function createProductWithTax(
        float $price,
        bool $priceIncludesTax,
        Tax $tax,
        int $quantity = 100
    ): Product {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => $price,
            'status' => BaseStatusEnum::PUBLISHED,
            'price_includes_tax' => $priceIncludesTax,
            'quantity' => $quantity,
            'with_storehouse_management' => false,
        ]);

        $product->taxes()->attach($tax->id);

        return $product;
    }

    public function test_cart_with_product_price_includes_tax_no_discount(): void
    {
        $tax = $this->createTax(10);
        $product = $this->createProductWithTax(110, true, $tax);

        $result = $this->cartService->addToCart($product->id, 1);

        $cart = $result['cart'];

        $this->assertEquals(110, $cart['subtotal']);

        $expectedTax = 110 - (110 / 1.10);
        $this->assertEqualsWithDelta($expectedTax, $cart['tax'], 0.01);

        $this->assertEquals(110, $cart['total']);
    }

    public function test_cart_with_product_price_excludes_tax_no_discount(): void
    {
        $tax = $this->createTax(10);
        $product = $this->createProductWithTax(100, false, $tax);

        $result = $this->cartService->addToCart($product->id, 1);

        $cart = $result['cart'];

        $this->assertEquals(100, $cart['subtotal']);

        $this->assertEquals(10, $cart['tax']);

        $this->assertEquals(110, $cart['total']);
    }

    public function test_cart_tax_calculation_with_discount_price_includes_tax(): void
    {
        $tax = $this->createTax(10);
        $product = $this->createProductWithTax(110, true, $tax);

        $this->cartService->addToCart($product->id, 1);
        $result = $this->cartService->updateManualDiscount(55, 'Half off', 'fixed');

        $cart = $result['cart'];

        $this->assertEquals(110, $cart['subtotal']);
        $this->assertEquals(55, $cart['manual_discount']);

        $expectedTax = 55 - (55 / 1.10);
        $this->assertEqualsWithDelta($expectedTax, $cart['tax'], 0.01);

        $this->assertEquals(55, $cart['total']);
    }

    public function test_cart_tax_calculation_with_discount_price_excludes_tax(): void
    {
        $tax = $this->createTax(10);
        $product = $this->createProductWithTax(100, false, $tax);

        $this->cartService->addToCart($product->id, 1);
        $result = $this->cartService->updateManualDiscount(55, 'Half off', 'fixed');

        $cart = $result['cart'];

        $this->assertEquals(100, $cart['subtotal']);
        $this->assertEquals(55, $cart['manual_discount']);

        $rawTotal = 110;
        $discountRatio = ($rawTotal - 55) / $rawTotal;
        $expectedTax = 100 * $discountRatio * 0.10;
        $this->assertEqualsWithDelta($expectedTax, $cart['tax'], 0.01);

        $subtotalAfterDiscount = 100 - 55;
        $expectedTotal = $subtotalAfterDiscount + $expectedTax;
        $this->assertEqualsWithDelta($expectedTotal, $cart['total'], 0.01);
    }

    public function test_cart_tax_calculation_with_coupon_price_includes_tax(): void
    {
        $tax = $this->createTax(10);
        $product = $this->createProductWithTax(110, true, $tax);

        Discount::query()->create([
            'code' => 'HALF50',
            'type' => 'coupon',
            'type_option' => 'percentage',
            'value' => 50,
            'start_date' => now()->subDay(),
            'end_date' => now()->addDay(),
        ]);

        $this->cartService->addToCart($product->id, 1);
        $result = $this->cartService->applyCoupon('HALF50');

        $cart = $result['cart'];

        $this->assertEquals(110, $cart['subtotal']);
        $this->assertEquals(55, $cart['coupon_discount']);

        $expectedTax = 55 - (55 / 1.10);
        $this->assertEqualsWithDelta($expectedTax, $cart['tax'], 0.01);

        $this->assertEquals(55, $cart['total']);
    }

    public function test_cart_tax_calculation_with_coupon_price_excludes_tax(): void
    {
        $tax = $this->createTax(10);
        $product = $this->createProductWithTax(100, false, $tax);

        Discount::query()->create([
            'code' => 'HALF50',
            'type' => 'coupon',
            'type_option' => 'percentage',
            'value' => 50,
            'start_date' => now()->subDay(),
            'end_date' => now()->addDay(),
        ]);

        $this->cartService->addToCart($product->id, 1);
        $result = $this->cartService->applyCoupon('HALF50');

        $cart = $result['cart'];

        $this->assertEquals(100, $cart['subtotal']);
        $this->assertEquals(50, $cart['coupon_discount']);

        $expectedTax = 50 * 0.10;
        $this->assertEquals($expectedTax, $cart['tax']);

        $expectedTotal = 50 + $expectedTax;
        $this->assertEquals($expectedTotal, $cart['total']);
    }

    public function test_cart_with_combined_discounts_price_includes_tax(): void
    {
        $tax = $this->createTax(10);
        $product = $this->createProductWithTax(220, true, $tax);

        Discount::query()->create([
            'code' => 'SAVE20',
            'type' => 'coupon',
            'type_option' => 'fixed',
            'value' => 20,
            'start_date' => now()->subDay(),
            'end_date' => now()->addDay(),
        ]);

        $this->cartService->addToCart($product->id, 1);
        $this->cartService->applyCoupon('SAVE20');
        $result = $this->cartService->updateManualDiscount(90, 'Additional discount', 'fixed');

        $cart = $result['cart'];

        $this->assertEquals(220, $cart['subtotal']);
        $this->assertEquals(20, $cart['coupon_discount']);
        $this->assertEquals(90, $cart['manual_discount']);

        $subtotalAfterDiscount = 220 - 20 - 90;
        $this->assertEquals(110, $subtotalAfterDiscount);

        $expectedTax = 110 - (110 / 1.10);
        $this->assertEqualsWithDelta($expectedTax, $cart['tax'], 0.01);

        $this->assertEquals(110, $cart['total']);
    }

    public function test_cart_with_100_percent_discount_price_includes_tax(): void
    {
        $tax = $this->createTax(10);
        $product = $this->createProductWithTax(110, true, $tax);

        $this->cartService->addToCart($product->id, 1);
        $result = $this->cartService->updateManualDiscount(100, 'Free', 'percentage');

        $cart = $result['cart'];

        $this->assertEquals(110, $cart['subtotal']);
        $this->assertEquals(110, $cart['manual_discount']);

        $this->assertEquals(0, $cart['tax']);

        $this->assertEquals(0, $cart['total']);
    }

    public function test_cart_with_multiple_products_mixed_tax_settings(): void
    {
        $tax = $this->createTax(10);

        $productIncludesTax = $this->createProductWithTax(110, true, $tax);
        $productIncludesTax->name = 'Product Includes Tax';
        $productIncludesTax->save();

        $productExcludesTax = Product::query()->create([
            'name' => 'Product Excludes Tax',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'price_includes_tax' => false,
            'quantity' => 100,
            'with_storehouse_management' => false,
        ]);
        $productExcludesTax->taxes()->attach($tax->id);

        $this->cartService->addToCart($productIncludesTax->id, 1);
        $result = $this->cartService->addToCart($productExcludesTax->id, 1);

        $cart = $result['cart'];

        $this->assertEquals(210, $cart['subtotal']);

        $taxFromIncluded = 110 - (110 / 1.10);
        $taxFromExcluded = 100 * 0.10;
        $expectedTotalTax = $taxFromIncluded + $taxFromExcluded;
        $this->assertEqualsWithDelta($expectedTotalTax, $cart['tax'], 0.02);

        $expectedTotal = 210 + $taxFromExcluded;
        $this->assertEqualsWithDelta($expectedTotal, $cart['total'], 0.02);
    }

    public function test_variation_product_inherits_parent_tax_settings(): void
    {
        $tax = $this->createTax(10);

        $parentProduct = $this->createProductWithTax(500, true, $tax);

        $variationProduct = Product::query()->create([
            'name' => 'Variation',
            'price' => 110,
            'status' => BaseStatusEnum::PUBLISHED,
            'is_variation' => true,
            'quantity' => 100,
            'with_storehouse_management' => false,
        ]);

        ProductVariation::query()->create([
            'product_id' => $variationProduct->id,
            'configurable_product_id' => $parentProduct->id,
            'is_default' => true,
        ]);

        $result = $this->cartService->addToCart($variationProduct->id, 1);

        $cart = $result['cart'];

        $this->assertEquals(110, $cart['subtotal']);

        $expectedTax = 110 - (110 / 1.10);
        $this->assertEqualsWithDelta($expectedTax, $cart['tax'], 0.01);

        $this->assertEquals(110, $cart['total']);
    }

    public function test_cart_with_shipping_and_discount_price_includes_tax(): void
    {
        $tax = $this->createTax(10);
        $product = $this->createProductWithTax(110, true, $tax);

        $this->cartService->addToCart($product->id, 1);
        $this->cartService->updateManualDiscount(55, 'Half off', 'fixed');
        $result = $this->cartService->updateShippingAmount(10);

        $cart = $result['cart'];

        $this->assertEquals(110, $cart['subtotal']);
        $this->assertEquals(55, $cart['manual_discount']);
        $this->assertEquals(10, $cart['shipping_amount']);

        $expectedTax = 55 - (55 / 1.10);
        $this->assertEqualsWithDelta($expectedTax, $cart['tax'], 0.01);

        $expectedTotal = 55 + 10;
        $this->assertEquals($expectedTotal, $cart['total']);
    }

    public function test_cart_with_multiple_quantities_price_includes_tax(): void
    {
        $tax = $this->createTax(10);
        $product = $this->createProductWithTax(55, true, $tax);

        $result = $this->cartService->addToCart($product->id, 2);

        $cart = $result['cart'];

        $this->assertEquals(110, $cart['subtotal']);

        $expectedTax = 110 - (110 / 1.10);
        $this->assertEqualsWithDelta($expectedTax, $cart['tax'], 0.01);

        $this->assertEquals(110, $cart['total']);
    }

    public function test_cart_session_prefix_isolates_tax_calculations(): void
    {
        $tax = $this->createTax(10);
        $product = $this->createProductWithTax(110, true, $tax);

        $result1 = $this->cartService->addToCart($product->id, 1, [], 'vendor_1_');
        $result2 = $this->cartService->addToCart($product->id, 2, [], 'vendor_2_');

        $this->assertEquals(110, $result1['cart']['subtotal']);
        $this->assertEquals(220, $result2['cart']['subtotal']);

        $expectedTax1 = 110 - (110 / 1.10);
        $expectedTax2 = 220 - (220 / 1.10);

        $this->assertEqualsWithDelta($expectedTax1, $result1['cart']['tax'], 0.01);
        $this->assertEqualsWithDelta($expectedTax2, $result2['cart']['tax'], 0.01);

        $this->cartService->clearCart('vendor_1_');
        $this->cartService->clearCart('vendor_2_');
    }

    public function test_tax_details_in_cart_response(): void
    {
        $tax = $this->createTax(10);
        $product = $this->createProductWithTax(110, true, $tax);

        $result = $this->cartService->addToCart($product->id, 1);

        $cart = $result['cart'];

        $this->assertArrayHasKey('tax_details', $cart);
        $this->assertCount(1, $cart['tax_details']);

        $taxDetail = $cart['tax_details'][0];
        $this->assertEquals($product->id, $taxDetail['product_id']);
        $this->assertEquals(10, $taxDetail['tax_rate']);

        $expectedTax = 110 - (110 / 1.10);
        $this->assertEqualsWithDelta($expectedTax, $taxDetail['tax_amount'], 0.01);
    }

    protected function tearDown(): void
    {
        $this->cartService->clearCart();

        parent::tearDown();
    }
}
