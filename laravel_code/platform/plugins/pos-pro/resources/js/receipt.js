// Initialize Botble object if it doesn't exist
if (typeof Botble === 'undefined') {
    window.Botble = {
        showNotice: function(type, message, messageHeader) {
            if (typeof toastr !== 'undefined') {
                toastr[type](message, messageHeader);
            } else {
                console.log(type + ': ' + message);
            }
        },
        showError: function(message, messageHeader) {
            this.showNotice('error', message, messageHeader || '');
        },
        showSuccess: function(message, messageHeader) {
            this.showNotice('success', message, messageHeader || '');
        }
    };
}

// Check for message and order data in sessionStorage
document.addEventListener('DOMContentLoaded', function() {
    try {
        // Check for checkout message
        const checkoutMessage = sessionStorage.getItem('pos_checkout_message');
        if (checkoutMessage) {
            // Display the message
            if (typeof Botble !== 'undefined' && Botble.showSuccess) {
                Botble.showSuccess(checkoutMessage);
            } else {
                console.log('Success: ' + checkoutMessage);
            }

            // Clear the message from sessionStorage
            sessionStorage.removeItem('pos_checkout_message');
        }

        // Clear other order data from sessionStorage
        sessionStorage.removeItem('pos_order_code');
        sessionStorage.removeItem('pos_order_id');
    } catch (e) {
        console.error('Error retrieving data from sessionStorage', e);
    }
});
