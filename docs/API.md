# StampSmart POS API Documentation

Complete API reference for the StampSmart POS Desktop Application.

**Base URL:** `https://stampsmart.test/api/v1/pos`

---

## Table of Contents

- [Authentication](#authentication)
- [Products](#products)
- [Cart](#cart)
- [Customers](#customers)
- [Orders](#orders)
- [Sessions](#sessions)
- [Denominations](#denominations)

---

## Common Headers

All API requests require the following headers:

| Header | Value | Description |
|--------|-------|-------------|
| `Accept` | `application/json` | Response format |
| `Content-Type` | `application/json` | Request format |
| `X-API-KEY` | `your-api-key` | API authentication key |
| `Authorization` | `Bearer {token}` | JWT token (after login) |

---

## Response Format

All API responses follow this standard format:

### Success Response
```json
{
  "error": false,
  "message": "Success message",
  "data": { ... }
}
```

### Error Response
```json
{
  "error": true,
  "message": "Error description"
}
```

---

## Authentication

### POST /auth/login

Authenticate a user and receive an access token.

**Use Case:** User login from the POS terminal at the start of a shift.

**Request Body:**
```json
{
  "username": "admin@example.com",
  "password": "12345678",
  "device_name": "POS-Terminal-01"
}
```

**Response:**
```json
{
  "error": false,
  "message": "Login successful",
  "data": {
    "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "user": {
      "id": 1,
      "name": "Admin User",
      "email": "admin@example.com",
      "store_id": 1,
      "store_name": "Main Store"
    }
  }
}
```

---

### GET /auth/me

Get the currently authenticated user's information.

**Use Case:** Verify session validity, display user info in the UI.

**Headers:** Requires `Authorization: Bearer {token}`

**Response:**
```json
{
  "error": false,
  "data": {
    "user": {
      "id": 1,
      "name": "Admin User",
      "email": "admin@example.com",
      "store_id": 1,
      "store_name": "Main Store"
    }
  }
}
```

---

### POST /auth/logout

Logout the current user and invalidate the session.

**Use Case:** User logs out at the end of their shift.

**Headers:** Requires `Authorization: Bearer {token}`

**Response:**
```json
{
  "error": false,
  "message": "Logged out successfully"
}
```

---

## Products

### GET /products

Retrieve a paginated list of products.

**Use Case:** Display product catalog on the POS sales screen.

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | integer | 1 | Page number |
| `per_page` | integer | 20 | Items per page |
| `search` | string | null | Search by name, SKU, or barcode |

**Example Request:**
```
GET /products?page=1&per_page=20&search=shirt
```

**Response:**
```json
{
  "error": false,
  "data": {
    "products": [
      {
        "id": 1,
        "name": "Blue T-Shirt",
        "sku": "TSH-BLU-001",
        "barcode": "1234567890123",
        "price": 29.99,
        "sale_price": 24.99,
        "image": "https://example.com/images/tshirt-blue.jpg",
        "quantity": 50,
        "description": "Comfortable cotton t-shirt",
        "is_available": true,
        "has_variants": true,
        "variants": [
          {
            "id": 1,
            "type": "attribute",
            "name": "Size",
            "options": [
              { "id": 1, "name": "Small", "price_modifier": 0 },
              { "id": 2, "name": "Medium", "price_modifier": 0 },
              { "id": 3, "name": "Large", "price_modifier": 2.00 }
            ]
          },
          {
            "id": 2,
            "type": "attribute",
            "name": "Color",
            "options": [
              { "id": 4, "name": "Blue", "price_modifier": 0 },
              { "id": 5, "name": "Red", "price_modifier": 0 }
            ]
          }
        ]
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total": 150,
      "last_page": 8
    }
  }
}
```

---

### POST /products/scan-barcode

Find a product by scanning its barcode.

**Use Case:** Quick product lookup when cashier scans a barcode.

**Request Body:**
```json
{
  "barcode": "1234567890123"
}
```

**Response (Found):**
```json
{
  "error": false,
  "data": {
    "product": {
      "id": 1,
      "name": "Blue T-Shirt",
      "sku": "TSH-BLU-001",
      "barcode": "1234567890123",
      "price": 29.99,
      "sale_price": 24.99,
      "image": "https://example.com/images/tshirt-blue.jpg",
      "quantity": 50,
      "is_available": true,
      "has_variants": false
    }
  }
}
```

**Response (Not Found):**
```json
{
  "error": false,
  "data": {
    "product": null
  }
}
```

---

### GET /products/categories

Get all product categories.

**Use Case:** Display category filters on the product grid.

**Response:**
```json
{
  "error": false,
  "data": {
    "categories": [
      { "id": 1, "name": "Clothing", "product_count": 45 },
      { "id": 2, "name": "Electronics", "product_count": 30 },
      { "id": 3, "name": "Accessories", "product_count": 25 }
    ]
  }
}
```

---

## Cart

### POST /cart/add

Add a product to the cart.

**Use Case:** Customer selects a product to purchase.

**Request Body:**
```json
{
  "product_id": 1,
  "quantity": 2,
  "attributes": {
    "1": 2,
    "2": 4
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `product_id` | integer | Yes | Product ID |
| `quantity` | integer | Yes | Quantity to add |
| `attributes` | object | No | Variant selections (variant_id: option_id) |

**Response:**
```json
{
  "error": false,
  "data": {
    "items": [
      {
        "id": 1,
        "name": "Blue T-Shirt (Medium, Blue)",
        "sku": "TSH-BLU-001-M-BLU",
        "price": 24.99,
        "quantity": 2,
        "image": "https://example.com/images/tshirt-blue.jpg"
      }
    ],
    "subtotal": 49.98,
    "discount": 0,
    "tax": 4.50,
    "shipping_amount": 0,
    "total": 54.48,
    "payment_method": null,
    "coupon_code": null
  }
}
```

---

### POST /cart/update

Update the quantity of an item in the cart.

**Use Case:** Customer changes quantity of an item.

**Request Body:**
```json
{
  "product_id": 1,
  "quantity": 3
}
```

**Response:** Same as `/cart/add`

---

### POST /cart/remove

Remove an item from the cart.

**Use Case:** Customer removes an item they don't want.

**Request Body:**
```json
{
  "product_id": 1
}
```

**Response:** Same as `/cart/add` (updated cart)

---

### POST /cart/clear

Clear all items from the cart.

**Use Case:** Cancel current transaction and start fresh.

**Request Body:** None

**Response:**
```json
{
  "error": false,
  "message": "Cart cleared"
}
```

---

### POST /cart/update-payment-method

Set the payment method for the cart.

**Use Case:** Customer selects cash or card payment.

**Request Body:**
```json
{
  "payment_method": "cash"
}
```

| Payment Method | Description |
|----------------|-------------|
| `cash` | Cash payment |
| `card` | Card payment |

**Response:** Same as `/cart/add` (updated cart)

---

## Customers

### GET /customers/search

Search for existing customers.

**Use Case:** Link a sale to a customer for loyalty/receipts.

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `keyword` | string | Search by name, email, or phone |

**Example Request:**
```
GET /customers/search?keyword=john
```

**Response:**
```json
{
  "error": false,
  "data": {
    "customers": [
      {
        "id": 1,
        "name": "John Doe",
        "email": "john@example.com",
        "phone": "+1234567890",
        "address": "123 Main St, City"
      }
    ]
  }
}
```

---

### POST /customers

Create a new customer.

**Use Case:** Register a new customer during checkout.

**Request Body:**
```json
{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "phone": "+1987654321",
  "address": "456 Oak Ave, Town"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Customer name |
| `email` | string | No | Email address |
| `phone` | string | No | Phone number |
| `address` | string | No | Address |

**Response:**
```json
{
  "error": false,
  "data": {
    "customer": {
      "id": 2,
      "name": "Jane Smith",
      "email": "jane@example.com",
      "phone": "+1987654321",
      "address": "456 Oak Ave, Town"
    }
  }
}
```

---

## Orders

### POST /orders

Complete checkout and create an order.

**Use Case:** Finalize the sale after payment is collected.

**Request Body:**
```json
{
  "payment_details": "Last 4 digits: 1234"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `payment_details` | string | No | Additional payment info (card last 4, etc.) |

**Response:**
```json
{
  "error": false,
  "data": {
    "order": {
      "id": 1001,
      "code": "ORD-2024-001001",
      "amount": 54.48,
      "payment_method": "cash",
      "status": "completed",
      "created_at": "2024-01-15T10:30:00Z",
      "payment_details": null,
      "items": [
        {
          "id": 1,
          "name": "Blue T-Shirt",
          "price": 24.99,
          "quantity": 2,
          "sku": "TSH-BLU-001"
        }
      ]
    }
  }
}
```

---

### GET /orders/{id}/receipt

Get the HTML receipt for an order.

**Use Case:** Display/print receipt after checkout.

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | integer | Order ID |

**Response:**
```json
{
  "error": false,
  "data": {
    "receipt_html": "<html>...receipt content...</html>"
  }
}
```

---

## Sessions

### GET /cash-registers

Get all available cash registers.

**Use Case:** User selects which register to work on.

**Response:**
```json
{
  "error": false,
  "data": {
    "cash_registers": [
      {
        "id": 1,
        "name": "Register 1",
        "code": "REG-001",
        "store_id": 1,
        "description": "Main entrance register",
        "is_active": true,
        "initial_float": 200.00
      },
      {
        "id": 2,
        "name": "Register 2",
        "code": "REG-002",
        "store_id": 1,
        "description": "Back counter register",
        "is_active": true,
        "initial_float": 200.00
      }
    ]
  }
}
```

---

### GET /sessions/active

Check if there's an active session for the current user.

**Use Case:** Resume existing session on login.

**Response (Has Session):**
```json
{
  "error": false,
  "data": {
    "session": {
      "id": 101,
      "cash_register_id": 1,
      "cash_register_name": "Register 1",
      "user_id": 1,
      "user_name": "Admin User",
      "status": "open",
      "opened_at": "2024-01-15T08:00:00Z",
      "closed_at": null,
      "opening_cash": 200.00,
      "closing_cash": null,
      "opening_denominations": {
        "100": 1,
        "50": 2
      },
      "closing_denominations": null,
      "opening_notes": "Starting shift",
      "closing_notes": null,
      "difference": null
    }
  }
}
```

**Response (No Session):** Returns 404 status

---

### POST /sessions/open

Open a new cash register session.

**Use Case:** Start of shift - count starting cash.

**Request Body:**
```json
{
  "cash_register_id": 1,
  "opening_cash": 200.00,
  "opening_denominations": {
    "100": 1,
    "50": 2,
    "20": 0,
    "10": 0,
    "5": 0,
    "1": 0
  },
  "opening_notes": "Starting morning shift"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `cash_register_id` | integer | Yes | Register to open |
| `opening_cash` | number | Yes | Total opening cash amount |
| `opening_denominations` | object | No | Count per denomination |
| `opening_notes` | string | No | Notes about opening |

**Response:**
```json
{
  "error": false,
  "data": {
    "session": {
      "id": 101,
      "cash_register_id": 1,
      "cash_register_name": "Register 1",
      "user_id": 1,
      "user_name": "Admin User",
      "status": "open",
      "opened_at": "2024-01-15T08:00:00Z",
      "opening_cash": 200.00,
      "opening_denominations": {
        "100": 1,
        "50": 2
      },
      "opening_notes": "Starting morning shift"
    }
  }
}
```

---

### POST /sessions/close

Close the current session.

**Use Case:** End of shift - count closing cash and reconcile.

**Request Body:**
```json
{
  "session_id": 101,
  "closing_cash": 450.00,
  "closing_denominations": {
    "100": 3,
    "50": 2,
    "20": 2,
    "10": 1,
    "5": 0,
    "1": 0
  },
  "closing_notes": "End of morning shift, all transactions complete"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `session_id` | integer | Yes | Session to close |
| `closing_cash` | number | Yes | Total closing cash amount |
| `closing_denominations` | object | No | Count per denomination |
| `closing_notes` | string | No | Notes about closing |

**Response:**
```json
{
  "error": false,
  "data": {
    "session": {
      "id": 101,
      "cash_register_id": 1,
      "cash_register_name": "Register 1",
      "user_id": 1,
      "user_name": "Admin User",
      "status": "closed",
      "opened_at": "2024-01-15T08:00:00Z",
      "closed_at": "2024-01-15T16:00:00Z",
      "opening_cash": 200.00,
      "closing_cash": 450.00,
      "opening_denominations": { "100": 1, "50": 2 },
      "closing_denominations": { "100": 3, "50": 2, "20": 2, "10": 1 },
      "opening_notes": "Starting morning shift",
      "closing_notes": "End of morning shift",
      "difference": 0.00
    }
  }
}
```

---

## Denominations

### GET /denominations

Get available currency denominations for cash counting.

**Use Case:** Display denomination inputs during session open/close.

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `currency` | string | USD | Currency code |

**Example Request:**
```
GET /denominations?currency=USD
```

**Response:**
```json
{
  "error": false,
  "data": {
    "denominations": [
      { "id": 1, "currency": "USD", "value": 100.00, "type": "bill", "display_name": "$100" },
      { "id": 2, "currency": "USD", "value": 50.00, "type": "bill", "display_name": "$50" },
      { "id": 3, "currency": "USD", "value": 20.00, "type": "bill", "display_name": "$20" },
      { "id": 4, "currency": "USD", "value": 10.00, "type": "bill", "display_name": "$10" },
      { "id": 5, "currency": "USD", "value": 5.00, "type": "bill", "display_name": "$5" },
      { "id": 6, "currency": "USD", "value": 1.00, "type": "bill", "display_name": "$1" },
      { "id": 7, "currency": "USD", "value": 0.25, "type": "coin", "display_name": "Quarter" },
      { "id": 8, "currency": "USD", "value": 0.10, "type": "coin", "display_name": "Dime" },
      { "id": 9, "currency": "USD", "value": 0.05, "type": "coin", "display_name": "Nickel" },
      { "id": 10, "currency": "USD", "value": 0.01, "type": "coin", "display_name": "Penny" }
    ]
  }
}
```

---

## Error Codes

| HTTP Status | Meaning |
|-------------|---------|
| 200 | Success |
| 400 | Bad Request - Invalid parameters |
| 401 | Unauthorized - Invalid or expired token |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource doesn't exist |
| 422 | Validation Error - Invalid data |
| 500 | Server Error |

---

## Offline Mode

The POS app supports offline mode. When offline:

1. Products are loaded from local SQLite database
2. Orders are queued in `pending_orders` table
3. When back online, pending orders are automatically synced
4. Cart operations require online connectivity

---

## Version

**API Version:** v1
**Documentation Version:** 1.0.0
**Last Updated:** January 2025
