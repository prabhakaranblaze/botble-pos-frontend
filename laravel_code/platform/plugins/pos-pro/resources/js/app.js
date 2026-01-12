// Translation function
function trans(key) {
    return window.trans && window.trans[key] ? window.trans[key] : key;
}

// Get application currency
function get_application_currency() {
    return {
        symbol: window.currency || '$'
    };
}

$(document).ready(function() {
    // Initialize tooltips
    const initTooltips = function() {
        $('[data-bs-toggle="tooltip"]').tooltip({
            placement: 'top',
            trigger: 'hover',
            boundary: 'window'
        });
    };

    initTooltips();

    // Initialize barcode scanner if available
    if (typeof window.BarcodeScanner !== 'undefined') {
        // Initialize barcode scanner with options but don't check camera permissions yet
        window.BarcodeScanner.init({
            containerId: 'barcode-scanner-container',
            checkCameraOnInit: false, // Don't check camera on init
            onDetected: function(barcode) {
                // Show notification
                Botble.showSuccess(trans('plugins/pos-pro::pos.barcode_detected').replace(':barcode', barcode));

                // Try to automatically add product to cart if barcode is unique
                const $container = $('#pos-container');
                const scanBarcodeUrl = $container.data('scan-barcode-url');

                if (scanBarcodeUrl) {
                    $httpClient.make()
                        .post(scanBarcodeUrl, { barcode: barcode })
                        .then((data) => {
                            if (data.error) {
                                // If barcode scan failed, fall back to regular search
                                $('#search-product').val(barcode);
                                $('#search-product').trigger('keyup');
                                Botble.showError(data.message || 'Product not found');
                            } else if (data.data.auto_added) {
                                // Product was automatically added to cart
                                window.updateCartDisplay(data.data.cart);
                                Botble.showSuccess(data.data.message || 'Product added to cart');
                            } else if (data.data.has_variations) {
                                // Product has variations, show in search results for manual selection
                                $('#search-product').val(barcode);
                                $('#search-product').trigger('keyup');
                                Botble.showInfo(data.data.message || 'Product found - please select variation');
                            }
                        })
                        .catch((error) => {
                            // If API call fails, fall back to regular search
                            $('#search-product').val(barcode);
                            $('#search-product').trigger('keyup');
                            console.error('Barcode scan API error:', error);
                        });
                } else {
                    // Fallback to original behavior if no scan URL configured
                    $('#search-product').val(barcode);
                    $('#search-product').trigger('keyup');
                }

                // Hide scanner after successful scan
                $('#barcode-scanner-container').slideUp(300);
                window.BarcodeScanner.stopScan();
            }
        });

        // Toggle barcode scanner on button click
        $('#toggle-barcode-scanner').on('click', async function() {
            const $scannerContainer = $('#barcode-scanner-container');

            if ($scannerContainer.is(':visible')) {
                // Hide scanner
                $scannerContainer.slideUp(300);
                if (window.BarcodeScanner) {
                    window.BarcodeScanner.stopScan().catch(error => {
                        console.error('Error stopping barcode scanner:', error);
                    });
                }
            } else {
                // Show loading state
                const $button = $(this);
                const originalHtml = $button.html();
                $button.prop('disabled', true).html('<i class="spinner-border spinner-border-sm"></i>');

                if (!window.BarcodeScanner) {
                    console.error('Barcode scanner not initialized');
                    Botble.showError(trans('plugins/pos-pro::pos.scanner_not_available'));
                    $button.prop('disabled', false).html(originalHtml);
                    return;
                }

                try {
                    // Check camera permission when the button is clicked
                    const hasPermission = await window.BarcodeScanner.checkCameraPermission();

                    // Reset button state
                    $button.prop('disabled', false).html(originalHtml);

                    // Show scanner container
                    $scannerContainer.slideDown(300);

                    // Start the scanner if permission is granted
                    if (hasPermission) {
                        window.BarcodeScanner.startScan().catch(error => {
                            console.error('Error starting barcode scanner:', error);

                            if (error.message === 'Camera permission denied') {
                                Botble.showError(trans('plugins/pos-pro::pos.camera_permission_denied'));
                            } else {
                                Botble.showError(trans('plugins/pos-pro::pos.no_camera_access'));
                            }
                        });
                    }
                } catch (error) {
                    // Reset button state
                    $button.prop('disabled', false).html(originalHtml);

                    console.error('Error checking camera permission:', error);
                    Botble.showError(trans('plugins/pos-pro::pos.no_camera_access'));

                    // Still show the scanner container as it will display the hardware scanner UI
                    $scannerContainer.slideDown(300);
                }
            }
        });
    }

    // Fullscreen mode functionality
    const $fullscreenToggle = $('#fullscreen-toggle');
    const $fullscreenToggleMobile = $('#fullscreen-toggle-mobile');
    const $fullscreenIcon = $('#fullscreen-icon');
    const $fullscreenText = $('#fullscreen-text');
    const $fullscreenTextMobile = $('#fullscreen-text-mobile');
    const $posContainer = $('.pos-container');
    const $exitFullscreenFloating = $('#exit-fullscreen-floating');
    const $mobileMenuOffcanvas = $('#mobile-menu-offcanvas');

    // Check if browser supports fullscreen API
    const fullscreenEnabled = document.fullscreenEnabled ||
                              document.webkitFullscreenEnabled ||
                              document.mozFullScreenEnabled ||
                              document.msFullscreenEnabled;

    // Function to enter browser fullscreen
    const enterFullscreen = function(element) {
        if (element.requestFullscreen) {
            element.requestFullscreen();
        } else if (element.webkitRequestFullscreen) {
            element.webkitRequestFullscreen();
        } else if (element.mozRequestFullScreen) {
            element.mozRequestFullScreen();
        } else if (element.msRequestFullscreen) {
            element.msRequestFullscreen();
        }
    };

    // Function to exit browser fullscreen
    const exitFullscreen = function() {
        if (document.exitFullscreen) {
            document.exitFullscreen();
        } else if (document.webkitExitFullscreen) {
            document.webkitExitFullscreen();
        } else if (document.mozCancelFullScreen) {
            document.mozCancelFullScreen();
        } else if (document.msExitFullscreen) {
            document.msExitFullscreen();
        }
    };

    // Function to check if browser is in fullscreen mode
    const isInFullscreen = function() {
        return !!(document.fullscreenElement ||
                 document.webkitFullscreenElement ||
                 document.mozFullScreenElement ||
                 document.msFullscreenElement);
    };

    // Get translation texts from data attributes
    const fullscreenText = $fullscreenToggle.data('fullscreen-text');
    const exitFullscreenText = $fullscreenToggle.data('exit-fullscreen-text');

    // Function to update UI based on fullscreen state
    const updateFullscreenUI = function(isFullscreen) {
        if (isFullscreen) {
            // Update UI for fullscreen mode
            $posContainer.addClass('fullscreen-mode');
            $fullscreenIcon.removeClass('ti-maximize').addClass('ti-minimize');
            $fullscreenText.text(exitFullscreenText);
            $fullscreenTextMobile.text(exitFullscreenText);
            $exitFullscreenFloating.fadeIn(300).css('display', 'inline-flex');

            // Close mobile menu if open
            const offcanvasInstance = bootstrap.Offcanvas.getInstance($mobileMenuOffcanvas[0]);
            if (offcanvasInstance) {
                offcanvasInstance.hide();
            }
        } else {
            // Update UI for normal mode
            $posContainer.removeClass('fullscreen-mode');
            $fullscreenIcon.removeClass('ti-minimize').addClass('ti-maximize');
            $fullscreenText.text(fullscreenText);
            $fullscreenTextMobile.text(fullscreenText);
            $exitFullscreenFloating.fadeOut(200);
        }
    };

    // Handle fullscreen toggle button click
    $fullscreenToggle.on('click', function() {
        if (!fullscreenEnabled) {
            // Fallback to CSS-only fullscreen if browser API not supported
            const isFullscreen = $posContainer.hasClass('fullscreen-mode');
            updateFullscreenUI(!isFullscreen);
            return;
        }

        if (isInFullscreen()) {
            exitFullscreen();
        } else {
            enterFullscreen(document.documentElement); // Make the whole page fullscreen
        }
    });

    // Handle mobile fullscreen toggle button click
    $fullscreenToggleMobile.on('click', function() {
        // Close the mobile menu
        const offcanvasInstance = bootstrap.Offcanvas.getInstance($mobileMenuOffcanvas[0]);
        if (offcanvasInstance) {
            offcanvasInstance.hide();
        }

        // Use a small timeout to ensure the menu is closed before toggling fullscreen
        setTimeout(() => {
            if (!fullscreenEnabled) {
                // Fallback to CSS-only fullscreen if browser API not supported
                const isFullscreen = $posContainer.hasClass('fullscreen-mode');
                updateFullscreenUI(!isFullscreen);
                return;
            }

            if (isInFullscreen()) {
                exitFullscreen();
            } else {
                enterFullscreen(document.documentElement); // Make the whole page fullscreen
            }
        }, 300);
    });

    // Handle floating exit fullscreen button click
    $exitFullscreenFloating.on('click', function() {
        if (isInFullscreen()) {
            exitFullscreen();
        } else {
            updateFullscreenUI(false);
        }
    });

    // Listen for fullscreen change events
    document.addEventListener('fullscreenchange', function() {
        updateFullscreenUI(isInFullscreen());
    });
    document.addEventListener('webkitfullscreenchange', function() {
        updateFullscreenUI(isInFullscreen());
    });
    document.addEventListener('mozfullscreenchange', function() {
        updateFullscreenUI(isInFullscreen());
    });
    document.addEventListener('MSFullscreenChange', function() {
        updateFullscreenUI(isInFullscreen());
    });

    // Add keyboard shortcut (F11) for toggling fullscreen mode
    $(document).on('keydown', function(e) {
        if (e.key === 'F11' || e.keyCode === 122) {
            e.preventDefault(); // Prevent browser's default fullscreen
            $fullscreenToggle.trigger('click');
        }
    });

    const $container = $('#pos-container')
    const urls = {
        cartAdd: $container.data('cart-add-url'),
        cartUpdate: $container.data('cart-update-url'),
        cartRemove: $container.data('cart-remove-url'),
        cartClear: $container.data('cart-clear-url'),
        cartApplyCoupon: $container.data('cart-apply-coupon-url'),
        cartRemoveCoupon: $container.data('cart-remove-coupon-url'),
        cartUpdateShipping: $container.data('cart-update-shipping-url'),
        cartUpdateManualDiscount: $container.data('cart-update-manual-discount-url'),
        cartRemoveManualDiscount: $container.data('cart-remove-manual-discount-url'),
        products: $container.data('products-url'),
        quickShop: $container.data('quick-shop-url'),
        checkout: $container.data('checkout-url'),
        receipt: $container.data('receipt-url'),
        orderSlots: $container.data('order-slots-url'),
        orderSlotsCreate: $container.data('order-slots-create-url'),
        orderSlotsSwitch: $container.data('order-slots-switch-url'),
        orderSlotsClose: $container.data('order-slots-close-url'),
    }

    // Initialize BroadcastChannel for customer display
    const posChannel = new BroadcastChannel('pos_channel');

    // Update cart display function - make it globally accessible
    window.updateCartDisplay = function(cart) {
        if (!cart) {
            console.error('Cart data is undefined or null')
            return
        }

        // Update cart items
        $('#cart-items').html(cart.html || '')

        // Update clear cart button state
        const $clearCartBtn = $('#clear-cart')
        if ($clearCartBtn.length) {
            if (cart.count > 0) {
                $clearCartBtn.prop('disabled', false)
            } else {
                $clearCartBtn.prop('disabled', true)
            }
        }

        // Send cart data to customer display via BroadcastChannel
        sendCartToCustomerDisplay(cart);

        // Reinitialize tooltips after cart update
        $('[data-bs-toggle="tooltip"]').tooltip({
            placement: 'top',
            trigger: 'hover',
            boundary: 'window'
        })

        // Restore customer selection from cart data
        if (cart.customer_id && cart.customer) {
            $('#customer-id').val(cart.customer_id);

            // Show the selected customer info
            $('#selected-customer-name').text(cart.customer.name);
            $('#selected-customer-contact').html(`<span>${cart.customer.phone || ''}</span>${cart.customer.email ? ` • <span>${cart.customer.email}</span>` : ''}`);
            $('#selected-customer-info').removeClass('d-none');

            // Also update the customer search field to show the selected customer
            $('#customer-search').val(cart.customer.name);
        } else {
            // No customer in cart data, hide customer info and reset fields
            $('#customer-id').val('');
            $('#selected-customer-info').addClass('d-none');
            $('#customer-search').val('');
        }

        // Restore payment method selection from cart data
        if (cart.payment_method) {
            $(`input[name="payment_method"][value="${cart.payment_method}"]`).prop('checked', true);
        } else {
            // Default to cash if no payment method is set
            $(`input[name="payment_method"][value="cash"]`).prop('checked', true);
        }

        // Check if cart has items and enable/disable checkout button accordingly
        const cartCount = cart.count || 0
        if (cartCount) {
            $('#checkout-button').prop('disabled', false).removeClass('disabled')
        } else {
            $('#checkout-button').prop('disabled', true).addClass('disabled')
        }

        // Update window.initialCart with the new cart data
        window.initialCart = cart
    }

    // Initialize cart if we have initial data
    if (window.initialCart) {
        window.updateCartDisplay(window.initialCart)
    }

    // Check initial search input value to set the correct icon
    const $searchInput = $('#search-product');
    const $searchIconAddon = $('#search-icon-addon');
    const $searchIcon = $('#search-icon');

    if ($searchInput.val().length > 0) {
        $searchIcon.html('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M18 6l-12 12" /><path d="M6 6l12 12" /></svg>');
        $searchIconAddon.css('cursor', 'pointer');
    }

    // Handle customer creation
    $(document).on('click', '#confirm-add-customer-button', function(e) {
        e.preventDefault()
        const $button = $(this)
        const $modal = $('#add-customer-modal')

        // Get form data
        const name = $('#customer-name').val()
        const email = $('#customer-email').val()
        const phone = $('#customer-phone').val()
        const address = $('#customer-address').val()

        // Validate form
        let hasError = false
        $('.add-customer-form .is-invalid').removeClass('is-invalid')

        if (!name) {
            $('#customer-name').addClass('is-invalid')
            hasError = true
        }

        // Email is optional

        if (!phone) {
            $('#customer-phone').addClass('is-invalid')
            hasError = true
        }

        if (hasError) {
            return
        }

        // Submit form
        const createCustomerUrl = $container.data('create-customer-url')
        $httpClient.make()
            .withButtonLoading($button[0])
            .post(createCustomerUrl, {
                name,
                email,
                phone,
                address
            })
            .then((response) => {
                const { data } = response
                if (data.error) {
                    Botble.showError(data.message)
                    return
                }

                // Select the new customer
                const newCustomerId = data.data.customer.id
                const newCustomerName = data.data.customer.name
                const newCustomerPhone = data.data.customer.phone
                const newCustomerEmail = data.data.customer.email || ''

                // Set the customer ID
                $('#customer-id').val(newCustomerId)

                // Update the display
                $('#selected-customer-name').text(newCustomerName)
                $('#selected-customer-contact').html(`<span>${newCustomerPhone}</span>${newCustomerEmail ? ` • <span>${newCustomerEmail}</span>` : ''}`)

                // Show the customer info box
                $('#selected-customer-info').removeClass('d-none')

                // Reset form
                $('#customer-name').val('')
                $('#customer-email').val('')
                $('#customer-phone').val('')
                $('#customer-address').val('')

                // Close modal
                bootstrap.Modal.getInstance($modal[0]).hide()

                // Show success message
                Botble.showSuccess(data.message)
            })
            .catch((error) => {
                Botble.handleError(error)
            })
    })

    // Product search with debounce
    let searchTimeout
    $('#search-product').on('keyup', function() {
        const $searchInput = $(this);
        const $searchIconAddon = $('#search-icon-addon');
        const $searchIcon = $('#search-icon');
        const searchValue = $searchInput.val();

        // Toggle between search and clear icons based on input value
        if (searchValue.length > 0) {
            // Change to clear icon
            if ($searchIcon.find('svg').length === 0 || $searchIcon.data('icon') !== 'x') {
                $searchIcon.html('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M18 6l-12 12" /><path d="M6 6l12 12" /></svg>');
                $searchIcon.data('icon', 'x');
                $searchIconAddon.css('cursor', 'pointer');
            }
        } else {
            // Change back to search icon
            if ($searchIcon.data('icon') === 'x') {
                $searchIcon.html('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M10 10m-7 0a7 7 0 1 0 14 0a7 7 0 1 0 -14 0" /><path d="M21 21l-6 -6" /></svg>');
                $searchIcon.data('icon', 'search');
                $searchIconAddon.css('cursor', 'default');
            }
        }

        clearTimeout(searchTimeout)
        searchTimeout = setTimeout(() => {
            // Reset pagination variables when searching
            currentPage = 1
            hasMorePages = true
            loadProducts(searchValue, 1, false)
        }, 500)
    })

    // Clear search when clicking the clear icon
    $(document).on('click', '#search-icon-addon', function() {
        const $searchIcon = $('#search-icon');
        const $searchInput = $('#search-product');

        // Only clear if it's currently showing the X (clear) icon
        if ($searchIcon.data('icon') === 'x') {
            $searchInput.val('').focus();
            $searchIcon.html('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M10 10m-7 0a7 7 0 1 0 14 0a7 7 0 1 0 -14 0" /><path d="M21 21l-6 -6" /></svg>');
            $searchIcon.data('icon', 'search');
            $(this).css('cursor', 'default');

            // Reset pagination variables
            currentPage = 1
            hasMorePages = true
            loadProducts('', 1, false)
        }
    })

    // Legacy clear search button click (keeping for backward compatibility)
    $(document).on('click', '#clear-search', function() {
        $('#search-product').val('').focus()
        // Reset pagination variables
        currentPage = 1
        hasMorePages = true
        loadProducts('', 1, false)
    })

    // Customer search functionality
    let customerSearchTimeout
    $(document).on('keyup focus', '#customer-search', function() {
        const $input = $(this)
        const $results = $('#customer-search-results')
        const query = $input.val().trim()

        clearTimeout(customerSearchTimeout)

        // Show dropdown immediately on focus
        $results.show()

        customerSearchTimeout = setTimeout(() => {
            if (query.length === 0) {
                // If empty, show all customers
                loadCustomers('')
            } else if (query.length >= 1) {
                // Search with query
                loadCustomers(query)
            }
        }, 300)
    })

    // Handle clicking outside the customer search dropdown
    $(document).on('click', function(e) {
        if (!$(e.target).closest('#customer-search, #customer-search-results').length) {
            $('#customer-search-results').hide()
        }
    })

    // Remove selected customer
    $(document).on('click', '#remove-selected-customer', function() {
        $('#customer-id').val('')
        $('#selected-customer-info').addClass('d-none')
        $('#customer-search').val('').focus()

        // Remove customer from session
        saveCustomerToSession('');
    })

    // Select customer from search results
    $(document).on('click', '.customer-search-item', function() {
        const customerId = $(this).data('id')
        const customerName = $(this).data('name')
        const customerPhone = $(this).data('phone')
        const customerEmail = $(this).data('email')

        // Set hidden input value
        $('#customer-id').val(customerId)

        // Update the display
        $('#selected-customer-name').text(customerName)
        $('#selected-customer-contact').html(`<span>${customerPhone}</span>${customerEmail ? ` • <span>${customerEmail}</span>` : ''}`)

        // Show the customer info box
        $('#selected-customer-info').removeClass('d-none')

        // Hide dropdown and clear search input
        $('#customer-search-results').hide()
        $('#customer-search').val('')

        // Save customer to session
        saveCustomerToSession(customerId);
    })

    // Save customer to session
    function saveCustomerToSession(customerId) {
        const urls = getUrls();

        $httpClient.make()
            .post(urls.cartUpdateCustomer, {
                customer_id: customerId,
            })
            .then(response => {
                if (response.error) {
                    Botble.showError(response.message);
                }
            })
            .catch(error => {
                console.error('Error saving customer to session:', error);
            });
    }

    // Helper function to get URLs
    function getUrls() {
        const $container = $('#pos-container');
        return {
            cartAdd: $container.data('cart-add-url'),
            cartUpdate: $container.data('cart-update-url'),
            cartRemove: $container.data('cart-remove-url'),
            cartClear: $container.data('cart-clear-url'),
            cartApplyCoupon: $container.data('cart-apply-coupon-url'),
            cartRemoveCoupon: $container.data('cart-remove-coupon-url'),
            cartUpdateShipping: $container.data('cart-update-shipping-url'),
            cartUpdateManualDiscount: $container.data('cart-update-manual-discount-url'),
            cartRemoveManualDiscount: $container.data('cart-remove-manual-discount-url'),
            cartUpdateCustomer: $container.data('cart-update-customer-url'),
            cartUpdatePaymentMethod: $container.data('cart-update-payment-method-url'),
            products: $container.data('products-url'),
            quickShop: $container.data('quick-shop-url'),
            checkout: $container.data('checkout-url'),
            receipt: $container.data('receipt-url'),
        };
    }

    // Function to load customers
    function loadCustomers(query = '') {
        const $results = $('#customer-search-results')

        $.ajax({
            url: $container.data('search-customers-url') || route('pos-pro.search-customers'),
            method: 'GET',
            data: { q: query },
            beforeSend: function() {
                $results.html('<div class="dropdown-item text-center"><div class="spinner-border spinner-border-sm text-primary" role="status"></div></div>')
            },
            success: function(response) {
                if (response.data && response.data.results) {
                    if (response.data.results.length === 0) {
                        $results.html('<div class="dropdown-item text-center text-muted">No customers found</div>')
                        return
                    }

                    let html = ''
                    response.data.results.forEach(function(customer) {
                        html += `<a href="javascript:void(0)" class="dropdown-item customer-search-item"
                                    data-id="${customer.id}"
                                    data-name="${customer.text}"
                                    data-phone="${customer.phone || ''}"
                                    data-email="${customer.email || ''}">
                                    <div class="d-flex align-items-center">
                                        <div class="me-2"><svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M8 7a4 4 0 1 0 8 0a4 4 0 0 0 -8 0" /><path d="M6 21v-2a4 4 0 0 1 4 -4h4a4 4 0 0 1 4 4v2" /></svg></div>
                                        <div>
                                            <div class="fw-medium">${customer.name}</div>
                                            <div class="text-muted small">${customer.phone || ''} ${customer.email ? '• ' + customer.email : ''}</div>
                                        </div>
                                    </div>
                                </a>`
                    })

                    $results.html(html)
                } else {
                    $results.html('<div class="dropdown-item text-center text-muted">Error loading customers</div>')
                }
            },
            error: function() {
                $results.html('<div class="dropdown-item text-center text-danger">Error loading customers</div>')
            }
        })
    }

    // Send cart data to customer display via BroadcastChannel
    function sendCartToCustomerDisplay(cart) {
        if (!cart) return;

        // Transform cart items to a format suitable for the customer display
        const cartItems = (cart.items || []).map(item => ({
            id: item.id,
            name: item.name,
            price: parseFloat(item.price) || 0,
            qty: item.quantity || item.qty || 1,
            image: item.image_url || item.image || null,
            tax_rate: parseFloat(item.tax_rate) || 0
        }));

        // Calculate total discount (coupon + manual)
        const totalDiscount = (parseFloat(cart.coupon_discount) || 0) + (parseFloat(cart.manual_discount) || 0);

        // Send update message to customer display
        posChannel.postMessage({
            type: 'UPDATE_CART',
            cart: cartItems,
            discount: totalDiscount,
            shipping: parseFloat(cart.shipping_amount) || 0
        });
    }

    // Clear customer display when cart is cleared
    window.clearCustomerDisplay = function() {
        posChannel.postMessage({ type: 'CLEAR' });
    };

    // Customer Display button click handler (using event delegation)
    $(document).on('click', '#open-customer-display, #open-customer-display-mobile', function(e) {
        e.preventDefault();
        const customerDisplayUrl = $(this).data('customer-display-url');
        console.log('Customer Display URL:', customerDisplayUrl);
        if (customerDisplayUrl) {
            // Open customer display in a new window (sized for secondary display)
            window.open(customerDisplayUrl, 'CustomerDisplay', 'width=1024,height=768,scrollbars=no,resizable=yes');
        }
    });

    // Order Slot Tab click handler - Switch to another order
    $(document).on('click', '.order-slot-tab', function(e) {
        // Don't switch if clicking on the close button
        if ($(e.target).closest('.close-order-slot').length) {
            return;
        }

        const slot = $(this).data('slot');
        if (!slot || !urls.orderSlotsSwitch) return;

        $.ajax({
            url: urls.orderSlotsSwitch,
            method: 'POST',
            data: { slot: slot },
            success: function(response) {
                if (response.error) {
                    Botble.showError(response.message);
                } else {
                    window.updateCartDisplay(response.data.cart);
                    // Send cart to customer display
                    sendCartToCustomerDisplay(response.data.cart);
                }
            },
            error: function(xhr) {
                Botble.handleError(xhr);
            }
        });
    });

    // Add New Order Slot button click handler
    $(document).on('click', '.add-order-slot', function(e) {
        e.preventDefault();
        if (!urls.orderSlotsCreate) return;

        $.ajax({
            url: urls.orderSlotsCreate,
            method: 'POST',
            success: function(response) {
                if (response.error) {
                    Botble.showError(response.message);
                } else {
                    window.updateCartDisplay(response.data.cart);
                    Botble.showSuccess(response.message);
                    // Clear customer display for new order
                    if (typeof window.clearCustomerDisplay === 'function') {
                        window.clearCustomerDisplay();
                    }
                }
            },
            error: function(xhr) {
                Botble.handleError(xhr);
            }
        });
    });

    // Close Order Slot button click handler
    $(document).on('click', '.close-order-slot', function(e) {
        e.preventDefault();
        e.stopPropagation();

        const slot = $(this).data('slot');
        if (!slot || !urls.orderSlotsClose) return;

        const confirmMessage = window.trans && window.trans['plugins/pos-pro::pos.confirm_close_order']
            ? window.trans['plugins/pos-pro::pos.confirm_close_order']
            : 'Are you sure you want to close this order?';

        if (!confirm(confirmMessage)) {
            return;
        }

        $.ajax({
            url: urls.orderSlotsClose,
            method: 'POST',
            data: { slot: slot },
            success: function(response) {
                if (response.error) {
                    Botble.showError(response.message);
                } else {
                    window.updateCartDisplay(response.data.cart);
                    Botble.showSuccess(response.message);
                    // Send cart to customer display
                    sendCartToCustomerDisplay(response.data.cart);
                }
            },
            error: function(xhr) {
                Botble.handleError(xhr);
            }
        });
    });

    // Infinity scroll event handler
    $(window).on('scroll', function() {
        if (!hasMorePages || isLoading || ! $('#products-grid').length) {
            return;
        }

        const scrollPosition = $(window).scrollTop() + $(window).height();
        const threshold = $(document).height() - 200; // Load more when 200px from bottom

        if (scrollPosition >= threshold) {
            loadProducts(lastSearch, currentPage, true);
        }
    })

    // Coupon Modal
    $(document).on('click', '#apply-coupon-btn', function() {
        const $button = $(this)
        const $modal = $('#coupon-modal')
        const couponCode = $('#coupon-code-input').val().trim()
        const $errorMsg = $('#coupon-error-msg')

        if (!couponCode) {
            $errorMsg.text(trans('plugins/pos-pro::pos.please_enter_coupon_code'))
            $('#coupon-code-input').addClass('is-invalid')
            return
        }

        $httpClient.make()
            .withButtonLoading($button[0])
            .post(urls.cartApplyCoupon, {
                coupon_code: couponCode
            })
            .then((response) => {
                const { data } = response
                if (data.error) {
                    $errorMsg.text(data.message)
                    $('#coupon-code-input').addClass('is-invalid')
                    return
                }

                window.updateCartDisplay(data.data.cart)
                Botble.showSuccess(data.message)
                $modal.modal('hide')
                $('#coupon-code-input').removeClass('is-invalid')
            })
            .catch((error) => {
                Botble.handleError(error)
            })
    })

    // Remove coupon
    $(document).on('click', '#remove-coupon-btn', function() {
        const $button = $(this)
        const $modal = $('#coupon-modal')

        $httpClient.make()
            .withButtonLoading($button[0])
            .post(urls.cartRemoveCoupon)
            .then((response) => {
                const { data } = response
                if (data.error) {
                    Botble.showError(data.message)
                    return
                }

                window.updateCartDisplay(data.data.cart)
                Botble.showSuccess(data.message)
                $modal.modal('hide')
            })
            .catch((error) => {
                Botble.handleError(error)
            })
    })

    // Enter key in coupon field
    $(document).on('keypress', '.coupon-code', function(e) {
        if (e.which === 13) {
            e.preventDefault()
            $(this).closest('.coupon-form').find('.apply-coupon-code').click()
        }
    })

    // Enter key in coupon modal
    $(document).on('keypress', '#coupon-code-input', function(e) {
        if (e.which === 13) {
            e.preventDefault()
            $('#apply-coupon-btn').click()
        }
    })

    // Reset coupon modal when opened
    $('#coupon-modal').on('show.bs.modal', function() {
        const $modal = $(this)
        const $input = $('#coupon-code-input')
        const $errorMsg = $('#coupon-error-msg')

        // If there's a coupon code in the cart, show it in the input
        if (window.initialCart && window.initialCart.coupon_code) {
            $input.val(window.initialCart.coupon_code)
        } else {
            $input.val('')
        }

        $input.removeClass('is-invalid')
        $errorMsg.text('')
    })

    // Update shipping amount
    $(document).on('click', '#update-shipping', function() {
        const $button = $(this)
        const shippingAmount = $('#shipping-amount').val()

        $httpClient.make()
            .withButtonLoading($button[0])
            .post(urls.cartUpdateShipping, {
                shipping_amount: shippingAmount
            })
            .then((response) => {
                const { data } = response
                if (data.error) {
                    Botble.showError(data.message)
                    return
                }

                window.updateCartDisplay(data.data.cart)
                Botble.showSuccess(data.message)
            })
            .catch((error) => {
                Botble.handleError(error)
            })
    })

    // Enter key in shipping amount field
    $(document).on('keypress', '#shipping-amount', function(e) {
        if (e.which === 13) {
            e.preventDefault()
            $('#update-shipping').click()
        }
    })

    // Update shipping amount button click
    $(document).on('click', '#update-shipping', function() {
        const $button = $(this)
        const shippingAmount = parseFloat($('#shipping-amount').val()) || 0

        $httpClient.make()
            .withButtonLoading($button[0])
            .post(urls.cartUpdateShipping, {
                shipping_amount: shippingAmount
            })
            .then((response) => {
                const { data } = response
                if (data.error) {
                    Botble.showError(data.message || 'An error occurred')
                    return
                }
                window.updateCartDisplay(data.data.cart)
                Botble.showSuccess(data.message || 'Shipping amount updated successfully')
            })
            .catch((error) => {
                Botble.handleError(error)
            })
    })

    // Shipping Modal
    $(document).on('click', '#update-shipping-btn', function() {
        const $button = $(this)
        const $modal = $('#shipping-modal')
        const shippingAmount = parseFloat($('#shipping-amount-input').val()) || 0
        const $errorMsg = $('#shipping-error-msg')

        if (shippingAmount < 0) {
            $errorMsg.text(trans('plugins/pos-pro::pos.invalid_shipping_amount'))
            $('#shipping-amount-input').addClass('is-invalid')
            return
        }

        $errorMsg.text('')
        $('#shipping-amount-input').removeClass('is-invalid')

        $httpClient.make()
            .withButtonLoading($button[0])
            .post(urls.cartUpdateShipping, {
                shipping_amount: shippingAmount
            })
            .then((response) => {
                const { data } = response
                if (data.error) {
                    $errorMsg.text(data.message)
                    $('#shipping-amount-input').addClass('is-invalid')
                    return
                }
                window.updateCartDisplay(data.data.cart)
                Botble.showSuccess(data.message)
                $modal.modal('hide')
            })
            .catch((error) => {
                Botble.handleError(error)
            })
    })

    // Enter key in shipping amount field
    $(document).on('keypress', '#shipping-amount-input', function(e) {
        if (e.which === 13) {
            e.preventDefault()
            $('#update-shipping-btn').click()
        }
    })

    // Reset shipping modal when opened
    $('#shipping-modal').on('show.bs.modal', function() {
        const $modal = $(this)
        const $input = $('#shipping-amount-input')
        const $errorMsg = $('#shipping-error-msg')

        // If there's a shipping amount in the cart, show it in the input
        if (window.initialCart) {
            $input.val(window.initialCart.shipping_amount || 0)
        } else {
            $input.val(0)
        }

        $input.removeClass('is-invalid')
        $errorMsg.text('')
    })

    // Toggle discount symbol based on discount type
    $(document).on('change', 'input[name="discount-type"]', function() {
        const discountType = $('input[name="discount-type"]:checked').val();
        if (discountType === 'percentage') {
            $('#discount-symbol').text('%');
        } else {
            $('#discount-symbol').text(get_application_currency().symbol || '$');
        }
    });

    // Discount Modal
    $(document).on('click', '#apply-discount-btn', function() {
        const $button = $(this)
        const $modal = $('#discount-modal')
        const discountAmount = $('#discount-amount-input').val()
        const discountDescription = $('#discount-description-input').val()
        const discountType = $('input[name="discount-type"]:checked').val()
        const $errorMsg = $('#discount-error-msg')

        if (!discountAmount || parseFloat(discountAmount) <= 0) {
            $errorMsg.text(trans('plugins/pos-pro::pos.invalid_discount_amount'))
            $('#discount-amount-input').addClass('is-invalid')
            return
        }

        // Additional validation for percentage discount
        if (discountType === 'percentage' && parseFloat(discountAmount) > 100) {
            $errorMsg.text(trans('plugins/pos-pro::pos.percentage_discount_cannot_exceed_100'))
            $('#discount-amount-input').addClass('is-invalid')
            return
        }

        $errorMsg.text('')
        $('#discount-amount-input').removeClass('is-invalid')

        $httpClient.make()
            .withButtonLoading($button[0])
            .post(urls.cartUpdateManualDiscount, {
                discount_amount: discountAmount,
                discount_description: discountDescription,
                discount_type: discountType,
            })
            .then((response) => {
                const { data } = response
                if (data.error) {
                    $errorMsg.text(data.message)
                    $('#discount-amount-input').addClass('is-invalid')
                    return
                }
                window.updateCartDisplay(data.data.cart)
                Botble.showSuccess(data.message)
                $modal.modal('hide')
            })
            .catch((error) => {
                Botble.handleError(error)
            })
    })

    // Remove discount
    $(document).on('click', '#remove-discount-btn', function() {
        const $button = $(this)
        const $modal = $('#discount-modal')

        $httpClient.make()
            .withButtonLoading($button[0])
            .post(urls.cartRemoveManualDiscount)
            .then((response) => {
                const { data } = response
                if (data.error) {
                    Botble.showError(data.message)
                    return
                }
                window.updateCartDisplay(data.data.cart)
                Botble.showSuccess(data.message)
                $modal.modal('hide')
            })
            .catch((error) => {
                Botble.handleError(error)
            })
    })

    // Enter key in discount amount field
    $(document).on('keypress', '#discount-amount-input', function(e) {
        if (e.which === 13) {
            e.preventDefault()
            $('#apply-discount-btn').click()
        }
    })

    // Reset discount modal when opened
    $('#discount-modal').on('show.bs.modal', function() {
        const $modal = $(this)
        const $amountInput = $('#discount-amount-input')
        const $descriptionInput = $('#discount-description-input')
        const $errorMsg = $('#discount-error-msg')

        // If there's a discount in the cart, show it in the inputs
        if (window.initialCart && window.initialCart.manual_discount > 0) {
            // Set the discount type
            const discountType = window.initialCart.manual_discount_type || 'fixed';
            $(`input[name="discount-type"][value="${discountType}"]`).prop('checked', true).trigger('change');

            // Set the discount value
            if (discountType === 'percentage') {
                $amountInput.val(window.initialCart.manual_discount_value)
            } else {
                $amountInput.val(window.initialCart.manual_discount_value)
            }

            $descriptionInput.val(window.initialCart.manual_discount_description || '')
        } else {
            $amountInput.val('')
            $descriptionInput.val('')
            $('input[name="discount-type"][value="fixed"]').prop('checked', true).trigger('change');
        }

        $amountInput.removeClass('is-invalid')
        $errorMsg.text('')
    })

    // Add to cart button click
    $(document).on('click', '.add-to-cart', function() {
        const $button = $(this)
        const productId = $button.data('product-id')
        const hasVariations = $button.data('has-variations') === true
        const url = $button.data('url')

        if (hasVariations) {
            // Show quick shop modal for products with variations
            const quickShopUrl = urls.quickShop.replace(':id', productId)
            $httpClient.make()
                .withButtonLoading($button[0])
                .get(quickShopUrl)
                .then((response) => {
                    const { data } = response
                    $('#quick-shop-modal .modal-content').html(data.data?.html || data.html || '')
                    $('#quick-shop-modal').modal('show')
                })
                .catch((error) => {
                    Botble.handleError(error)
                })
            return
        }

        // Add simple product to cart
        $httpClient.make()
            .withButtonLoading($button[0])
            .post(url, {
                product_id: productId,
                quantity: 1,
            })
            .then((response) => {
                const { data } = response
                if (data.error) {
                    Botble.showError(data.message || 'An error occurred')
                    return
                }
                window.updateCartDisplay(data.data.cart)
                Botble.showSuccess(data.data.message || 'Product added to cart')
            })
            .catch((error) => {
                Botble.handleError(error)
            })
    })

    // Update quantity button click
    $(document).on('click', '.update-quantity', function(event) {
        event.preventDefault()
        event.stopPropagation()
        const $button = $(this)
        const productId = $button.data('product-id')
        const quantity = $button.data('quantity')

        // Don't allow negative quantities
        if (quantity < 1) {
            return
        }

        const url = urls.cartUpdate

        $httpClient.make()
            .withButtonLoading($button[0])
            .post(url, {
                product_id: productId,
                quantity: quantity,
            })
            .then((response) => {
                const { data } = response
                if (data.error) {
                    Botble.showError(data.message || 'An error occurred')
                    return
                }
                window.updateCartDisplay(data.data.cart)
                Botble.showSuccess(data.data.message || 'Cart updated successfully')
            })
            .catch((error) => {
                Botble.handleError(error)
            })
    })

    // Handle input validation for quantity fields
    $(document).on('input', '.cart-item input[type="text"]', function() {
        // Allow only numbers
        this.value = this.value.replace(/[^0-9]/g, '')

        // Store the current valid value
        if (this.value && !isNaN(parseInt(this.value, 10))) {
            $(this).data('last-value', this.value)
        }
    })

    // Remove from cart button click
    $(document).on('click', '.remove-from-cart', function(event) {
        event.preventDefault()
        event.stopPropagation()
        const $button = $(this)
        const productId = $button.data('product-id')
        const url = urls.cartRemove

        $httpClient.make()
            .withButtonLoading($button[0])
            .post(url, {
                product_id: productId,
            })
            .then((response) => {
                const { data } = response
                if (data.error) {
                    Botble.showError(data.message || 'An error occurred')
                    return
                }
                window.updateCartDisplay(data.data.cart)
                Botble.showSuccess(data.data.message || 'Item removed from cart')
            })
            .catch((error) => {
                Botble.handleError(error)
            })
    })

    // Clear cart button click - show confirmation modal
    $(document).on('click', '#clear-cart', function() {
        const modal = new bootstrap.Modal(document.getElementById('clear-cart-modal'))
        modal.show()
    })

    // Confirm clear cart button click
    $(document).on('click', '#confirm-clear-cart-btn', function() {
        const $button = $(this)
        const url = urls.cartClear
        const modal = bootstrap.Modal.getInstance(document.getElementById('clear-cart-modal'))

        $httpClient.make()
            .withButtonLoading($button[0])
            .post(url)
            .then((response) => {
                const { data } = response
                if (data.error) {
                    Botble.showError(data.message || 'An error occurred')
                    return
                }
                window.updateCartDisplay(data.data.cart)
                Botble.showSuccess(data.data.message || 'Cart cleared successfully')
                if (modal) {
                    modal.hide()
                }
            })
            .catch((error) => {
                Botble.handleError(error)
            })
    })

    // Quick shop form submit
    $(document).on('submit', '#quick-shop-form', function(e) {
        e.preventDefault()
        const $form = $(this)
        const $submitButton = $form.find('button[type="submit"]')
        const url = urls.cartAdd

        // Get form values explicitly
        const productId = $form.find('input[name="product_id"]').val()
        const quantity = $form.find('input[name="quantity"]').val() || 1

        // Get selected attributes
        let selectedAttributes = [];

        // Get values from select dropdowns
        $form.find('select.variation-select').each(function() {
            const setId = $(this).data('attribute-id');
            const attrId = $(this).val();
            if (attrId && setId) {
                selectedAttributes[setId] = attrId;
            }
        });

        // Get values from radio buttons
        $form.find('input[type="radio"]:checked').each(function() {
            const setId = $(this).data('attribute-id');
            const attrId = $(this).val();
            if (attrId && setId) {
                selectedAttributes[setId] = attrId;
            }
        });

        $httpClient.make()
            .withButtonLoading($submitButton[0])
            .post(url, {
                product_id: productId,
                quantity: quantity,
                attributes: selectedAttributes
            })
            .then((response) => {
                const { data } = response
                if (data.error) {
                    Botble.showError(data.message || 'An error occurred')
                    return
                }
                $('#quick-shop-modal').modal('hide')
                window.updateCartDisplay(data.data.cart)
                Botble.showSuccess(data.data.message || 'Product added to cart')
            })
            .catch((error) => {
                Botble.handleError(error)
            })
    })

    // When payment method is selected in cart, update the checkout modal
    $(document).on('change', '#cart-items input[name="payment_method"]', function() {
        const selectedPaymentMethod = $(this).val();
        // Store the selected payment method to use when the checkout modal opens
        window.selectedPaymentMethod = selectedPaymentMethod;

        // Save payment method to session
        savePaymentMethodToSession(selectedPaymentMethod);
    });

    // Save payment method to session
    function savePaymentMethodToSession(paymentMethod) {
        const urls = getUrls();

        $httpClient.make()
            .post(urls.cartUpdatePaymentMethod, {
                payment_method: paymentMethod,
            })
            .then(response => {
                if (response.error) {
                    Botble.showError(response.message);
                }
            })
            .catch(error => {
                console.error('Error saving payment method to session:', error);
            });
    }

    // Function to load address form dynamically
    function loadAddressForm(customerId) {
        const addressFormContainer = $('#address-form-container');

        // Show loading state
        addressFormContainer.html(`
            <div class="text-center py-3">
                <div class="spinner-border spinner-border-sm text-primary" role="status">
                    <span class="visually-hidden">${trans('plugins/pos-pro::pos.loading')}...</span>
                </div>
                <div class="mt-2 text-muted">${trans('plugins/pos-pro::pos.loading_address_form')}</div>
            </div>
        `);

        // Load address form
        const addressFormUrl = $container.data('address-form-url') || '/admin/pos/address-form';
        $.ajax({
            url: addressFormUrl,
            method: 'GET',
            data: { customer_id: customerId },
            success: function(response) {
                if (response && response.data && response.data.html) {
                    addressFormContainer.html(response.data.html);
                } else {
                    addressFormContainer.html(`
                        <div class="alert alert-warning">
                            <div class="text-muted">${trans('plugins/pos-pro::pos.address_form_load_error')}</div>
                        </div>
                    `);
                }
            },
            error: function() {
                addressFormContainer.html(`
                    <div class="alert alert-danger">
                        <div class="text-danger">${trans('plugins/pos-pro::pos.address_form_load_error')}</div>
                    </div>
                `);
            }
        });
    }

    // Function to handle delivery option changes
    function handleDeliveryOptionChange() {
        const deliveryOption = $('input[name="delivery_option"]:checked').val();
        const addressSection = $('#customer-address-section');
        const helpText = $('#delivery-option-help');

        if (deliveryOption === 'pickup') {
            // Hide address section for pickup
            addressSection.hide();
            helpText.text(trans('plugins/pos-pro::pos.pickup_in_store_help'));
        } else {
            // Show address section for shipping
            addressSection.show();
            helpText.text(trans('plugins/pos-pro::pos.ship_to_address_help'));
        }
    }

    // Checkout button click
    $(document).on('click', '#checkout-button', function(event) {
        event.preventDefault();
        event.stopPropagation();

        // Get payment method information
        const paymentMethod = $('input[name="payment_method"]:checked').val() || 'cash';
        const paymentMethodText = $('input[name="payment_method"]:checked').closest('.form-selectgroup-item').find('.form-selectgroup-title').text() || trans('plugins/pos-pro::pos.cash');
        const paymentMethodIcon = paymentMethod === 'cash' ? 'ti-cash' : (paymentMethod === 'card' ? 'ti-credit-card' : 'ti-wallet');

        // Set payment method in the checkout modal
        $('#checkout-payment-method').val(paymentMethod);
        $('#checkout-payment-method-info').html(`<x-core::icon name="${paymentMethodIcon}" class="me-1" /> ${paymentMethodText}`);

        // Get customer information
        const customerId = $('#customer-id').val();
        let customerText = trans('plugins/pos-pro::pos.guest');
        let customerName = '';
        let customerPhone = '';
        let customerEmail = '';

        if (customerId && $('#selected-customer-name').text()) {
            customerText = $('#selected-customer-name').text();
            customerName = $('#selected-customer-name').text();

            // Get customer contact info (phone and email)
            const contactText = $('#selected-customer-contact').text();
            if (contactText) {
                const contactParts = contactText.split('•');
                if (contactParts.length > 0) {
                    customerPhone = contactParts[0].trim();
                }
                if (contactParts.length > 1) {
                    customerEmail = contactParts[1].trim();
                }
            }

            $('#checkout-customer-id').val(customerId);

            // Add hidden fields for customer information
            if (!$('#checkout-customer-name').length) {
                $('#checkout-form').append(`<input type="hidden" id="checkout-customer-name" name="customer_name" value="${customerName}">`);
                $('#checkout-form').append(`<input type="hidden" id="checkout-customer-phone" name="customer_phone" value="${customerPhone}">`);
                $('#checkout-form').append(`<input type="hidden" id="checkout-customer-email" name="customer_email" value="${customerEmail}">`);
            } else {
                $('#checkout-customer-name').val(customerName);
                $('#checkout-customer-phone').val(customerPhone);
                $('#checkout-customer-email').val(customerEmail);
            }
        } else {
            $('#checkout-customer-id').val('');

            // Remove customer information fields if they exist
            $('#checkout-customer-name, #checkout-customer-phone, #checkout-customer-email').remove();
        }

        // Set customer info in the checkout modal
        $('#checkout-customer-info').text(customerText);

        // Load address form dynamically
        loadAddressForm(customerId);

        // Handle delivery option changes
        handleDeliveryOptionChange();

        // Update order summary values from the current cart data
        if (window.initialCart) {
            // Update subtotal
            $('#modal-subtotal').text(window.initialCart.subtotal_formatted);

            // Update tax
            $('#modal-tax').text(window.initialCart.tax_formatted);

            // Update shipping
            $('#modal-shipping').text(window.initialCart.shipping_amount_formatted);

            // Update total
            $('#modal-total').text(window.initialCart.total_formatted);

            // Handle coupon discount
            const hasCouponDiscount = window.initialCart.coupon_discount && window.initialCart.coupon_discount > 0;
            const couponDiscountRow = $('#checkout-modal .datagrid-item.coupon-discount-row');

            if (hasCouponDiscount) {
                if (couponDiscountRow.length === 0) {
                    // Create coupon discount row if it doesn't exist
                    const couponCode = window.initialCart.coupon_code || '';
                    const couponBadge = couponCode ? `<span class="badge bg-blue-lt ms-1">${couponCode}</span>` : '';

                    const couponRow = `
                        <div class="datagrid-item coupon-discount-row">
                            <div class="datagrid-title">
                                <div class="d-flex align-items-center">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="me-1 text-primary"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M5 7.2a3 3 0 0 1 6 -2.2h2a3 3 0 0 1 6 2.2v1.8a1 1 0 0 1 -.883 .993l-.117 .007h-2v7a1 1 0 0 1 -1 1h-6a1 1 0 0 1 -1 -1v-7h-2a1 1 0 0 1 -1 -1v-1.8z" /><path d="M9 12l2 2l4 -4" /></svg>
                                    ${trans('plugins/pos-pro::pos.coupon_discount')}
                                    ${couponBadge}
                                </div>
                            </div>
                            <div class="datagrid-content text-danger">-${window.initialCart.coupon_discount_formatted}</div>
                        </div>
                    `;

                    // Insert before the total row
                    $('#checkout-modal .datagrid-item:last').before(couponRow);
                } else {
                    // Update existing coupon discount row
                    couponDiscountRow.find('.datagrid-content').text('-' + window.initialCart.coupon_discount_formatted);
                }
            } else {
                // Remove coupon discount row if it exists but there's no discount
                couponDiscountRow.remove();
            }

            // Handle manual discount
            const hasManualDiscount = window.initialCart.manual_discount && window.initialCart.manual_discount > 0;
            const manualDiscountRow = $('#checkout-modal .datagrid-item.manual-discount-row');

            if (hasManualDiscount) {
                if (manualDiscountRow.length === 0) {
                    // Create manual discount row if it doesn't exist
                    const discountDescription = window.initialCart.manual_discount_description || '';
                    const discountBadge = discountDescription ?
                        `<span class="badge bg-blue-lt ms-1" title="${discountDescription}">${discountDescription.length > 15 ? discountDescription.substring(0, 15) + '...' : discountDescription}</span>` : '';

                    const discountRow = `
                        <div class="datagrid-item manual-discount-row">
                            <div class="datagrid-title">
                                <div class="d-flex align-items-center">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="me-1 text-primary"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M9 5h6a2 2 0 0 1 2 2v2a2 2 0 0 1 -2 2h-6a2 2 0 0 1 -2 -2v-2a2 2 0 0 1 2 -2" /><path d="M9 13h6a2 2 0 0 1 2 2v2a2 2 0 0 1 -2 2h-6a2 2 0 0 1 -2 -2v-2a2 2 0 0 1 2 -2" /><path d="M9 7l8 10" /></svg>
                                    ${trans('plugins/pos-pro::pos.manual_discount')}
                                    ${discountBadge}
                                </div>
                            </div>
                            <div class="datagrid-content text-danger">-${window.initialCart.manual_discount_formatted}</div>
                        </div>
                    `;

                    // Insert before the total row
                    $('#checkout-modal .datagrid-item:last').before(discountRow);
                } else {
                    // Update existing manual discount row
                    manualDiscountRow.find('.datagrid-content').text('-' + window.initialCart.manual_discount_formatted);
                }
            } else {
                // Remove manual discount row if it exists but there's no discount
                manualDiscountRow.remove();
            }
        }

        $('#checkout-modal').modal('show');

        // Initialize cash payment section
        initCashPaymentSection();
    })

    // Cash payment section functions
    function initCashPaymentSection() {
        const paymentMethod = $('#checkout-payment-method').val() || 'cash';
        const total = window.initialCart ? window.initialCart.total : 0;

        // Show/hide cash payment section based on payment method
        if (paymentMethod === 'cash') {
            $('#cash-payment-section').show();
        } else {
            $('#cash-payment-section').hide();
        }

        // Reset cash received input
        $('#cash-received-input').val('');
        updateChangeAmount(0, total);

        // Generate quick cash buttons
        generateQuickCashButtons(total);
    }

    function generateQuickCashButtons(total) {
        const $container = $('#quick-cash-buttons');
        $container.empty();

        // Add "Exact" button first
        const exactText = window.trans && window.trans['plugins/pos-pro::pos.exact']
            ? window.trans['plugins/pos-pro::pos.exact']
            : 'Exact';
        $container.append(`<button type="button" class="btn btn-outline-success quick-cash-btn" data-amount="exact">${exactText}</button>`);

        // Generate common denominations based on total
        const denominations = generateDenominations(total);
        denominations.forEach(amount => {
            const formattedAmount = formatCurrency(amount);
            $container.append(`<button type="button" class="btn btn-outline-secondary quick-cash-btn" data-amount="${amount}">${formattedAmount}</button>`);
        });
    }

    function generateDenominations(total) {
        const denominations = [];
        if (total <= 0) return denominations;

        // Round up to nearest common amounts
        const roundUpValues = [10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000, 500000];

        for (let i = 0; i < roundUpValues.length && denominations.length < 4; i++) {
            if (roundUpValues[i] >= total && !denominations.includes(roundUpValues[i])) {
                denominations.push(roundUpValues[i]);
            }
        }

        // If we don't have enough, add some larger amounts
        if (denominations.length < 2) {
            const ceilTotal = Math.ceil(total / 10) * 10;
            if (!denominations.includes(ceilTotal) && ceilTotal > total) {
                denominations.unshift(ceilTotal);
            }
        }

        return denominations.slice(0, 4);
    }

    function formatCurrency(amount) {
        const symbol = window.currencySymbol || '$';
        const isPrefix = window.currencyIsPrefix !== false;
        const formatted = new Intl.NumberFormat().format(amount);

        return isPrefix ? symbol + formatted : formatted + symbol;
    }

    function updateChangeAmount(cashReceived, total) {
        const change = cashReceived - total;
        const $changeAmount = $('#change-amount');
        const $changeStatus = $('#change-status');

        if (cashReceived === 0 || cashReceived === '') {
            $changeAmount.text(formatCurrency(0));
            $changeAmount.removeClass('text-success text-danger').addClass('text-muted');
            $changeStatus.addClass('d-none');
        } else if (change >= 0) {
            $changeAmount.text(formatCurrency(change));
            $changeAmount.removeClass('text-muted text-danger').addClass('text-success');
            $changeStatus.addClass('d-none');
        } else {
            $changeAmount.text('-' + formatCurrency(Math.abs(change)));
            $changeAmount.removeClass('text-muted text-success').addClass('text-danger');
            $changeStatus.removeClass('d-none');
        }
    }

    // Cash received input change event
    $(document).on('input', '#cash-received-input', function() {
        const cashReceived = parseFloat($(this).val()) || 0;
        const total = window.initialCart ? window.initialCart.total : 0;
        updateChangeAmount(cashReceived, total);
    });

    // Quick cash button click event
    $(document).on('click', '.quick-cash-btn', function() {
        const amount = $(this).data('amount');
        const total = window.initialCart ? window.initialCart.total : 0;

        if (amount === 'exact') {
            $('#cash-received-input').val(total.toFixed(2));
            updateChangeAmount(total, total);
        } else {
            $('#cash-received-input').val(parseFloat(amount).toFixed(2));
            updateChangeAmount(parseFloat(amount), total);
        }
    });

    // Update cash payment section when payment method changes
    $(document).on('change', '#cart-items input[name="payment_method"]', function() {
        const paymentMethod = $(this).val();
        $('#checkout-payment-method').val(paymentMethod);

        // Update payment method display in checkout modal
        const paymentIcons = {
            'cash': '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="me-1 text-success"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M17 9v-2a2 2 0 0 0 -2 -2h-10a2 2 0 0 0 -2 2v6a2 2 0 0 0 2 2h2" /><path d="M13 9h8a2 2 0 0 1 2 2v6a2 2 0 0 1 -2 2h-8a2 2 0 0 1 -2 -2v-6a2 2 0 0 1 2 -2z" /><path d="M17 14a1 1 0 1 0 2 0a1 1 0 0 0 -2 0" /></svg>',
            'card': '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="me-1 text-info"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M3 5m0 3a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v8a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3z" /><path d="M3 10l18 0" /><path d="M7 15l.01 0" /><path d="M11 15l2 0" /></svg>',
            'other': '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="me-1 text-warning"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M17 8v-3a1 1 0 0 0 -1 -1h-10a2 2 0 0 0 0 4h12a1 1 0 0 1 1 1v3m0 4v3a1 1 0 0 1 -1 1h-12a2 2 0 0 1 -2 -2v-12" /><path d="M20 12v4h-4a2 2 0 0 1 0 -4h4" /></svg>'
        };
        const paymentLabels = {
            'cash': window.trans && window.trans['plugins/pos-pro::pos.cash'] ? window.trans['plugins/pos-pro::pos.cash'] : 'Cash',
            'card': window.trans && window.trans['plugins/pos-pro::pos.card'] ? window.trans['plugins/pos-pro::pos.card'] : 'Card',
            'other': window.trans && window.trans['plugins/pos-pro::pos.other'] ? window.trans['plugins/pos-pro::pos.other'] : 'Other'
        };

        $('#checkout-payment-method-info').html(paymentIcons[paymentMethod] + paymentLabels[paymentMethod]);

        // Show/hide cash payment section
        if (paymentMethod === 'cash') {
            $('#cash-payment-section').show();
        } else {
            $('#cash-payment-section').hide();
        }
    });

    // Delivery option change event
    $(document).on('change', 'input[name="delivery_option"]', function() {
        handleDeliveryOptionChange();
    });

    // Complete order button click
    $(document).on('click', '#complete-order-btn', function() {
        const $button = $(this);
        const $form = $('#checkout-form');

        Botble.showButtonLoading($button[0]);

        $.ajax({
            url: urls.checkout,
            method: 'POST',
            data: $form.serializeArray(),
            success: function(response) {
                if (response.error) {
                    Botble.showError(response.message);
                } else {
                    $('#checkout-modal').modal('hide');
                    Botble.showSuccess(response.message);
                    if (response.data.order_ids && response.data.order_ids.length > 1) {
                        const orderCodes = response.data.orders ? response.data.orders.map(o => o.code).join(', ') : response.data.order_code;
                        $('#order-number').text(orderCodes);
                        $('#multiple-orders-info').removeClass('d-none');
                        $('#print-receipt-btn').data('order-ids', response.data.order_ids.join(','));
                    } else {
                        $('#order-number').text(response.data.order_code || response.data.order.code);
                        $('#multiple-orders-info').addClass('d-none');
                        $('#print-receipt-btn').data('order-ids', response.data.order_id || response.data.order.id);
                    }
                    $('#success-modal').modal('show');
                }
            },
            error: function(xhr) {
                Botble.handleError(xhr);
            },
            complete: function() {
                Botble.hideButtonLoading($button[0]);
            }
        });
    });

    // Variables for infinity loading
    let currentPage = 1;
    let hasMorePages = true;
    let isLoading = false;
    let lastSearch = '';

    // Load products function
    function loadProducts(search = '', page = 1, append = false) {
        if (isLoading || ! urls.products) {
            return;
        }

        isLoading = true;
        lastSearch = search;

        // Create HTTP client instance
        const client = $httpClient.make();

        // Show loading indicator
        if (page > 1) {
            $('.load-more-loading').removeClass('d-none');
        } else {
            client.withLoading($('#products-grid')[0]);
        }

        client.get(urls.products, { search, page })
            .then((response) => {
                const { data } = response;

                // Update pagination variables
                hasMorePages = data.data.has_more || false;
                currentPage = data.data.next_page || (currentPage + 1);

                // Update DOM
                if (append) {
                    // Create a temporary div to parse the HTML
                    const tempDiv = document.createElement('div');
                    tempDiv.innerHTML = data.data.html;

                    // Find all product cards and append them
                    const productCards = $(tempDiv).find('.col-md-4');
                    $('#products-grid').append(productCards);
                } else {
                    $('#products-grid').html(data.data.html || data.html || '');
                }

                // Hide loading indicator
                $('.load-more-loading').addClass('d-none');
                isLoading = false;

                // Reinitialize tooltips for newly added elements
                const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
                tooltipTriggerList.map(function (tooltipTriggerEl) {
                    return new bootstrap.Tooltip(tooltipTriggerEl);
                });
            })
            .catch((error) => {
                Botble.handleError(error);
                isLoading = false;
                $('.load-more-loading').addClass('d-none');
            });
    }

    // No longer need formatPrice function as prices are formatted on the server side

    // Format price function is above

    // Global function to update quantity from input field
    window.updateQuantity = function(productId, quantity) {
        // Convert to number and validate
        quantity = parseInt(quantity, 10)
        if (isNaN(quantity) || quantity < 1) {
            quantity = 1
        }

        const $input = $(`.cart-item[data-product-id="${productId}"] input`)
        const url = urls.cartUpdate

        $httpClient.make()
            .withButtonLoading($input.closest('.input-group').find('button')[0])
            .post(url, {
                product_id: productId,
                quantity: quantity,
            })
            .then((response) => {
                const { data } = response
                if (data.error) {
                    Botble.showError(data.message || 'An error occurred')
                    // Reset input value on error
                    $input.val($input.data('last-value') || 1)
                    return
                }
                // Store last valid value
                $input.data('last-value', quantity)
                window.updateCartDisplay(data.data.cart)
                Botble.showSuccess(data.data.message || 'Quantity updated successfully')
            })
            .catch((error) => {
                Botble.handleError(error)
                // Reset input value on error
                $input.val($input.data('last-value') || 1)
            })
    }
})

