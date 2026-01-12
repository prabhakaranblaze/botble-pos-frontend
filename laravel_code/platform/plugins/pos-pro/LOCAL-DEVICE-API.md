# Local Device API Integration

This feature allows the POS Pro plugin to automatically send order data to local hardware devices (such as receipt printers or payment terminals) after an order is completed.

## How It Works

1. **User Configuration**: Each user can configure their local device settings in their profile
2. **Order Detection**: The system automatically detects POS orders based on payment methods (`pos_cash`, `pos_card`, `pos_other`)
3. **API Call**: After order completion, the system sends a POST request to the configured device IP
4. **Error Handling**: Failed requests are logged but don't interrupt the order process

## Database Structure

The feature uses a dedicated `pos_device_configs` table with the following structure:
- `user_id`: Links to the user who owns the device configuration
- `device_ip`: The IP address of the local device
- `device_name`: Optional friendly name for the device
- `is_active`: Whether the device configuration is active

## Setup Instructions

### 1. Configure Device Settings

1. Go to **Admin Panel** → **POS** → **POS Devices**
2. Click **Add New Device** to create a device configuration
3. Fill in the form with these fields:
   - **User**: Select the user who will use this device
   - **POS Device IP Address**: Enter your local device IP (e.g., `192.168.1.100`)
   - **Device Name**: Optional name to identify your device (e.g., "Receipt Printer")
   - **Device Active**: Enable/disable sending data to this device
4. Save the configuration

### 2. Device Requirements

Your local device should:
- Be accessible on the local network
- Accept POST requests at `http://{device_ip}/api`
- Handle JSON payload with order data

### 3. API Payload Format

The system sends the following JSON structure:

```json
{
  "order_id": 123,
  "order_code": "POS-2025-001",
  "total_amount": 150.00,
  "sub_total": 130.00,
  "tax_amount": 15.00,
  "discount_amount": 5.00,
  "payment_method": "pos_cash",
  "payment_status": "pending",
  "status": "pending",
  "notes": "Customer notes",
  "created_at": "2025-01-15T10:30:00.000Z",
  "customer": {
    "name": "John Doe",
    "phone": "+1234567890",
    "email": "john@example.com"
  },
  "items": [
    {
      "product_id": 1,
      "product_name": "Product Name",
      "sku": "SKU123",
      "quantity": 2,
      "price": 65.00,
      "tax_amount": 7.50,
      "options": {}
    }
  ]
}
```

## Security Features

- **IP Validation**: Only private IP ranges are allowed (192.168.x.x, 10.x.x.x, 172.16-31.x.x, 127.x.x.x)
- **Timeout Protection**: Requests timeout after 3 seconds to prevent delays
- **Error Isolation**: Device failures don't affect order processing

## Testing

Use the test command to verify your setup:

```bash
php artisan pos:test-local-device {user_id} {order_id}
```

Example:
```bash
php artisan pos:test-local-device 1 123
```

## Troubleshooting

### Common Issues

1. **Device not receiving requests**
   - Check if the device IP is correct
   - Verify the device is on the same network
   - Ensure the device accepts POST requests at `/api`

2. **Invalid IP error**
   - Only private IP addresses are allowed
   - Format must be valid IPv4 (e.g., 192.168.1.100)

3. **Timeout errors**
   - Check network connectivity
   - Ensure device responds within 3 seconds

### Logs

Check Laravel logs for API call results:
```bash
tail -f storage/logs/laravel.log | grep "local device"
```

## Example Device Implementation

Here's a simple Python Flask server example for testing:

```python
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/api', methods=['POST'])
def receive_order():
    order_data = request.get_json()
    print(f"Received order: {order_data['order_code']}")
    print(f"Total: {order_data['total_amount']}")

    # Process the order data here
    # (print receipt, update terminal, etc.)

    return jsonify({"status": "success", "message": "Order received"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
```

## Configuration Options

The feature includes these built-in configurations:
- **Timeout**: 3 seconds (with 2 second connection timeout)
- **Retry**: 1 retry attempt after 1 second
- **IP Validation**: Private ranges only
- **Logging**: All attempts are logged

## Support

For issues or questions about this feature, check the Laravel logs and ensure your local device meets the requirements above.
