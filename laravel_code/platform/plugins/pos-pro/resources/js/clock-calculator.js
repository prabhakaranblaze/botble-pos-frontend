'use strict';

(function () {
    // Clock functionality
    function updateClock() {
        const now = new Date();
        const timeString = now.toLocaleTimeString([], {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });

        const clockElement = document.getElementById('pos-clock-time');
        const clockElementMobile = document.getElementById('pos-clock-time-mobile');

        if (clockElement) {
            clockElement.textContent = timeString;
        }
        if (clockElementMobile) {
            clockElementMobile.textContent = timeString;
        }
    }

    // Initialize clock
    updateClock();
    setInterval(updateClock, 1000);

    // macOS-style Calculator
    const calculator = {
        displayValue: '0',
        firstOperand: null,
        waitingForSecondOperand: false,
        operator: null,

        init: function () {
            this.bindEvents();
            this.resetOnModalOpen();
        },

        bindEvents: function () {
            document.querySelectorAll('[data-calc]').forEach(button => {
                button.addEventListener('click', (e) => {
                    const action = e.currentTarget.dataset.calc;

                    switch (action) {
                        case 'num':
                            this.inputDigit(e.currentTarget.dataset.num);
                            break;
                        case 'op':
                            this.handleOperator(e.currentTarget.dataset.op);
                            break;
                        case 'equals':
                            this.handleOperator('=');
                            break;
                        case 'clear':
                            this.clear();
                            break;
                        case 'negate':
                            this.negate();
                            break;
                        case 'percent':
                            this.percent();
                            break;
                    }
                });
            });

            // Keyboard support
            document.addEventListener('keydown', (e) => {
                const modal = document.getElementById('calculator-modal');
                if (!modal || !modal.classList.contains('show')) return;

                if (e.key >= '0' && e.key <= '9') {
                    this.inputDigit(e.key);
                } else if (e.key === '.') {
                    this.inputDigit('.');
                } else if (e.key === '+') {
                    this.handleOperator('+');
                } else if (e.key === '-') {
                    this.handleOperator('-');
                } else if (e.key === '*') {
                    this.handleOperator('*');
                } else if (e.key === '/') {
                    e.preventDefault();
                    this.handleOperator('/');
                } else if (e.key === 'Enter' || e.key === '=') {
                    e.preventDefault();
                    this.handleOperator('=');
                } else if (e.key === 'Escape' || e.key === 'c' || e.key === 'C') {
                    this.clear();
                } else if (e.key === 'Backspace') {
                    this.backspace();
                } else if (e.key === '%') {
                    this.percent();
                }
            });
        },

        resetOnModalOpen: function () {
            const modal = document.getElementById('calculator-modal');
            if (modal) {
                modal.addEventListener('show.bs.modal', () => {
                    this.clear();
                });
            }
        },

        inputDigit: function (digit) {
            if (this.waitingForSecondOperand) {
                this.displayValue = digit === '.' ? '0.' : digit;
                this.waitingForSecondOperand = false;
            } else {
                if (digit === '.') {
                    if (this.displayValue.includes('.')) return;
                    this.displayValue += '.';
                } else {
                    this.displayValue = this.displayValue === '0' ? digit : this.displayValue + digit;
                }
            }
            this.updateDisplay();
        },

        handleOperator: function (nextOperator) {
            const inputValue = parseFloat(this.displayValue);

            if (this.operator && this.waitingForSecondOperand) {
                this.operator = nextOperator;
                this.updateOperatorHighlight(nextOperator);
                return;
            }

            if (this.firstOperand === null && !isNaN(inputValue)) {
                this.firstOperand = inputValue;
            } else if (this.operator) {
                const result = this.calculate(this.firstOperand, inputValue, this.operator);
                this.displayValue = this.formatResult(result);
                this.firstOperand = result;
            }

            this.waitingForSecondOperand = true;
            this.operator = nextOperator === '=' ? null : nextOperator;
            this.updateOperatorHighlight(nextOperator);
            this.updateDisplay();
        },

        calculate: function (first, second, operator) {
            switch (operator) {
                case '+': return first + second;
                case '-': return first - second;
                case '*': return first * second;
                case '/': return second !== 0 ? first / second : 'Error';
                default: return second;
            }
        },

        formatResult: function (result) {
            if (result === 'Error' || isNaN(result) || !isFinite(result)) {
                return 'Error';
            }
            // Format to avoid floating point issues
            const formatted = parseFloat(result.toPrecision(12));
            return String(formatted);
        },

        clear: function () {
            this.displayValue = '0';
            this.firstOperand = null;
            this.waitingForSecondOperand = false;
            this.operator = null;
            this.updateOperatorHighlight(null);
            this.updateDisplay();
        },

        backspace: function () {
            if (this.waitingForSecondOperand) return;
            this.displayValue = this.displayValue.length > 1
                ? this.displayValue.slice(0, -1)
                : '0';
            this.updateDisplay();
        },

        negate: function () {
            const value = parseFloat(this.displayValue);
            if (value !== 0) {
                this.displayValue = String(-value);
                this.updateDisplay();
            }
        },

        percent: function () {
            const value = parseFloat(this.displayValue);
            this.displayValue = String(value / 100);
            this.updateDisplay();
        },

        updateDisplay: function () {
            const displayElement = document.getElementById('calculator-display');
            if (displayElement) {
                let displayText = this.displayValue;
                // Format large numbers with commas
                if (displayText !== 'Error' && !isNaN(parseFloat(displayText))) {
                    const parts = displayText.split('.');
                    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',');
                    displayText = parts.join('.');
                }
                displayElement.textContent = displayText;

                // Adjust font size for long numbers
                if (displayText.length > 9) {
                    displayElement.style.fontSize = '2rem';
                } else if (displayText.length > 7) {
                    displayElement.style.fontSize = '2.5rem';
                } else {
                    displayElement.style.fontSize = '3rem';
                }
            }
        },

        updateOperatorHighlight: function (activeOp) {
            // Remove active class from all operators
            document.querySelectorAll('.calc-op').forEach(btn => {
                btn.classList.remove('active');
            });

            // Add active class to current operator
            if (activeOp && activeOp !== '=') {
                const opButton = document.querySelector(`[data-op="${activeOp}"]`);
                if (opButton) {
                    opButton.classList.add('active');
                }
            }
        }
    };

    // Initialize calculator when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => calculator.init());
    } else {
        calculator.init();
    }
})();