// Receipt and order success functions
$(document).ready(function() {
    const $container = $('#pos-container');
    const urls = {
        cartAdd: $container.data('cart-add-url'),
        cartUpdate: $container.data('cart-update-url'),
        cartRemove: $container.data('cart-remove-url'),
        cartClear: $container.data('cart-clear-url'),
        cartApplyCoupon: $container.data('cart-apply-coupon-url'),
        cartRemoveCoupon: $container.data('cart-remove-coupon-url'),
        cartUpdateShipping: $container.data('cart-update-shipping-url'),
        cartUpdateManualDiscount: $container.data('cart-update-manual-discount-url'),
        cartRemoveManualDiscount: $container.data('cart-remove-manual-discount-url'),
        products: $container.data('products-url'),
        quickShop: $container.data('quick-shop-url'),
        checkout: $container.data('checkout-url'),
        receipt: $container.data('receipt-url'),
    };
    $(document).on('click', '#print-receipt-btn', function() {
        const orderIds = $(this).data('order-ids') || $(this).data('order-id');
        if (orderIds) {
            window.open(urls.receipt.replace(':id', orderIds), '_blank');
        } else {
            Botble.showError('Order ID not found');
        }
    });

    // New order button click
    $(document).on('click', '#new-order-btn', function() {
        $('#success-modal').modal('hide');
        clearCart();
    });

    // When success modal is hidden, refresh the cart session and display
    $('#success-modal').on('hidden.bs.modal', function() {
        // Reset customer and payment method when closing success modal
        $.ajax({
            url: $container.data('cart-reset-customer-payment-url') || '/pos-pro/cart/reset-customer-payment',
            method: 'POST',
            success: function(resetResponse) {
                if (!resetResponse.error) {
                    // Update the display with the fully reset cart
                    window.updateCartDisplay(resetResponse.data.cart);
                    Botble.showSuccess(resetResponse.message);
                }
            },
            error: function(xhr) {
                Botble.handleError(xhr);
                // Fallback to just clearing the cart if reset fails
                $.ajax({
                    url: urls.cartClear,
                    method: 'POST',
                    success: function(response) {
                        if (!response.error) {
                            window.updateCartDisplay(response.data.cart);
                        }
                    }
                });
            }
        });
    });

    // Define clearCart function in the same scope as urls
    window.clearCart = function() {
        $.ajax({
            url: urls.cartClear,
            method: 'POST',
            success: function(response) {
                if (response.error) {
                    Botble.showError(response.message);
                } else {
                    // Use the global updateCartDisplay function
                    window.updateCartDisplay(response.data.cart);
                    // Clear customer display
                    if (typeof window.clearCustomerDisplay === 'function') {
                        window.clearCustomerDisplay();
                    }
                    Botble.showSuccess(response.message);
                }
            },
            error: function(xhr) {
                Botble.handleError(xhr);
            }
        });
    };
});

