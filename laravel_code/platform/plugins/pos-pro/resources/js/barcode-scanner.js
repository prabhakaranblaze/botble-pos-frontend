'use strict';

/**
 * Barcode Scanner for POS Pro
 *
 * This module provides barcode scanning functionality for the POS Pro plugin.
 * It supports both camera-based scanning and hardware barcode scanner input.
 */

import { BrowserMultiFormatReader } from '@zxing/library';

class BarcodeScanner {
    constructor() {
        // Check if MediaDevices API is supported
        this.cameraSupported = !!(navigator && navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
        this.cameraPermissionGranted = false;
        this.cameraPermissionDenied = false;

        // Only initialize the reader if camera is supported
        if (this.cameraSupported) {
            try {
                // Create a new reader with default settings
                // The UMD version of ZXing automatically supports all formats
                this.reader = new BrowserMultiFormatReader();

                // Enable more aggressive scanning for better results
                try {
                    // Try to set hints if the API supports it
                    if (this.reader.hints) {
                        // Set hints for better performance
                        this.reader.hints.set(
                            DecodeHintType.TRY_HARDER,
                            true
                        );
                    }
                } catch (e) {
                    // Ignore if hints API is not available
                }

                // Set debug mode for development
                this.debugMode = false;
            } catch (error) {
                console.error('Error initializing barcode reader:', error);
                this.cameraSupported = false;
            }
        } else {
            // Camera API not supported in this browser. Using hardware scanner mode only.
        }

        this.isScanning = false;
        this.selectedDeviceId = null;
        this.videoElement = null;
        this.scannerContainer = null;
        this.availableDevices = [];
        this.onDetectedCallback = null;
        this.hardwareInputBuffer = '';
        this.hardwareInputTimeout = null;
        this.hardwareScannerEnabled = true;
        this.lastScanTime = 0;
        this.scanCooldown = 1500; // 1.5 seconds cooldown between scans
    }

    /**
     * Check camera permission
     * @returns {Promise<boolean>} Promise that resolves to true if permission is granted
     */
    async checkCameraPermission() {
        if (!this.cameraSupported) {
            return false;
        }

        // If we already know the permission state, return it
        if (this.cameraPermissionGranted) {
            return true;
        }
        if (this.cameraPermissionDenied) {
            return false;
        }

        try {
            // Try to access the camera to trigger the permission prompt
            const stream = await navigator.mediaDevices.getUserMedia({ video: true });

            // If we get here, permission was granted
            this.cameraPermissionGranted = true;

            // Stop the stream since we're just checking permission
            stream.getTracks().forEach(track => track.stop());

            return true;
        } catch (error) {
            console.error('Camera permission denied or error:', error);
            this.cameraPermissionDenied = true;
            return false;
        }
    }

    /**
     * Initialize the barcode scanner
     * @param {Object} options Configuration options
     * @param {Function} options.onDetected Callback function when a barcode is detected
     * @param {boolean} options.enableHardwareScanner Enable hardware barcode scanner support
     * @param {string} options.containerId ID of the container element for the scanner UI
     * @param {boolean} options.checkCameraOnInit Whether to check camera permission during initialization
     */
    init(options = {}) {
        this.onDetectedCallback = options.onDetected || this.defaultDetectionCallback;
        this.hardwareScannerEnabled = options.enableHardwareScanner !== false;
        this.scannerContainer = document.getElementById(options.containerId || 'barcode-scanner-container');
        this.checkCameraOnInit = options.checkCameraOnInit !== false; // Default to true for backward compatibility

        // Clear the container initially
        if (this.scannerContainer) {
            this.scannerContainer.innerHTML = '';
        }

        // Initialize hardware scanner support
        if (this.hardwareScannerEnabled) {
            this.initHardwareScanner();
        }

        return this;
    }

    /**
     * Prepare the scanner UI based on camera permission
     * @returns {Promise<boolean>} Promise that resolves to true if UI was created successfully
     */
    async prepareUI() {
        if (!this.scannerContainer) {
            return false;
        }

        // Clear the container
        this.scannerContainer.innerHTML = '';

        if (this.cameraSupported) {
            // Check camera permission
            const hasPermission = await this.checkCameraPermission();

            if (hasPermission) {
                // Create camera UI if camera is supported and permission is granted
                this.createScannerUI();
                return true;
            } else {
                // Show hardware scanner message if camera permission is denied
                this.createHardwareScannerUI('Camera permission denied. Please check your browser settings and reload the page.');
                return false;
            }
        } else {
            // Show hardware scanner message if camera is not supported
            this.createHardwareScannerUI('Camera access is not supported in this browser. Connect a USB barcode scanner or manually enter the barcode.');
            return false;
        }
    }

    /**
     * Create UI for hardware scanner mode
     * @param {string} customMessage Optional custom message to display
     */
    createHardwareScannerUI(customMessage) {
        // Clear container
        this.scannerContainer.innerHTML = '';

        // Create hardware scanner message
        const messageContainer = document.createElement('div');
        messageContainer.className = 'hardware-scanner-container';

        const icon = document.createElement('div');
        icon.className = 'hardware-scanner-icon';
        icon.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-primary"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M4 7v-1a2 2 0 0 1 2 -2h2" /><path d="M4 17v1a2 2 0 0 0 2 2h2" /><path d="M16 4h2a2 2 0 0 1 2 2v1" /><path d="M16 20h2a2 2 0 0 0 2 -2v-1" /><path d="M5 11h1v2h-1z" /><path d="M10 11l0 2" /><path d="M14 11h1v2h-1z" /><path d="M19 11l0 2" /></svg>';

        const title = document.createElement('h4');
        title.className = 'hardware-scanner-title';
        title.textContent = 'Hardware Barcode Scanner Mode';

        const message = document.createElement('p');
        message.className = 'hardware-scanner-message';
        message.textContent = customMessage || 'Camera access is not available. Connect a USB barcode scanner or manually enter the barcode.';

        // Add permission button if we're in permission denied state
        if (this.cameraPermissionDenied && this.cameraSupported) {
            const permissionBtn = document.createElement('button');
            permissionBtn.className = 'btn btn-outline-primary mb-3';
            permissionBtn.textContent = 'Request Camera Permission';
            permissionBtn.addEventListener('click', async () => {
                // Try to request permission again
                const hasPermission = await this.checkCameraPermission();
                if (hasPermission) {
                    // Recreate the scanner UI if permission is granted
                    this.createScannerUI();
                } else {
                    // Show instructions to reset permissions
                    message.innerHTML = 'Camera permission is still denied. Please check your browser settings:<br>' +
                        '1. Click the lock/info icon in your browser\'s address bar<br>' +
                        '2. Find camera permissions and allow access<br>' +
                        '3. Reload the page';
                }
            });
            messageContainer.appendChild(permissionBtn);
        }

        const inputGroup = document.createElement('div');
        inputGroup.className = 'input-group mb-3';

        const input = document.createElement('input');
        input.type = 'text';
        input.className = 'form-control';
        input.id = 'manual-barcode-input';
        input.placeholder = 'Enter barcode manually...';

        const button = document.createElement('button');
        button.className = 'btn btn-primary';
        button.type = 'button';
        button.textContent = 'Search';
        button.addEventListener('click', () => {
            const barcode = input.value.trim();
            if (barcode) {
                this.onDetectedCallback(barcode);
                input.value = '';
            }
        });

        // Handle Enter key press
        input.addEventListener('keypress', (event) => {
            if (event.key === 'Enter') {
                const barcode = input.value.trim();
                if (barcode) {
                    this.onDetectedCallback(barcode);
                    input.value = '';
                    event.preventDefault();
                }
            }
        });

        inputGroup.appendChild(input);
        inputGroup.appendChild(button);

        messageContainer.appendChild(icon);
        messageContainer.appendChild(title);
        messageContainer.appendChild(message);
        messageContainer.appendChild(inputGroup);

        this.scannerContainer.appendChild(messageContainer);

        // Focus on the input field
        setTimeout(() => {
            input.focus();
        }, 100);
    }

    /**
     * Create the scanner UI elements
     */
    createScannerUI() {
        // Create video element for camera feed
        this.videoElement = document.createElement('video');
        this.videoElement.id = 'barcode-scanner-video';
        this.videoElement.className = 'barcode-scanner-video';

        // Create device selection dropdown
        const deviceSelect = document.createElement('select');
        deviceSelect.id = 'barcode-scanner-devices';
        deviceSelect.className = 'form-select mt-2';
        deviceSelect.addEventListener('change', (event) => {
            this.selectedDeviceId = event.target.value;
            if (this.isScanning) {
                this.stopScan().then(() => this.startScan());
            }
        });

        // Create scanner overlay with scanning line and guide
        const overlay = document.createElement('div');
        overlay.className = 'barcode-scanner-overlay';

        // Add scanning line
        const scanLine = document.createElement('div');
        scanLine.className = 'barcode-scanner-line';
        overlay.appendChild(scanLine);

        // Add scanning guide (target box)
        const scanGuide = document.createElement('div');
        scanGuide.className = 'barcode-scanner-guide';
        overlay.appendChild(scanGuide);

        // Add scanning status message
        const statusMessage = document.createElement('div');
        statusMessage.className = 'barcode-scanner-status';
        statusMessage.id = 'barcode-scanner-status';
        statusMessage.textContent = 'Position barcode within the box';
        overlay.appendChild(statusMessage);

        // Add debug info container (hidden by default)
        const debugInfo = document.createElement('div');
        debugInfo.className = 'barcode-scanner-debug';
        debugInfo.id = 'barcode-scanner-debug';
        debugInfo.style.display = this.debugMode ? 'block' : 'none';
        overlay.appendChild(debugInfo);

        // Add toggle button for debug mode
        const debugToggle = document.createElement('button');
        debugToggle.className = 'btn btn-sm btn-outline-secondary mt-2 me-2';
        debugToggle.textContent = 'Toggle Debug';
        debugToggle.addEventListener('click', () => {
            this.debugMode = !this.debugMode;
            debugInfo.style.display = this.debugMode ? 'block' : 'none';
        });

        // Add elements to container
        this.scannerContainer.innerHTML = '';
        this.scannerContainer.appendChild(this.videoElement);
        this.scannerContainer.appendChild(overlay);

        // Add controls container
        const controlsContainer = document.createElement('div');
        controlsContainer.className = 'd-flex align-items-center mt-2';

        // Add the debug toggle button to controls
        controlsContainer.appendChild(debugToggle);

        // Add the device select to controls
        controlsContainer.appendChild(deviceSelect);

        // Add controls to container
        this.scannerContainer.appendChild(controlsContainer);

        // Get available camera devices
        this.getVideoDevices();
    }

    /**
     * Get available video input devices
     */
    getVideoDevices() {
        const deviceSelect = document.getElementById('barcode-scanner-devices');
        if (!deviceSelect) return;

        // Check if mediaDevices API is supported
        if (!navigator.mediaDevices || !navigator.mediaDevices.enumerateDevices) {
            console.error('MediaDevices API not supported in this browser');

            // Add a default option
            const option = document.createElement('option');
            option.value = '';
            option.text = 'Default camera';
            deviceSelect.appendChild(option);

            // Add a message to the container
            if (this.scannerContainer) {
                const message = document.createElement('div');
                message.className = 'barcode-scanner-message';
                message.textContent = 'Your browser may not fully support camera access. Try using Chrome, Edge, or Safari for best results.';
                this.scannerContainer.appendChild(message);
            }

            return;
        }

        // Try to enumerate devices
        navigator.mediaDevices.enumerateDevices()
            .then((devices) => {
                this.availableDevices = devices.filter(device => device.kind === 'videoinput');

                // Clear existing options
                deviceSelect.innerHTML = '';

                if (this.availableDevices.length === 0) {
                    // No cameras found
                    const option = document.createElement('option');
                    option.value = '';
                    option.text = 'No cameras found';
                    deviceSelect.appendChild(option);

                    if (this.scannerContainer) {
                        const message = document.createElement('div');
                        message.className = 'barcode-scanner-message';
                        message.textContent = 'No cameras detected. Please connect a camera and refresh the page.';
                        this.scannerContainer.appendChild(message);
                    }
                } else {
                    // Add options for each device
                    this.availableDevices.forEach((device) => {
                        const option = document.createElement('option');
                        option.value = device.deviceId;
                        option.text = device.label || `Camera ${deviceSelect.length + 1}`;
                        deviceSelect.appendChild(option);
                    });

                    // Select the first device by default
                    this.selectedDeviceId = this.availableDevices[0].deviceId;
                }
            })
            .catch((error) => {
                console.error('Error getting video devices:', error);

                // Add a default option
                const option = document.createElement('option');
                option.value = '';
                option.text = 'Default camera';
                deviceSelect.appendChild(option);

                // Add an error message
                if (this.scannerContainer) {
                    const message = document.createElement('div');
                    message.className = 'barcode-scanner-message';
                    message.textContent = 'Could not access camera. Please check your browser permissions.';
                    this.scannerContainer.appendChild(message);
                }
            });
    }

    /**
     * Start the barcode scanner
     * @returns {Promise} Promise that resolves when scanning starts
     */
    async startScan() {
        if (this.isScanning) return Promise.resolve();

        // If camera is not supported, focus on the manual input field and return
        if (!this.cameraSupported) {
            const manualInput = document.getElementById('manual-barcode-input');
            if (manualInput) {
                setTimeout(() => manualInput.focus(), 100);
            }
            return Promise.resolve();
        }

        // Prepare UI based on camera permission
        const uiPrepared = await this.prepareUI();
        if (!uiPrepared) {
            // Focus on the manual input field if UI preparation failed
            const manualInput = document.getElementById('manual-barcode-input');
            if (manualInput) {
                setTimeout(() => manualInput.focus(), 100);
            }

            return Promise.reject(new Error('Camera permission denied'));
        }

        this.isScanning = true;

        const constraints = {
            video: {
                deviceId: this.selectedDeviceId ? { exact: this.selectedDeviceId } : undefined,
                width: { ideal: 1280 },
                height: { ideal: 720 },
                facingMode: 'environment'
            }
        };

        try {
            // Update status message
            const statusMessage = document.getElementById('barcode-scanner-status');
            if (statusMessage) {
                statusMessage.textContent = 'Ready to scan - position barcode within the box';
            }

            // Track consecutive errors for better user feedback
            let consecutiveErrors = 0;
            let lastErrorMessage = '';

            return this.reader.decodeFromConstraints(constraints, this.videoElement, (result, error) => {
                // Update debug info if debug mode is enabled
                if (this.debugMode) {
                    const debugInfo = document.getElementById('barcode-scanner-debug');
                    if (debugInfo) {
                        if (error) {
                            debugInfo.innerHTML = `Last error: ${error.message || 'Unknown error'}`;
                        } else {
                            debugInfo.innerHTML = 'Processing...';
                        }
                    }
                }

                if (result) {
                    // Reset error counter on successful scan
                    consecutiveErrors = 0;

                    // Update status message
                    if (statusMessage) {
                        statusMessage.textContent = 'Barcode detected!';
                        statusMessage.className = 'barcode-scanner-status success';

                        // Reset status after a delay
                        setTimeout(() => {
                            if (statusMessage) {
                                statusMessage.textContent = 'Ready to scan - position barcode within the box';
                                statusMessage.className = 'barcode-scanner-status';
                            }
                        }, 2000);
                    }

                    const currentTime = new Date().getTime();
                    // Check if enough time has passed since the last scan
                    if (currentTime - this.lastScanTime > this.scanCooldown) {
                        this.lastScanTime = currentTime;
                        this.onDetectedCallback(result.getText());
                    }
                }

                if (error) {
                    // Handle different types of errors
                    if (error.message && error.message.includes('No MultiFormat Readers were able to detect the code')) {
                        // This is a normal error when no barcode is detected
                        // Only show a message after several consecutive failures
                        consecutiveErrors++;

                        if (consecutiveErrors > 30 && statusMessage) {
                            // After about 3 seconds of failures, show a helpful message
                            if (lastErrorMessage !== 'detection-failed') {
                                statusMessage.textContent = 'No barcode detected. Try adjusting distance or angle.';
                                lastErrorMessage = 'detection-failed';
                            }
                        }
                    } else if (!(error instanceof TypeError)) {
                        // Log other errors to console
                        console.error('Barcode scanning error:', error);

                        if (statusMessage && lastErrorMessage !== error.message) {
                            statusMessage.textContent = 'Scanner error: ' + (error.message || 'Unknown error');
                            lastErrorMessage = error.message;
                        }
                    }
                }
            });
        } catch (error) {
            console.error('Error starting barcode scanner:', error);
            this.isScanning = false;

            // If there's an error starting the scanner, show the hardware scanner UI
            if (error.name === 'NotAllowedError') {
                // Permission denied
                this.cameraPermissionDenied = true;
                this.createHardwareScannerUI('Camera permission denied. Please check your browser settings and reload the page.');
            } else if (error.name === 'NotFoundError') {
                // No camera found
                this.createHardwareScannerUI('No camera found. Please connect a camera or use a hardware barcode scanner.');
            } else {
                // Other error
                this.createHardwareScannerUI('Error accessing camera: ' + error.message);
            }

            return Promise.reject(error);
        }
    }

    /**
     * Stop the barcode scanner
     * @returns {Promise} Promise that resolves when scanning stops
     */
    stopScan() {
        if (!this.isScanning) return Promise.resolve();

        this.isScanning = false;

        // If camera is not supported, just return resolved promise
        if (!this.cameraSupported || !this.reader) {
            return Promise.resolve();
        }

        return this.reader.reset();
    }

    /**
     * Initialize hardware barcode scanner support
     * This listens for rapid keyboard input which is typical of hardware scanners
     */
    initHardwareScanner() {
        document.addEventListener('keydown', (event) => {
            // Only process if hardware scanner is enabled
            if (!this.hardwareScannerEnabled) return;

            // Ignore modifier keys
            if (event.ctrlKey || event.altKey || event.metaKey) return;

            // Reset timeout on each keypress
            if (this.hardwareInputTimeout) {
                clearTimeout(this.hardwareInputTimeout);
            }

            // Handle Enter key as the end of barcode input
            if (event.key === 'Enter' && this.hardwareInputBuffer) {
                const barcode = this.hardwareInputBuffer.trim();
                if (barcode) {
                    const currentTime = new Date().getTime();
                    // Check if enough time has passed since the last scan
                    if (currentTime - this.lastScanTime > this.scanCooldown) {
                        this.lastScanTime = currentTime;
                        this.onDetectedCallback(barcode);
                    }
                }
                this.hardwareInputBuffer = '';
                // Prevent form submission if inside a form
                event.preventDefault();
                return;
            }

            // Add character to buffer
            if (event.key.length === 1) {
                this.hardwareInputBuffer += event.key;
            }

            // Set timeout to clear buffer if no more input is received
            this.hardwareInputTimeout = setTimeout(() => {
                this.hardwareInputBuffer = '';
            }, 100); // 100ms timeout is typical for barcode scanners
        });
    }

    /**
     * Default callback when a barcode is detected
     * @param {string} barcode The detected barcode
     */
    defaultDetectionCallback(barcode) {
        // Try to automatically add product to cart if barcode is unique
        const container = document.getElementById('pos-container');
        const scanBarcodeUrl = container ? container.dataset.scanBarcodeUrl : null;

        if (scanBarcodeUrl && window.$httpClient) {
            window.$httpClient.make()
                .post(scanBarcodeUrl, { barcode: barcode })
                .then((data) => {
                    if (data.error) {
                        // If barcode scan failed, fall back to regular search
                        this.fallbackToSearch(barcode);
                        if (window.Botble) {
                            window.Botble.showError(data.message || 'Product not found');
                        }
                    } else if (data.data.auto_added) {
                        // Product was automatically added to cart
                        if (window.updateCartDisplay) {
                            window.updateCartDisplay(data.data.cart);
                        }
                        if (window.Botble) {
                            window.Botble.showSuccess(data.data.message || 'Product added to cart');
                        }
                    } else if (data.data.has_variations) {
                        // Product has variations, show in search results for manual selection
                        this.fallbackToSearch(barcode);
                        if (window.Botble) {
                            window.Botble.showInfo(data.data.message || 'Product found - please select variation');
                        }
                    }
                })
                .catch((error) => {
                    // If API call fails, fall back to regular search
                    this.fallbackToSearch(barcode);
                    console.error('Barcode scan API error:', error);
                });
        } else {
            // Fallback to original behavior if no scan URL configured or $httpClient not available
            this.fallbackToSearch(barcode);
        }
    }

    /**
     * Fallback to regular search functionality
     * @param {string} barcode The barcode to search for
     */
    fallbackToSearch(barcode) {
        const searchInput = document.getElementById('search-product');
        if (searchInput) {
            searchInput.value = barcode;
            searchInput.dispatchEvent(new Event('keyup'));
        }
    }

    /**
     * Toggle the scanner on/off
     * @returns {Promise} Promise that resolves when the toggle is complete
     */
    toggle() {
        return this.isScanning ? this.stopScan() : this.startScan();
    }

    /**
     * Enable or disable hardware scanner support
     * @param {boolean} enable Whether to enable hardware scanner support
     */
    setHardwareScannerEnabled(enable) {
        this.hardwareScannerEnabled = enable;
    }
}

// Export as global and module
window.BarcodeScanner = new BarcodeScanner();
export default window.BarcodeScanner;
