document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('license-activation-form')
    const deactivateBtn = document.getElementById('deactivate-license-btn')
    const toggleBtn = document.getElementById('toggle-purchase-code')

    if (form) {
        form.addEventListener('submit', function(e) {
            e.preventDefault()

            const btn = document.getElementById('activate-license-btn')
            const spinner = btn.querySelector('.spinner-border')
            const formData = new FormData(form)

            // Show loading state
            btn.disabled = true
            spinner.classList.remove('d-none')

            fetch(form.dataset.action, {
                method: 'POST',
                body: formData,
                headers: {
                    'X-CSRF-TOKEN': document.querySelector('meta[name=csrf-token]').content,
                    'X-Requested-With': 'XMLHttpRequest',
                },
            })
                .then(response => response.json())
                .then(data => {
                    if (data.error) {
                        Botble.showError(data.message)
                    } else {
                        Botble.showSuccess(data.message)
                        setTimeout(() => {
                            window.location.reload()
                        }, 1000)
                    }
                })
                .catch(error => {
                    console.error('License activation error:', error)
                    Botble.showError(getTranslation('somethingWentWrong'))
                })
                .finally(() => {
                    btn.disabled = false
                    spinner.classList.add('d-none')
                })
        })
    }

    if (deactivateBtn) {
        deactivateBtn.addEventListener('click', function() {
            if (confirm(getTranslation('deactivateLicenseConfirm'))) {
                const btn = this
                btn.disabled = true

                // Get deactivate URL from the form's data attribute or construct it
                const deactivateUrl = document.querySelector('[data-deactivate-url]')?.dataset.deactivateUrl ||
                    window.location.pathname + '/deactivate'

                fetch(deactivateUrl, {
                    method: 'POST',
                    headers: {
                        'X-CSRF-TOKEN': document.querySelector('meta[name=csrf-token]').content,
                        'X-Requested-With': 'XMLHttpRequest',
                    },
                })
                    .then(response => response.json())
                    .then(data => {
                        if (data.error) {
                            Botble.showError(data.message)
                        } else {
                            Botble.showSuccess(data.message)
                            setTimeout(() => {
                                window.location.reload()
                            }, 1000)
                        }
                    })
                    .catch(error => {
                        console.error('License deactivation error:', error)
                        Botble.showError(getTranslation('somethingWentWrong'))
                    })
                    .finally(() => {
                        btn.disabled = false
                    })
            }
        })
    }

    // Toggle purchase code visibility - only if we're on the license page
    if (toggleBtn && window.location.pathname.includes('/license')) {
        let isVisible = false

        toggleBtn.addEventListener('click', function(e) {
            e.preventDefault()
            e.stopPropagation()

            try {
                const display = document.getElementById('purchase-code-display')
                const showIcon = document.getElementById('show-icon')
                const hideIcon = document.getElementById('hide-icon')

                // Check if all required elements exist
                if (!display || !showIcon || !hideIcon) {
                    console.warn('License toggle elements not found:', {
                        display: !!display,
                        showIcon: !!showIcon,
                        hideIcon: !!hideIcon,
                    })
                    return
                }

                // Ensure we have the required data attributes
                if (!this.dataset.fullCode || !this.dataset.maskedCode) {
                    console.warn('License toggle missing data attributes')
                    return
                }

                if (!isVisible) {
                    // Show full code
                    display.textContent = this.dataset.fullCode
                    if (showIcon) showIcon.style.display = 'none'
                    if (hideIcon) hideIcon.style.display = 'inline'
                    this.title = getTranslation('hidePurchaseCode')
                    isVisible = true
                } else {
                    // Show masked code
                    display.textContent = this.dataset.maskedCode
                    if (showIcon) showIcon.style.display = 'inline'
                    if (hideIcon) hideIcon.style.display = 'none'
                    this.title = getTranslation('showPurchaseCode')
                    isVisible = false
                }
            } catch (error) {
                console.error('Error in license toggle:', error)
            }
        })
    }

    /**
     * Get translation text
     * @param {string} key - Translation key
     * @returns {string} - Translated text
     */
    function getTranslation(key) {
        return window.posTranslations?.[key] || key
    }
})
