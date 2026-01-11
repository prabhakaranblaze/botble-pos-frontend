@php
    $product = $product->original_product;
@endphp

<form id="quick-shop-form" class="quick-shop-form" data-product-id="{{ $product->id }}">
    <input type="hidden" name="product_id" value="{{ $product->id }}">
    <div class="product-info mb-4">
        <div class="d-flex align-items-center">
            <img src="{{ RvMedia::getImageUrl($product->image) }}" alt="{{ $product->name }}" class="me-3 product-image">
            <div>
                <h5 class="mb-2 fs-4">{{ $product->name }}</h5>
                <p class="text-muted mb-1">SKU: {{ $product->sku }}</p>
                @if($product->barcode)
                <p class="text-muted mb-1">
                    <x-core::icon name="ti ti-barcode" class="me-1" />
                    Barcode: {{ $product->barcode }}
                </p>
                @endif
                @include('plugins/ecommerce::themes.includes.product-price', [
                    'product' => $product,
                    'priceWrapperClassName' => 'mt-2',
                    'priceClassName' => 'fw-bold fs-5'
                ])
            </div>
        </div>
    </div>

    @php
        $productVariations = $product->variations;
        $productVariationsInfo = \Botble\Ecommerce\Models\ProductVariationItem::getVariationsInfo($productVariations->pluck('id')->all());
        $attributes = $product->productAttributeSets->load('attributes');
    @endphp

    @foreach($attributes as $set)
        @php
            $variationInfo = $productVariationsInfo->where('attribute_set_id', $set->id);
            $variationAttributes = $variationInfo->pluck('id')->toArray();
        @endphp

        @if($set->display_layout == 'visual')
            <div class="attribute-swatches-wrapper" data-type="visual" data-slug="{{ $set->slug }}">
                <h4 class="attribute-name mb-2">{{ $set->title }}:</h4>
                <ul class="attribute-swatch-list visual-swatch d-flex flex-wrap gap-2 list-unstyled">
                    @foreach($set->attributes as $attribute)
                        <li
                            class="attribute-swatch-item {{ !in_array($attribute->id, $variationAttributes) ? 'disabled' : '' }}"
                            data-slug="{{ $attribute->slug }}"
                            data-id="{{ $attribute->id }}"
                        >
                            <label>
                                <input
                                    type="radio"
                                    name="attributes[{{ $set->id }}]"
                                    value="{{ $attribute->id }}"
                                    class="variation-select"
                                    data-attribute-id="{{ $set->id }}"
                                    {{ !in_array($attribute->id, $variationAttributes) ? 'disabled' : '' }}
                                >
                                @if($attribute->image)
                                    <span class="attribute-swatch-item-image">
                                        <img src="{{ RvMedia::getImageUrl($attribute->image) }}" alt="{{ $attribute->title }}">
                                    </span>
                                @else
                                    <span class="attribute-swatch-item-color" style="background-color: {{ $attribute->color }}"></span>
                                @endif
                                <span class="attribute-swatch-item-tooltip">{{ $attribute->title }}</span>
                            </label>
                        </li>
                    @endforeach
                </ul>
            </div>
        @elseif($set->display_layout == 'text')
            <div class="attribute-swatches-wrapper" data-type="text" data-slug="{{ $set->slug }}">
                <h4 class="attribute-name mb-2">{{ $set->title }}:</h4>
                <ul class="attribute-swatch-list text-swatch d-flex flex-wrap gap-2 list-unstyled">
                    @foreach($set->attributes as $attribute)
                        <li
                            class="attribute-swatch-item {{ !in_array($attribute->id, $variationAttributes) ? 'disabled' : '' }}"
                            data-slug="{{ $attribute->slug }}"
                            data-id="{{ $attribute->id }}"
                        >
                            <label>
                                <input
                                    type="radio"
                                    name="attributes[{{ $set->id }}]"
                                    value="{{ $attribute->id }}"
                                    class="variation-select"
                                    data-attribute-id="{{ $set->id }}"
                                    {{ !in_array($attribute->id, $variationAttributes) ? 'disabled' : '' }}
                                >
                                <span class="attribute-swatch-text">{{ $attribute->title }}</span>
                            </label>
                        </li>
                    @endforeach
                </ul>
            </div>
        @else
            <div class="attribute-swatches-wrapper" data-type="dropdown" data-slug="{{ $set->slug }}">
                <x-core::form.select
                    :label="$set->title"
                    name="attributes[{{ $set->id }}]"
                    class="variation-select"
                    data-attribute-id="{{ $set->id }}"
                >
                    <option value="">{{ trans('plugins/pos-pro::pos.select_option') }}</option>
                    @foreach($set->attributes as $attribute)
                        <option
                            value="{{ $attribute->id }}"
                            data-id="{{ $attribute->id }}"
                            {{ !in_array($attribute->id, $variationAttributes) ? 'disabled' : '' }}
                        >
                            {{ $attribute->title }}
                        </option>
                    @endforeach
                </x-core::form.select>
            </div>
        @endif
    @endforeach

    <div class="mb-3">
        <label class="form-label">{{ trans('plugins/pos-pro::pos.quantity') }}</label>
        <div class="input-group input-group-flat quantity-controls bg-light rounded" style="width: 150px;">
            <button type="button" class="btn" id="decrease-quantity" onclick="updateQuickShopQuantity('decrease')">
                <x-core::icon name="ti ti-minus" style="width: 12px; height: 12px;" />
            </button>
            <input type="text" class="form-control text-center" name="quantity" id="quick-shop-quantity" value="1" min="1">
            <button type="button" class="btn" id="increase-quantity" onclick="updateQuickShopQuantity('increase')">
                <x-core::icon name="ti ti-plus" style="width: 12px; height: 12px;" />
            </button>
        </div>
    </div>

    <script>
        function updateQuickShopQuantity(action) {
            const quantityInput = document.getElementById('quick-shop-quantity');
            let quantity = parseInt(quantityInput.value);

            if (action === 'increase') {
                quantity += 1;
            } else if (action === 'decrease' && quantity > 1) {
                quantity -= 1;
            }

            quantityInput.value = quantity;
        }
    </script>

    <div class="variation-info d-none">
        <x-core::datagrid>
            <x-core::datagrid.item :title="trans('plugins/pos-pro::pos.price')">
                <div class="variation-price"></div>
            </x-core::datagrid.item>
            <x-core::datagrid.item :title="trans('plugins/pos-pro::pos.stock')">
                <div class="variation-stock"></div>
            </x-core::datagrid.item>
        </x-core::datagrid>
    </div>

     <div class="text-end mt-3">
        <x-core::button type="button" data-bs-dismiss="modal">
            {{ trans('plugins/pos-pro::pos.cancel') }}
        </x-core::button>
        <x-core::button type="submit" color="primary">
            {{ trans('plugins/pos-pro::pos.add_to_cart') }}
        </x-core::button>
    </div>
</form>

<script>
    window.trans = window.trans || {};
    window.trans.in_stock = '{{ trans('plugins/pos-pro::pos.in_stock') }}';
    window.trans.out_of_stock = '{{ trans('plugins/pos-pro::pos.out_of_stock') }}';
</script>
