/**
 * Responsive enhancements for POS Pro plugin
 */
(function($) {
    'use strict';

    // Improve checkout modal for mobile devices
    $(document).ready(function() {
        // Adjust modal size based on screen size
        $('#checkout-modal').on('show.bs.modal', function() {
            const isMobile = window.innerWidth < 768;
            
            if (isMobile) {
                // On mobile, make sure the modal is properly sized
                setTimeout(function() {
                    // Scroll to top of modal when opened on mobile
                    $('.modal-body').scrollTop(0);
                    
                    // Ensure the complete order button is visible
                    const completeOrderBtn = $('#complete-order-btn');
                    if (completeOrderBtn.length) {
                        completeOrderBtn.addClass('btn-lg');
                    }
                    
                    // Add mobile-friendly class to form elements
                    $('#checkout-modal .form-control, #checkout-modal .form-select, #checkout-modal .btn')
                        .addClass('mobile-friendly');
                    
                    // Adjust modal height to fit screen
                    const modalDialog = $('#checkout-modal .modal-dialog');
                    const windowHeight = window.innerHeight;
                    const modalHeight = modalDialog.height();
                    
                    if (modalHeight > windowHeight) {
                        modalDialog.css('margin-top', '0.5rem');
                        modalDialog.css('margin-bottom', '0.5rem');
                    }
                }, 300);
            }
        });

        // Handle orientation change
        window.addEventListener('orientationchange', function() {
            if ($('#checkout-modal').hasClass('show')) {
                // Adjust modal layout after orientation change
                setTimeout(function() {
                    $('.modal-body').scrollTop(0);
                    
                    // Re-adjust modal height
                    const modalDialog = $('#checkout-modal .modal-dialog');
                    const windowHeight = window.innerHeight;
                    const modalHeight = modalDialog.height();
                    
                    if (modalHeight > windowHeight) {
                        modalDialog.css('margin-top', '0.5rem');
                        modalDialog.css('margin-bottom', '0.5rem');
                    }
                }, 500);
            }
        });
        
        // Handle window resize
        $(window).on('resize', function() {
            if ($('#checkout-modal').hasClass('show')) {
                const isMobile = window.innerWidth < 768;
                
                if (isMobile) {
                    // Add mobile-friendly class to form elements
                    $('#checkout-modal .form-control, #checkout-modal .form-select, #checkout-modal .btn')
                        .addClass('mobile-friendly');
                } else {
                    // Remove mobile-friendly class on larger screens
                    $('#checkout-modal .form-control, #checkout-modal .form-select, #checkout-modal .btn')
                        .removeClass('mobile-friendly');
                }
            }
        });
    });

})(jQuery);
