@extends(BaseHelper::getAdminMasterLayoutTemplate())

@section('content')
    <div class="max-w-3xl mx-auto">

        {{-- QuickBooks Card --}}
        <div class="my-3 d-block d-md-flex">
            <div class="col-12 col-md-3">
                {{-- Page Title --}}
                <div class="mb-4">
                    <h2 class="text-2xl font-bold">QuickBooks Settings</h2>
                    <p class="text-muted">Manage QuickBooks connection settings</p>
                </div>
            </div>
            <div class="col-12 col-md-9">
                <div class="card mb-4">
                    <div class="card-header">
                        <h4>QuickBooks Connection</h4>
                    </div>

                    <div class="card-body">

                        {{-- Success Message --}}
                        @if (session('success'))
                            <div class="alert alert-success">{{ session('success') }}</div>
                        @endif

                        {{-- Description Text --}}
                        <p class="text-muted mb-3">
                            • Connect: You will be redirected to QuickBooks authorization page<br>
                            • Disconnect: Application will stop sending data to QuickBooks
                        </p>

                        @if (!$tokenExists)
                            {{-- SHOW CONNECT BUTTON --}}
                            <a href="{{ route('quickbooks.connect') }}" class="btn btn-primary">
                                Connect to QuickBooks
                            </a>
                        @else
                            {{-- SHOW DISCONNECT BUTTON --}}
                            <p class="text-success mb-2"><strong>QuickBooks is connected</strong></p>

                            <a href="{{ route('quickbooks.disconnect') }}" class="btn btn-danger mb-4">
                                Disconnect QuickBooks
                            </a>

                            {{-- ⭐ SALES RECEIPT DELETE OPTIONS --}}
                            <form action="{{ route('quickbooks.settings.update') }}" method="POST">
                                @csrf

                                <div class="form-group mb-3">
                                    <label class="font-weight-bold">Sales Receipt Delete in QuickBooks:</label>

                                    @php
                                        $deleteSetting = setting('quickbooks_sales_receipt_delete', 0);
                                    @endphp

                                    <div class="mt-2">
                                        <label class="mr-3">
                                            <input type="radio" name="quickbooks_sales_receipt_delete" value="1"
                                                {{ $deleteSetting == 1 ? 'checked' : '' }}> Yes
                                        </label>

                                        <label>
                                            <input type="radio" name="quickbooks_sales_receipt_delete" value="0"
                                                {{ $deleteSetting == 0 ? 'checked' : '' }}> No
                                        </label>
                                    </div>
                                </div>

                                <button type="submit" class="btn btn-success">Save Settings</button>
                            </form>

                           @if ($companyDetails)
                                <div class="mb-3 mt-4">
                                    <h4>QuickBooks Company Details</h4>
                                    <p><strong>Environment:</strong> {{ ucfirst($companyDetails['environment'] ?? '-') }}</p>
                                    <pre>{{ json_encode($companyDetails['company'], JSON_PRETTY_PRINT) }}</pre>
                                    <p><strong>Total Customers:</strong> {{ $companyDetails['total_customers'] ?? 0 }}</p>
                                </div>
                            @endif

                        @endif

                    </div>
                </div>
                {{-- ⭐ QuickBooks Working Process Documentation --}}
                <div class="card mt-4">
                    <div class="card-header">
                        <h4>QuickBooks Integration - Working Process</h4>
                    </div>
                    <div class="card-body">
                        <ol class="pl-3">
                            <li>Run <code>composer require quickbooks/v3-php-sdk</code> to install the QuickBooks PHP SDK.</li>
                            <li>Login to your QuickBooks account and create a new App.</li>
                            <li>Add the <strong>Client ID</strong>, <strong>Client Secret</strong>, and <strong>Callback URL</strong> from your App.</li>
                            <li>Activate the QuickBooks plugin in your application.</li>
                            <li>Run <code>php artisan vendor:publish --tag=public --force</code> to publish required CSS and JS assets.</li>
                            <li>Click <strong>Connect</strong> in the QuickBooks settings page to authorize your app with QuickBooks.</li>
                            <li>Once connected, your sales receipts will automatically be created in QuickBooks when triggered from your application.</li>
                            <li>If needed, you can disconnect the QuickBooks account from the settings page, which will stop sending data.</li>
                        </ol>
                    </div>
                </div>
                
            </div>
        </div>

        
    </div>
@endsection
