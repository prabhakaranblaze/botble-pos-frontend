$(document).ready(function () {

    // Append modal HTML to body only once
    if (!$('#cronModal').length) {
        $('body').append(`
        <div class="modal fade" id="cronModal" tabindex="-1">
          <div class="modal-dialog modal-xl">
            <div class="modal-content">
              <div class="modal-header">
                <h5 class="modal-title">
                    <span id="cronPostUrl"></span>
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
              </div>
              <div class="modal-body">
                <ul class="nav nav-tabs">
                    <li class="nav-item">
                        <button class="nav-link active" data-bs-toggle="tab" data-bs-target="#reqTab">Request</button>
                    </li>
                    <li class="nav-item">
                        <button class="nav-link" data-bs-toggle="tab" data-bs-target="#resTab">Response</button>
                    </li>
                </ul>
                <div class="tab-content mt-3">
                    <div class="tab-pane fade show active" id="reqTab">
                        <pre id="cronRequest" style="padding:10px;border-radius:6px;"></pre>
                    </div>
                    <div class="tab-pane fade" id="resTab">
                        <pre id="cronResponse" style="padding:10px;border-radius:6px;"></pre>
                    </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        `);
    }

    // Click event to open modal
    $(document).on('click', '.show-cron-data', function () {
        var id = $(this).data('id');

        // AJAX call to get cron data
        $.get('/admin/quickbooks/cron/view', { id: id }, function (res) {
            console.log(res); // debug: check structure

            $('#cronPostUrl').text(res.post_url || 'N/A');

            // Handle payload safely
            var payloadData = res.payload;
            if (typeof payloadData === 'string') {
                try { payloadData = JSON.parse(payloadData); } catch(e) {}
            }
            $('#cronRequest').text(payloadData ? JSON.stringify(payloadData, null, 2) : 'No Payload Found');

            // Handle quickbook_response safely
            var responseData = res.quickbook_response;
            if (typeof responseData === 'string') {
                try { responseData = JSON.parse(responseData); } catch(e) {}
            }
            $('#cronResponse').text(responseData ? JSON.stringify(responseData, null, 2) : 'No Response Found');

            // Show modal
            $('#cronModal').modal('show');
        }).fail(function () {
            $('#cronPostUrl').text('Error');
            $('#cronRequest').text('Error loading data');
            $('#cronResponse').text('Error loading data');
            $('#cronModal').modal('show');
        });
    });

});
