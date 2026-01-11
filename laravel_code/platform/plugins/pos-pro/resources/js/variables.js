// This file contains global variables and translations for the POS Pro plugin
// It will be populated by the Blade templates with the necessary data

// Initialize BotbleVariables for notifications if it doesn't exist
window.BotbleVariables = window.BotbleVariables || {
    languages: {
        notices_msg: {
            success: '',
            error: '',
            info: '',
            warning: ''
        }
    }
};

// Set currency for formatting prices
window.currency = window.currency || 'USD';
