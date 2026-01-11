<?php

namespace Botble\PosPro\Tests\Feature;

use Botble\Base\Enums\BaseStatusEnum;
use Botble\Base\Supports\BaseTestCase;
use Botble\Ecommerce\Models\Discount;
use Botble\Ecommerce\Models\Product;
use Botble\PosPro\Services\CartService;
use Exception;
use Illuminate\Foundation\Testing\RefreshDatabase;

class CartServiceTest extends BaseTestCase
{
    use RefreshDatabase;

    protected CartService $cartService;

    protected function setUp(): void
    {
        parent::setUp();

        $this->cartService = app(CartService::class);
    }

    public function test_can_add_product_to_cart(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => true,
        ]);

        $result = $this->cartService->addToCart($product->id, 2);

        $this->assertArrayHasKey('cart', $result);
        $this->assertEquals(1, $result['cart']['count']);
        $this->assertEquals(200, $result['cart']['subtotal']);
    }

    public function test_can_update_cart_quantity(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => true,
        ]);

        $this->cartService->addToCart($product->id, 1);
        $result = $this->cartService->updateQuantity($product->id, 5);

        $this->assertEquals(500, $result['cart']['subtotal']);
    }

    public function test_can_remove_product_from_cart(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => true,
        ]);

        $this->cartService->addToCart($product->id, 1);
        $result = $this->cartService->removeFromCart($product->id);

        $this->assertEquals(0, $result['cart']['count']);
    }

    public function test_can_clear_cart(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => true,
        ]);

        $this->cartService->addToCart($product->id, 2);
        $result = $this->cartService->clearCart();

        $this->assertEquals(0, $result['cart']['count']);
        $this->assertEquals(0, $result['cart']['subtotal']);
    }

    public function test_can_apply_fixed_coupon_discount(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => false,
        ]);

        Discount::query()->create([
            'code' => 'FIXED10',
            'type' => 'coupon',
            'type_option' => 'fixed',
            'value' => 10,
            'start_date' => now()->subDay(),
            'end_date' => now()->addDay(),
        ]);

        $this->cartService->addToCart($product->id, 1);
        $result = $this->cartService->applyCoupon('FIXED10');

        $this->assertFalse($result['error']);
        $this->assertEquals(10, $result['cart']['coupon_discount']);
        $this->assertEquals(90, $result['cart']['total']);
    }

    public function test_can_apply_percentage_coupon_discount(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => false,
        ]);

        Discount::query()->create([
            'code' => 'PERCENT20',
            'type' => 'coupon',
            'type_option' => 'percentage',
            'value' => 20,
            'start_date' => now()->subDay(),
            'end_date' => now()->addDay(),
        ]);

        $this->cartService->addToCart($product->id, 1);
        $result = $this->cartService->applyCoupon('PERCENT20');

        $this->assertFalse($result['error']);
        $this->assertEquals(20, $result['cart']['coupon_discount']);
        $this->assertEquals(80, $result['cart']['total']);
    }

    public function test_invalid_coupon_returns_error(): void
    {
        $result = $this->cartService->applyCoupon('INVALID');

        $this->assertTrue($result['error']);
    }

    public function test_can_apply_manual_fixed_discount(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => false,
        ]);

        $this->cartService->addToCart($product->id, 1);
        $result = $this->cartService->updateManualDiscount(25, 'Staff discount', 'fixed');

        $this->assertFalse($result['error']);
        $this->assertEquals(25, $result['cart']['manual_discount']);
        $this->assertEquals(75, $result['cart']['total']);
    }

    public function test_can_apply_manual_percentage_discount(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => false,
        ]);

        $this->cartService->addToCart($product->id, 1);
        $result = $this->cartService->updateManualDiscount(50, 'Half off', 'percentage');

        $this->assertFalse($result['error']);
        $this->assertEquals(50, $result['cart']['manual_discount']);
        $this->assertEquals(50, $result['cart']['total']);
    }

    public function test_manual_discount_cannot_exceed_subtotal(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => false,
        ]);

        $this->cartService->addToCart($product->id, 1);
        $result = $this->cartService->updateManualDiscount(150, 'Too much', 'fixed');

        $this->assertTrue($result['error']);
    }

    public function test_can_update_shipping_amount(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => false,
        ]);

        $this->cartService->addToCart($product->id, 1);
        $result = $this->cartService->updateShippingAmount(15);

        $this->assertFalse($result['error']);
        $this->assertEquals(15, $result['cart']['shipping_amount']);
        $this->assertEquals(115, $result['cart']['total']);
    }

    public function test_negative_shipping_amount_returns_error(): void
    {
        $result = $this->cartService->updateShippingAmount(-10);

        $this->assertTrue($result['error']);
    }

    public function test_cannot_add_out_of_stock_product(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 0,
            'with_storehouse_management' => true,
            'allow_checkout_when_out_of_stock' => false,
        ]);

        $this->expectException(Exception::class);
        $this->cartService->addToCart($product->id, 1);
    }

    public function test_cannot_add_more_than_available_stock(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 5,
            'with_storehouse_management' => true,
        ]);

        $this->expectException(Exception::class);
        $this->cartService->addToCart($product->id, 10);
    }

    public function test_combined_coupon_and_manual_discount(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => false,
        ]);

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
        $result = $this->cartService->updateManualDiscount(30, 'Additional discount', 'fixed');

        $this->assertFalse($result['error']);
        $this->assertEquals(20, $result['cart']['coupon_discount']);
        $this->assertEquals(30, $result['cart']['manual_discount']);
        $this->assertEquals(50, $result['cart']['total']);
    }

    public function test_total_with_multiple_products(): void
    {
        $product1 = Product::query()->create([
            'name' => 'Product 1',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => false,
        ]);

        $product2 = Product::query()->create([
            'name' => 'Product 2',
            'price' => 50,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => false,
        ]);

        $this->cartService->addToCart($product1->id, 2);
        $result = $this->cartService->addToCart($product2->id, 1);

        $this->assertEquals(2, $result['cart']['count']);
        $this->assertEquals(250, $result['cart']['subtotal']);
        $this->assertEquals(250, $result['cart']['total']);
    }

    public function test_100_percent_discount_results_in_zero_total(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => false,
        ]);

        $this->cartService->addToCart($product->id, 1);
        $result = $this->cartService->updateManualDiscount(100, 'Free item', 'percentage');

        $this->assertFalse($result['error']);
        $this->assertEquals(100, $result['cart']['manual_discount']);
        $this->assertEquals(0, $result['cart']['total']);
    }

    public function test_can_remove_coupon(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => false,
        ]);

        Discount::query()->create([
            'code' => 'REMOVE10',
            'type' => 'coupon',
            'type_option' => 'fixed',
            'value' => 10,
            'start_date' => now()->subDay(),
            'end_date' => now()->addDay(),
        ]);

        $this->cartService->addToCart($product->id, 1);
        $this->cartService->applyCoupon('REMOVE10');
        $result = $this->cartService->removeCoupon();

        $this->assertFalse($result['error']);
        $this->assertEquals(0, $result['cart']['coupon_discount']);
        $this->assertEquals(100, $result['cart']['total']);
    }

    public function test_can_remove_manual_discount(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => false,
        ]);

        $this->cartService->addToCart($product->id, 1);
        $this->cartService->updateManualDiscount(25, 'Discount', 'fixed');
        $result = $this->cartService->removeManualDiscount();

        $this->assertFalse($result['error']);
        $this->assertEquals(0, $result['cart']['manual_discount']);
        $this->assertEquals(100, $result['cart']['total']);
    }
}
