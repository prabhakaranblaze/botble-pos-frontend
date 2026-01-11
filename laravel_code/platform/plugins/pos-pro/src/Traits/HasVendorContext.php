<?php

namespace Botble\PosPro\Traits;

use Botble\Ecommerce\Models\Customer;
use Botble\Marketplace\Models\Store;
use Illuminate\Database\Eloquent\Collection;

trait HasVendorContext
{
    protected function getVendorStore(): Store
    {
        $store = auth('customer')->user()?->store;

        abort_if(! $store, 403, trans('plugins/marketplace::marketplace.store_not_found'));

        return $store;
    }

    protected function getStoreId(): int
    {
        return $this->getVendorStore()->id;
    }

    protected function authorizeProductAccess($product): void
    {
        abort_if(
            $product->store_id !== $this->getStoreId(),
            403,
            trans('plugins/pos-pro::pos.product_not_in_store')
        );
    }

    protected function authorizeOrderAccess($order): void
    {
        abort_if(
            $order->store_id !== $this->getStoreId(),
            403,
            trans('plugins/pos-pro::pos.order_not_in_store')
        );
    }

    protected function getStoreCustomers(): Collection
    {
        $storeId = $this->getStoreId();

        return Customer::query()
            ->whereHas('orders', function ($q) use ($storeId): void {
                $q->where('store_id', $storeId);
            })
            ->oldest('name')
            ->get();
    }

    protected function getCartSessionPrefix(): string
    {
        return 'vendor_' . $this->getStoreId() . '_';
    }
}
