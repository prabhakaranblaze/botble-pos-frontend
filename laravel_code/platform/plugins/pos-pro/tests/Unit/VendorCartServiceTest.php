<?php

namespace Botble\PosPro\Tests\Unit;

use Botble\Base\Enums\BaseStatusEnum;
use Botble\Base\Supports\BaseTestCase;
use Botble\Ecommerce\Models\Product;
use Botble\PosPro\Services\CartService;
use Illuminate\Foundation\Testing\RefreshDatabase;

class VendorCartServiceTest extends BaseTestCase
{
    use RefreshDatabase;

    protected CartService $cartService;

    protected function setUp(): void
    {
        parent::setUp();

        $this->cartService = app(CartService::class);
    }

    public function test_session_key_without_prefix(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => true,
        ]);

        // Add to cart without prefix (admin context)
        $this->cartService->addToCart($product->id, 1);
        $cart = $this->cartService->getCart();

        $this->assertEquals(1, $cart['count']);
    }

    public function test_session_key_with_vendor_prefix(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => true,
        ]);

        $vendorPrefix = 'vendor_123_';

        // Add to cart with vendor prefix
        $this->cartService->addToCart($product->id, 1, [], $vendorPrefix);
        $cart = $this->cartService->getCart($vendorPrefix);

        $this->assertEquals(1, $cart['count']);
    }

    public function test_admin_and_vendor_carts_are_separate(): void
    {
        $product1 = Product::query()->create([
            'name' => 'Product 1',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => true,
        ]);

        $product2 = Product::query()->create([
            'name' => 'Product 2',
            'price' => 200,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => true,
        ]);

        $vendorPrefix = 'vendor_456_';

        // Add product1 to admin cart (no prefix)
        $this->cartService->addToCart($product1->id, 1);

        // Add product2 to vendor cart (with prefix)
        $this->cartService->addToCart($product2->id, 2, [], $vendorPrefix);

        // Verify admin cart
        $adminCart = $this->cartService->getCart();
        $this->assertEquals(1, $adminCart['count']);
        $this->assertEquals(100, $adminCart['subtotal']);

        // Verify vendor cart
        $vendorCart = $this->cartService->getCart($vendorPrefix);
        $this->assertEquals(1, $vendorCart['count']);
        $this->assertEquals(400, $vendorCart['subtotal']);
    }

    public function test_different_vendors_have_separate_carts(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 100,
            'with_storehouse_management' => true,
        ]);

        $vendorAPrefix = 'vendor_1_';
        $vendorBPrefix = 'vendor_2_';

        // Vendor A adds 2 items
        $this->cartService->addToCart($product->id, 2, [], $vendorAPrefix);

        // Vendor B adds 5 items
        $this->cartService->addToCart($product->id, 5, [], $vendorBPrefix);

        // Verify vendor A cart
        $cartA = $this->cartService->getCart($vendorAPrefix);
        $this->assertEquals(200, $cartA['subtotal']);

        // Verify vendor B cart
        $cartB = $this->cartService->getCart($vendorBPrefix);
        $this->assertEquals(500, $cartB['subtotal']);
    }

    public function test_vendor_cart_update_quantity(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => true,
        ]);

        $vendorPrefix = 'vendor_789_';

        $this->cartService->addToCart($product->id, 1, [], $vendorPrefix);
        $result = $this->cartService->updateQuantity($product->id, 5, $vendorPrefix);

        $this->assertEquals(500, $result['cart']['subtotal']);
    }

    public function test_vendor_cart_remove_product(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => true,
        ]);

        $vendorPrefix = 'vendor_101_';

        $this->cartService->addToCart($product->id, 1, [], $vendorPrefix);
        $result = $this->cartService->removeFromCart($product->id, $vendorPrefix);

        $this->assertEquals(0, $result['cart']['count']);
    }

    public function test_vendor_cart_clear(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => true,
        ]);

        $vendorPrefix = 'vendor_102_';

        $this->cartService->addToCart($product->id, 3, [], $vendorPrefix);

        // Clear vendor cart
        $result = $this->cartService->clearCart($vendorPrefix);

        $this->assertEquals(0, $result['cart']['count']);
    }

    public function test_clearing_vendor_cart_does_not_affect_admin_cart(): void
    {
        $product = Product::query()->create([
            'name' => 'Test Product',
            'price' => 100,
            'status' => BaseStatusEnum::PUBLISHED,
            'quantity' => 10,
            'with_storehouse_management' => true,
        ]);

        $vendorPrefix = 'vendor_103_';

        // Add to both carts
        $this->cartService->addToCart($product->id, 1);
        $this->cartService->addToCart($product->id, 2, [], $vendorPrefix);

        // Clear vendor cart
        $this->cartService->clearCart($vendorPrefix);

        // Admin cart should still have item
        $adminCart = $this->cartService->getCart();
        $this->assertEquals(1, $adminCart['count']);

        // Vendor cart should be empty
        $vendorCart = $this->cartService->getCart($vendorPrefix);
        $this->assertEquals(0, $vendorCart['count']);
    }

    public function test_vendor_cart_customer_selection(): void
    {
        $vendorPrefix = 'vendor_104_';

        $result = $this->cartService->updateCustomer(123, $vendorPrefix);

        $this->assertEquals(123, $result['cart']['customer_id']);
    }

    public function test_vendor_cart_payment_method(): void
    {
        $vendorPrefix = 'vendor_105_';

        $result = $this->cartService->updatePaymentMethod('card', $vendorPrefix);

        $this->assertEquals('card', $result['cart']['payment_method']);
    }

    public function test_vendor_cart_shipping_amount(): void
    {
        $vendorPrefix = 'vendor_106_';

        $result = $this->cartService->updateShippingAmount(15.00, $vendorPrefix);

        $this->assertEquals(15.00, $result['cart']['shipping_amount']);
    }
}
