<div class="payment-method-wrapper mb-3">
    <h5 class="checkout-payment-title">{{ __('Delivery Option') }}</h5>

    <div class="list-group list-group-horizontal delivery-row-box">
        <label class="list-group-item flex-fill d-flex align-items-center mb-0">
            <input type="radio" name="delivery_option" value="shipping" class="me-2" checked>
            <span>{{ __('Ship to Address') }}</span>
        </label>

        <label class="list-group-item flex-fill d-flex align-items-center mb-0">
            <input type="radio" name="delivery_option" value="pickup" class="me-2">
            <span>{{ __('Pickup in Store') }}</span>
        </label>
    </div>
</div>



<script>
$(document).ready(function () {
    let storeId = $('.shipping_method_input').attr('data-id');
    let ship_option = $('input[name="shipping_option['+storeId+']"]').val();

     
    function toggleOption() {
        let val = $('input[name="delivery_option"]:checked').val();
        let $checkoutForm = $('form.checkout-form');
        $('.payment-info-loading').show();
        $('.payment-checkout-btn').prop('disabled', true);
        $('.shipping-info-loading').show();
        $.ajax({
            url: $checkoutForm.data('update-url'),
            method: 'POST',
            data: new FormData($checkoutForm.get(0)),
            processData: false,
            contentType: false,
            success: ({ data }) => {
                // Update checkout button status
                if (data.checkout_button) {
                    $('.payment-checkout-btn, .payment-checkout-btn-step').replaceWith(data.checkout_button)
                }
                if (data.payment_amount) {
                    // Get existing currency symbol from subtotal OR total
                    let currency = $('.total-text').text().replace(/[0-9.,\s]/g, '');

                    // Clean fallback if empty (rare cases)
                    if (!currency.trim()) {
                        currency = $('.sub-total-text').text().replace(/[0-9.,\s]/g, '');
                    }

                    // Update total dynamically with same currency symbol
                    $('.total-text').text(data.payment_amount + currency);
                }
                if (data.ship_amount) {
                    // Get existing currency symbol from subtotal OR total
                    let currency = $('.shipping-price-text').text().replace(/[0-9.,\s]/g, '');

                    if (!currency.trim()) {
                        currency = $('.sub-total-text').text().replace(/[0-9.,\s]/g, '');
                    }
            
                    // Update total dynamically with same currency symbol
                    $('.shipping-price-text').text(data.ship_amount + currency);
                }
                $('.payment-info-loading').hide();
                $('.payment-checkout-btn').prop('disabled', false);
                $('.shipping-info-loading').hide();


            }
        });
        
       
        if (val === 'pickup') {
            // Hide address field
            $('#address_id').closest('.form-group').hide();

            // Hide shipping method section
            $('.shipping-method-wrapper.py-3').hide();

            // Hide shipping fee row in totals
            $('.shipping-price-text').closest('.row').hide();

            $('input[name="shipping_option['+storeId+']"]').val('0');
      

        } else {
            // Show address field
            $('#address_id').closest('.form-group').show();

            // Show shipping method section
            $('.shipping-method-wrapper.py-3').show();

            // Show shipping fee row
            $('.shipping-price-text').closest('.row').show();
            $('input[name="shipping_option['+storeId+']"]').val(ship_option);

        }
    }

    $('input[name="delivery_option"]').on('change', toggleOption);


});
</script>

