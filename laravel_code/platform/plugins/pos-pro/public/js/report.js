$(document).ready(function () {
    'use strict';

    // ─── Date Range Picker ──────────────────────────────────────────────
    if (jQuery().daterangepicker && window.moment) {
        let $dateRange = $('.date-range-picker');

        if ($dateRange.length) {
            let dateFormat = $dateRange.data('format') || 'YYYY-MM-DD';

            let startDate = $dateRange.data('start-date')
                ? moment($dateRange.data('start-date'))
                : moment().startOf('month');

            let endDate = $dateRange.data('end-date')
                ? moment($dateRange.data('end-date'))
                : moment();

            let ranges = {
                'Today': [moment(), moment()],
                'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
                'Last 7 Days': [moment().subtract(6, 'days'), moment()],
                'Last 30 Days': [moment().subtract(29, 'days'), moment()],
                'This Month': [moment().startOf('month'), moment().endOf('month')],
                'Last Month': [
                    moment().subtract(1, 'month').startOf('month'),
                    moment().subtract(1, 'month').endOf('month')
                ]
            };

            $dateRange.daterangepicker({
                ranges: ranges,
                alwaysShowCalendars: true,
                startDate: startDate,
                endDate: endDate,
                opens: 'left',
                drops: 'auto',
                locale: {
                    format: dateFormat
                }
            });

            // On date change: preserve filter params and redirect
            $dateRange.on('apply.daterangepicker', function (ev, picker) {
                const url = new URL(window.location.href);
                url.searchParams.set('start_date', picker.startDate.format('YYYY-MM-DD'));
                url.searchParams.set('end_date', picker.endDate.format('YYYY-MM-DD'));
                // Clear session selections on date change (they're date-dependent)
                url.searchParams.delete('session_ids[]');
                window.location.href = url.toString();
            });

            // Update button text
            $dateRange.on('show.daterangepicker', function () {
                let formatValue = $(this).data('format-value') || '__from__ - __to__';

                let value = formatValue
                    .replace('__from__', startDate.format(dateFormat))
                    .replace('__to__', endDate.format(dateFormat));

                $(this).find('span').text(value);
            });
        }
    }

    // ─── Cascading Multi-Select Filters ─────────────────────────────────
    const $container = $('#report-stats-content');
    if (!$container.length) return;

    const filtersUrl = $container.data('filters-url');
    const currentStartDate = $container.data('start-date');
    const currentEndDate = $container.data('end-date');
    const selectedStoreIds = ($container.data('store-ids') || []).map(String);
    const selectedUserIds = ($container.data('user-ids') || []).map(String);
    const selectedSessionIds = ($container.data('session-ids') || []).map(String);

    const $storeSelect = $('#filter-store');
    const $userSelect = $('#filter-user');
    const $sessionSelect = $('#filter-session');

    /**
     * Populate a <select> with options, restoring previously selected values.
     */
    function populateSelect($select, items, preselected, valueKey, labelKey) {
        $select.empty();

        items.forEach(function (item) {
            const val = String(item[valueKey]);
            const label = item[labelKey];
            const selected = preselected.includes(val) ? ' selected' : '';
            $select.append('<option value="' + val + '"' + selected + '>' + label + '</option>');
        });
    }

    /**
     * Get currently selected values from a <select multiple>.
     */
    function getSelectedValues($select) {
        const val = $select.val();
        if (!val) return [];
        return Array.isArray(val) ? val : [val];
    }

    /**
     * Fetch filter dropdown data from the AJAX endpoint.
     * @param {Object} options
     *   - storeIds: array of store ids to send
     *   - userIds: array of user ids to send
     *   - reloadStores: bool (default true)
     *   - reloadUsers: bool (default true)
     *   - preselectStores: array of ids to pre-select (only on initial load)
     *   - preselectUsers: array of ids to pre-select (only on initial load)
     *   - preselectSessions: array of ids to pre-select (only on initial load)
     */
    function loadFilters(options) {
        options = options || {};

        const params = new URLSearchParams();
        params.set('start_date', currentStartDate);
        params.set('end_date', currentEndDate);

        const storeVals = options.storeIds || getSelectedValues($storeSelect);
        storeVals.forEach(function (v) { params.append('store_ids[]', v); });

        const userVals = options.userIds || getSelectedValues($userSelect);
        userVals.forEach(function (v) { params.append('user_ids[]', v); });

        $.ajax({
            url: filtersUrl + '?' + params.toString(),
            type: 'GET',
            dataType: 'json',
            success: function (data) {
                if (options.reloadStores !== false) {
                    populateSelect(
                        $storeSelect, data.stores,
                        options.preselectStores || [],
                        'id', 'name'
                    );
                }

                if (options.reloadUsers !== false) {
                    populateSelect(
                        $userSelect, data.users,
                        options.preselectUsers || [],
                        'id', 'name'
                    );
                }

                populateSelect(
                    $sessionSelect, data.sessions,
                    options.preselectSessions || [],
                    'id', 'label'
                );
            },
            error: function (xhr) {
                console.error('Failed to load report filters:', xhr.responseText);
            }
        });
    }

    // ─── Cascade Event Handlers ─────────────────────────────────────────

    // Store changed → reload users + sessions, clear downstream
    $storeSelect.on('change', function () {
        $userSelect.val([]);
        $sessionSelect.val([]);
        loadFilters({
            storeIds: getSelectedValues($storeSelect),
            userIds: [],
            reloadStores: false,
            reloadUsers: true
        });
    });

    // User changed → reload sessions only, clear sessions
    $userSelect.on('change', function () {
        $sessionSelect.val([]);
        loadFilters({
            storeIds: getSelectedValues($storeSelect),
            userIds: getSelectedValues($userSelect),
            reloadStores: false,
            reloadUsers: false
        });
    });

    // ─── Initial Load ───────────────────────────────────────────────────
    loadFilters({
        storeIds: selectedStoreIds,
        userIds: selectedUserIds,
        preselectStores: selectedStoreIds,
        preselectUsers: selectedUserIds,
        preselectSessions: selectedSessionIds
    });
});