function formatPrice(price) {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: window.currency || 'USD'
    }).format(price);
}

// Cash Register Management
$(document).ready(function() {
    const $container = $('#pos-container');

    // Get register URLs from data attributes
    const registerUrls = {
        status: $container.data('register-status-url'),
        open: $container.data('register-open-url'),
        close: $container.data('register-close-url'),
    };

    // Initialize register state from data attribute
    let isRegisterOpen = $container.data('register-is-open') === 'true';
    let registerData = null;

    // Register status button click handler
    $(document).on('click', '#register-status-btn, #register-status-btn-mobile', function(e) {
        e.preventDefault();

        // Fetch current register status
        if (!registerUrls.status) return;

        $.ajax({
            url: registerUrls.status,
            method: 'GET',
            success: function(response) {
                if (response.data) {
                    registerData = response.data;
                    isRegisterOpen = response.data.is_open;

                    if (isRegisterOpen) {
                        // Show close register modal with current data
                        showCloseRegisterModal(response.data);
                    } else {
                        // Show open register modal
                        $('#open-register-modal').modal('show');
                    }
                }
            },
            error: function(xhr) {
                Botble.handleError(xhr);
            }
        });
    });

    // Open register form submission
    $(document).on('click', '#confirm-open-register', function() {
        const $button = $(this);
        const cashStart = parseFloat($('#register-cash-start').val()) || 0;
        const notes = $('#register-open-notes').val();

        if (!registerUrls.open) return;

        $httpClient.make()
            .withButtonLoading($button[0])
            .post(registerUrls.open, {
                cash_start: cashStart,
                notes: notes
            })
            .then(function(response) {
                if (response.data.error) {
                    Botble.showError(response.data.message);
                    return;
                }

                isRegisterOpen = true;
                updateRegisterStatusUI(true);
                $('#open-register-modal').modal('hide');
                $('#register-cash-start').val(0);
                $('#register-open-notes').val('');
                Botble.showSuccess(response.data.message);
            })
            .catch(function(error) {
                Botble.handleError(error);
            });
    });

    // Close register form submission
    $(document).on('click', '#confirm-close-register', function() {
        const $button = $(this);
        const actualCash = parseFloat($('#register-actual-cash').val()) || 0;
        const notes = $('#register-close-notes').val();

        if (!registerUrls.close) return;

        $httpClient.make()
            .withButtonLoading($button[0])
            .post(registerUrls.close, {
                actual_cash: actualCash,
                notes: notes
            })
            .then(function(response) {
                if (response.data.error) {
                    Botble.showError(response.data.message);
                    return;
                }

                isRegisterOpen = false;
                updateRegisterStatusUI(false);
                $('#close-register-modal').modal('hide');
                $('#register-actual-cash').val(0);
                $('#register-close-notes').val('');
                Botble.showSuccess(response.data.message);
            })
            .catch(function(error) {
                Botble.handleError(error);
            });
    });

    // Calculate difference when actual cash is entered
    $(document).on('input', '#register-actual-cash', function() {
        const actualCash = parseFloat($(this).val()) || 0;
        const expectedCash = parseFloat($('#close-register-expected').data('expected')) || 0;
        const difference = actualCash - expectedCash;

        $('#register-difference').val(difference.toFixed(2));

        // Update styling based on difference
        if (difference >= 0) {
            $('#register-difference').removeClass('text-danger').addClass('text-success');
        } else {
            $('#register-difference').removeClass('text-success').addClass('text-danger');
        }
    });

    // Show close register modal with data
    function showCloseRegisterModal(data) {
    const currencySymbol = window.currencySymbol || '$';
    const register = data.register || {};

    // Update modal with current register data
    $('#close-register-start').text(currencySymbol + (register.cash_start?.toFixed(2) || '0.00'));
    $('#close-register-sales').text(currencySymbol + (register.cash_sales?.toFixed(2) || '0.00'));
    $('#close-register-expected').text(currencySymbol + (register.expected_cash?.toFixed(2) || '0.00'));
    $('#close-register-expected').data('expected', register.expected_cash || 0);

    // Pre-fill actual cash with expected amount
    $('#register-actual-cash').val(register.expected_cash?.toFixed(2) || 0);
    $('#register-difference').val('0.00');

    $('#close-register-modal').modal('show');
}

    // Update register status in UI
    function updateRegisterStatusUI(isOpen) {
        const $badge = $('#register-status-badge, #register-status-badge-mobile');
        const $text = $('#register-status-text');
        const $textMobile = $('#register-status-text-mobile');

        if (isOpen) {
            $badge.removeClass('bg-red').addClass('bg-green');
            $badge.text(window.trans?.['plugins/pos-pro::pos.open'] || 'Open');
            $text.text(window.trans?.['plugins/pos-pro::pos.register_open'] || 'Register Open');
            $textMobile.text(window.trans?.['plugins/pos-pro::pos.click_to_close_register'] || 'Click to close register');
        } else {
            $badge.removeClass('bg-green').addClass('bg-red');
            $badge.text(window.trans?.['plugins/pos-pro::pos.closed'] || 'Closed');
            $text.text(window.trans?.['plugins/pos-pro::pos.register_closed'] || 'Register Closed');
            $textMobile.text(window.trans?.['plugins/pos-pro::pos.click_to_open_register'] || 'Click to open register');
        }
    }

    // Check register status on page load
    if (registerUrls.status) {
        $.ajax({
            url: registerUrls.status,
            method: 'GET',
            success: function(response) {
                if (response.data) {
                    isRegisterOpen = response.data.is_open;
                    updateRegisterStatusUI(isRegisterOpen);
                }
            }
        });
    }
});

