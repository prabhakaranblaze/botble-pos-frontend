@extends(BaseHelper::getAdminMasterLayoutTemplate())

@section('content')

{{-- View Toggle Buttons --}}
<div class="mb-3">
    <button id="btn-list-view" class="btn btn-primary">List View</button>
    <button id="btn-nested-view" class="btn btn-secondary">Nested View</button>
</div>

{{-- LIST VIEW --}}
<div id="list-view-container">
    {{-- renderTable(true) ensures scripts are included --}}
    {!! $dataTable->renderTable([], ['render_script' => true]) !!}
</div>

{{-- NESTED VIEW --}}
<div id="nested-view-container" style="display:none;">
    <div class="card">
        <div class="card-body">
            <h4 class="mb-3">Nested Accounts View</h4>
            <ul class="list-group">
                <li class="list-group-item">
                    Assets
                    <ul>
                        <li>Cash</li>
                        <li>Bank</li>
                    </ul>
                </li>
                <li class="list-group-item">
                    Liabilities
                    <ul>
                        <li>Credit Card</li>
                    </ul>
                </li>
            </ul>
        </div>
    </div>
</div>

@endsection

@section('footer')
<script>
document.addEventListener('DOMContentLoaded', function () {
    const listBtn = document.getElementById('btn-list-view');
    const nestedBtn = document.getElementById('btn-nested-view');

    const listView = document.getElementById('list-view-container');
    const nestedView = document.getElementById('nested-view-container');

    // Toggle to List View
    listBtn.addEventListener('click', function (e) {
        e.preventDefault();
        listView.style.display = 'block';
        nestedView.style.display = 'none';
    });

    // Toggle to Nested View
    nestedBtn.addEventListener('click', function (e) {
        e.preventDefault();
        listView.style.display = 'none';
        nestedView.style.display = 'block';
    });
});
</script>
@endsection
