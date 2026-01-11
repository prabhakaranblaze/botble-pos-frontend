$(document).ready(function () {
    'use strict';
    // Initialize date range picker
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

            // 🔥 MAIN FIX: Redirect with query params
            $dateRange.on('apply.daterangepicker', function (ev, picker) {
                const href = $(this).data('href');

                const start = picker.startDate.format('YYYY-MM-DD');
                const end = picker.endDate.format('YYYY-MM-DD');

                window.location.href = `${href}?start_date=${start}&end_date=${end}`;
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
});