// Quick shop form handling
$(document).ready(function() {
    const $container = $('#pos-container');

    // Add these URLs for the quick shop functionality
    const getVariationUrl = $container.data('get-variation-url') || '/pos-pro/get-variation';
    const productPriceUrl = $container.data('product-price-url') || '/pos-pro/product-price';

    // Handle both radio buttons and select dropdowns for variation selection
    $(document).on('change', '.quick-shop-form .variation-select, .attribute-swatch-item input[type="radio"]', function() {
        const form = $(this).closest('form');
        const variationInfo = form.find('.variation-info');
        const variationPrice = form.find('.variation-price');
        const variationStock = form.find('.variation-stock');

        // Get all selected attributes
        let selectedAttributes = {};

        // Get values from select dropdowns
        form.find('select.variation-select').each(function() {
            const setId = $(this).data('attribute-id');
            const attrId = $(this).val();
            if (attrId) {
                selectedAttributes[setId] = attrId;

                // Store attribute information for display
                const attributeTitle = $(this).find('option:selected').text().trim();
                const attributeSetTitle = $(this).closest('.attribute-swatches-wrapper').find('label').text().replace(':', '').trim();

                // Store this information as data attributes for later use
                $(this).data('attribute-set-title', attributeSetTitle);
                $(this).data('attribute-title', attributeTitle);
            }
        });

        // Get values from radio buttons
        form.find('input[type="radio"]:checked').each(function() {
            const setId = $(this).data('attribute-id');
            const attrId = $(this).val();
            if (attrId) {
                selectedAttributes[setId] = attrId;

                // Store attribute information for display
                const attributeTitle = $(this).closest('label').find('.attribute-swatch-text').text().trim() ||
                                      $(this).closest('label').find('.attribute-swatch-item-tooltip').text().trim();
                const attributeSetTitle = $(this).closest('.attribute-swatches-wrapper').find('h4.attribute-name').text().replace(':', '').trim();

                // Store this information as data attributes for later use
                $(this).data('attribute-set-title', attributeSetTitle);
                $(this).data('attribute-title', attributeTitle);
            }
        });

        // Find the total number of attribute sets
        const totalAttributeSets = form.find('.attribute-swatches-wrapper').length;

        // Check if all attributes are selected
        const allSelected = Object.keys(selectedAttributes).length === totalAttributeSets;

        // Find matching variation
        const productId = form.data('product-id');

        // Make AJAX request to get variation data
        $.ajax({
            url: getVariationUrl,
            method: 'GET',
            data: {
                product_id: productId,
                attributes: selectedAttributes
            },
            success: function(response) {
                // Update available attributes based on current selection
                if (response.data && response.data.availableAttributes) {
                    updateAvailableAttributes(form, response.data.availableAttributes, selectedAttributes);
                }

                if (response.data && response.data.variation) {
                    const variation = response.data.variation;

                    // Update the product_id hidden input with the variation's product_id
                    form.find('input[name="product_id"]').val(variation.product.id);

                    // Update price
                    $.get(`${productPriceUrl}?product_id=${variation.product.id}`, function(priceResponse) {
                        variationPrice.html(priceResponse.data);
                    });

                    // Update stock information
                    if (variation.product.with_storehouse_management) {
                        if (variation.product.quantity > 0) {
                            variationStock.html(`<span class="badge bg-green-lt">
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="me-1"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M12 3l8 4.5l0 9l-8 4.5l-8 -4.5l0 -9l8 -4.5" /><path d="M12 12l8 -4.5" /><path d="M12 12l0 9" /><path d="M12 12l-8 -4.5" /></svg> ${window.trans.in_stock || 'In Stock'}: ${variation.product.quantity}
                            </span>`);
                        } else {
                            variationStock.html(`<span class="badge bg-red-lt">
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="me-1"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M12 9v4" /><path d="M10.363 3.591l-8.106 13.534a1.914 1.914 0 0 0 1.636 2.871h16.214a1.914 1.914 0 0 0 1.636 -2.87l-8.106 -13.536a1.914 1.914 0 0 0 -3.274 0z" /><path d="M12 16h.01" /></svg> ${window.trans.out_of_stock || 'Out of Stock'}
                            </span>`);
                        }
                    } else {
                        variationStock.html(`<span class="badge bg-green-lt">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="me-1"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M12 3l8 4.5l0 9l-8 4.5l-8 -4.5l0 -9l8 -4.5" /><path d="M12 12l8 -4.5" /><path d="M12 12l0 9" /><path d="M12 12l-8 -4.5" /></svg> ${window.trans.in_stock || 'In Stock'}
                        </span>`);
                    }

                    variationInfo.removeClass('d-none');
                } else {
                    if (allSelected) {
                        variationInfo.addClass('d-none');
                    }
                }
            },
            error: function(xhr) {
                Botble.handleError(xhr);
                variationInfo.addClass('d-none');
            }
        });

        if (!Object.keys(selectedAttributes).length) {
            variationInfo.addClass('d-none');
        }
    });

    // Function to update available attributes based on current selection
    function updateAvailableAttributes(form, availableAttributes, selectedAttributes) {
        // For each attribute set
        form.find('.attribute-swatches-wrapper').each(function() {
            const setId = $(this).find('.variation-select').data('attribute-id') ||
                          $(this).find('input[type="radio"]').first().data('attribute-id');

            // Skip the set that was just selected
            if (selectedAttributes[setId]) {
                return;
            }

            // If we have available attributes for this set
            if (availableAttributes[setId]) {
                const availableIds = availableAttributes[setId];

                // For dropdown selects
                $(this).find('select.variation-select option').each(function() {
                    const attrId = $(this).attr('value');
                    if (attrId && !availableIds.includes(parseInt(attrId))) {
                        $(this).prop('disabled', true);
                    } else {
                        $(this).prop('disabled', false);
                    }
                });

                // For visual/text swatches
                $(this).find('.attribute-swatch-item').each(function() {
                    const attrId = $(this).find('input[type="radio"]').val();
                    if (attrId && !availableIds.includes(parseInt(attrId))) {
                        $(this).addClass('disabled');
                        $(this).find('input[type="radio"]').prop('disabled', true);
                    } else {
                        $(this).removeClass('disabled');
                        $(this).find('input[type="radio"]').prop('disabled', false);
                    }
                });
            }
        });
    }
});
