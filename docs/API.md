# StampSmart POS API Documentation

Complete API reference for the StampSmart POS Desktop Application.

**Base URL:** `https://api.stampsmart.com/api/v1/pos`

---

## Table of Contents

- [Authentication](#authentication)
- [Products](#products)
- [Cart](#cart)
- [Customers](#customers)
- [Orders](#orders)
- [Sessions](#sessions)
- [Denominations](#denominations)
- [Discounts](#discounts)
- [Settings](#settings)
- [Printer](#printer)
- [Reports](#reports)

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
      "store_name": "Main Store",
      "permissions": ["pos.sales", "pos.reports", "pos.settings"]
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
      "store_name": "Main Store",
      "permissions": ["pos.sales", "pos.reports"]
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

### POST /auth/verify-password

Verify user's password for sensitive operations.

**Use Case:** Confirm identity before applying discounts or refunds.

**Request Body:**
```json
{
  "password": "12345678"
}
```

**Response:**
```json
{
  "error": false,
  "data": {
    "valid": true
  }
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
| `category_id` | integer | null | Filter by category ID |

**Example Request:**
```
GET /products?page=1&per_page=20&search=coffee
```

**Response:**
```json
{
  "error": false,
  "data": {
    "products": [
      {
        "id": 1,
        "name": "Organic Coffee Beans",
        "sku": "COF-ORG-001",
        "barcode": "1234567890123",
        "price": 29.99,
        "sale_price": 24.99,
        "image": "https://example.com/images/coffee.jpg",
        "quantity": 50,
        "description": "Premium organic coffee",
        "is_available": true,
        "tax_rate": 15.0,
        "has_variants": false
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

### GET /products/:id

Get a single product by ID.

**Use Case:** Fetch full product details including variants.

**Response:**
```json
{
  "error": false,
  "data": {
    "product": {
      "id": 1,
      "name": "Organic Coffee Beans",
      "sku": "COF-ORG-001",
      "price": 29.99,
      "sale_price": 24.99,
      "tax_rate": 15.0,
      "has_variants": true,
      "variants": [
        {
          "id": 1,
          "name": "Size",
          "options": [
            { "id": 1, "name": "250g", "price_modifier": 0 },
            { "id": 2, "name": "500g", "price_modifier": 15.00 }
          ]
        }
      ]
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
      "name": "Organic Coffee Beans",
      "sku": "COF-ORG-001",
      "barcode": "1234567890123",
      "price": 29.99,
      "is_available": true
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
      { "id": 1, "name": "Beverages", "product_count": 45 },
      { "id": 2, "name": "Food", "product_count": 30 },
      { "id": 3, "name": "Accessories", "product_count": 25 }
    ]
  }
}
```

---

## Cart

### GET /cart

Get the current cart contents.

**Use Case:** Sync cart state with server.

**Response:**
```json
{
  "error": false,
  "data": {
    "items": [
      {
        "id": 1,
        "name": "Organic Coffee Beans",
        "sku": "COF-ORG-001",
        "price": 24.99,
        "quantity": 2,
        "image": "https://example.com/images/coffee.jpg"
      }
    ],
    "subtotal": 49.98,
    "discount": 0,
    "tax": 7.50,
    "shipping_amount": 0,
    "total": 57.48,
    "payment_method": null,
    "coupon_code": null
  }
}
```

---

### POST /cart/add

Add a product to the cart.

**Use Case:** Customer selects a product to purchase.

**Request Body:**
```json
{
  "product_id": 1,
  "quantity": 2,
  "attributes": {
    "1": 2
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `product_id` | integer | Yes | Product ID |
| `quantity` | integer | Yes | Quantity to add |
| `attributes` | object | No | Variant selections (variant_id: option_id) |

**Response:** Same as `GET /cart`

---

### POST /cart/update

Update the quantity of an item in the cart.

**Request Body:**
```json
{
  "product_id": 1,
  "quantity": 3
}
```

**Response:** Same as `GET /cart`

---

### POST /cart/remove

Remove an item from the cart.

**Request Body:**
```json
{
  "product_id": 1
}
```

**Response:** Same as `GET /cart`

---

### POST /cart/clear

Clear all items from the cart.

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

**Request Body:**
```json
{
  "payment_method": "pos_cash"
}
```

| Payment Method | Description |
|----------------|-------------|
| `pos_cash` | Cash payment at POS |
| `pos_card` | Card payment at POS |

**Response:** Same as `GET /cart`

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
        "phone": "+1234567890"
      }
    ]
  }
}
```

---

### GET /customers/:id

Get a single customer by ID.

**Response:**
```json
{
  "error": false,
  "data": {
    "customer": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890"
    }
  }
}
```

---

### POST /customers

Create a new customer.

**Request Body:**
```json
{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "phone": "+1987654321"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Customer name |
| `email` | string | No | Email address |
| `phone` | string | No | Phone number |

**Response:**
```json
{
  "error": false,
  "data": {
    "customer": {
      "id": 2,
      "name": "Jane Smith",
      "email": "jane@example.com",
      "phone": "+1987654321"
    }
  }
}
```

---

### GET /customers/:id/addresses

Get all addresses for a customer.

**Use Case:** Display delivery address options.

**Response:**
```json
{
  "error": false,
  "data": {
    "addresses": [
      {
        "id": 1,
        "name": "Home",
        "address": "123 Main St",
        "city": "Victoria",
        "state": "Mahe",
        "country": "Seychelles",
        "zip_code": "12345",
        "phone": "+1234567890",
        "is_default": true
      }
    ]
  }
}
```

---

### POST /customers/:id/addresses

Create a new address for a customer.

**Request Body:**
```json
{
  "name": "Office",
  "address": "456 Business Ave",
  "city": "Victoria",
  "state": "Mahe",
  "country": "Seychelles",
  "zip_code": "12345",
  "phone": "+1234567890",
  "is_default": false
}
```

**Response:**
```json
{
  "error": false,
  "data": {
    "address": {
      "id": 2,
      "name": "Office",
      "address": "456 Business Ave",
      "city": "Victoria",
      "is_default": false
    }
  }
}
```

---

## Orders

### GET /orders

Get list of orders with pagination.

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | integer | 1 | Page number |
| `per_page` | integer | 20 | Items per page |
| `from_date` | string | null | Start date (YYYY-MM-DD) |
| `to_date` | string | null | End date (YYYY-MM-DD) |

**Response:**
```json
{
  "error": false,
  "data": {
    "orders": [
      {
        "id": 1001,
        "code": "ORD-2024-001001",
        "amount": 54.48,
        "payment_method": "pos_cash",
        "status": "completed",
        "created_at": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total": 100,
      "last_page": 5
    }
  }
}
```

---

### POST /orders

Complete checkout and create an order (Direct Checkout).

**Use Case:** Finalize the sale after payment is collected.

**Request Body:**
```json
{
  "items": [
    {
      "product_id": 1,
      "name": "Organic Coffee Beans",
      "quantity": 2,
      "price": 24.99,
      "sku": "COF-ORG-001",
      "tax_rate": 15.0
    }
  ],
  "payment_method": "pos_cash",
  "payment_details": "Cash: $100.00, Change: $42.52",
  "payment_metadata": {
    "cash_received": 100.00,
    "change_given": 42.52
  },
  "customer_id": 1,
  "discount_amount": 5.00,
  "discount_description": "Loyalty discount",
  "shipping_amount": 0,
  "delivery_type": "pickup",
  "tax_amount": 7.50
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `items` | array | Yes | Cart items to checkout |
| `payment_method` | string | Yes | `pos_cash` or `pos_card` |
| `payment_details` | string | No | Display text for receipt |
| `payment_metadata` | object | No | Structured payment data |
| `customer_id` | integer | No | Customer ID |
| `discount_amount` | number | No | Total discount amount |
| `shipping_amount` | number | No | Shipping charge |
| `delivery_type` | string | No | `pickup` or `ship` |
| `tax_amount` | number | No | Pre-calculated tax |

**Payment Metadata:**

For cash:
```json
{
  "cash_received": 100.00,
  "change_given": 42.52
}
```

For card:
```json
{
  "card_last_four": "4242"
}
```

**Response:**
```json
{
  "error": false,
  "data": {
    "id": 1001,
    "code": "ORD-2024-001001",
    "amount": 57.48,
    "sub_total": 49.98,
    "tax_amount": 7.50,
    "discount_amount": 0,
    "shipping_amount": 0,
    "payment_method": "pos_cash",
    "payment_id": 501,
    "invoice_id": 301,
    "invoice_code": "INV-2024-001001",
    "status": "completed",
    "created_at": "2024-01-15T10:30:00Z",
    "payment_details": "Cash: $100.00, Change: $42.52",
    "payment_metadata": {
      "cash_received": 100.00,
      "change_given": 42.52
    },
    "items": [
      {
        "id": 1,
        "name": "Organic Coffee Beans",
        "price": 24.99,
        "quantity": 2,
        "sku": "COF-ORG-001"
      }
    ]
  }
}
```

---

### GET /orders/:id

Get a single order by ID.

**Response:**
```json
{
  "error": false,
  "data": {
    "order": {
      "id": 1001,
      "code": "ORD-2024-001001",
      "amount": 54.48,
      "payment_method": "pos_cash",
      "status": "completed",
      "created_at": "2024-01-15T10:30:00Z",
      "items": [...]
    }
  }
}
```

---

### GET /orders/:id/receipt

Get the HTML receipt for an order.

**Use Case:** Display/print receipt after checkout.

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
      "user_id": 1,
      "user_name": "Admin User",
      "status": "open",
      "opened_at": "2024-01-15T08:00:00Z",
      "opening_cash": 200.00,
      "cash_sales": 350.00,
      "card_sales": 150.00,
      "total_sales": 500.00,
      "order_count": 25
    }
  }
}
```

**Response (No Session):** Returns 404 status

---

### GET /sessions/history

Get session history for the current user.

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | integer | 1 | Page number |
| `per_page` | integer | 20 | Items per page |

**Response:**
```json
{
  "error": false,
  "data": {
    "sessions": [
      {
        "id": 100,
        "status": "closed",
        "opened_at": "2024-01-14T08:00:00Z",
        "closed_at": "2024-01-14T16:00:00Z",
        "opening_cash": 200.00,
        "closing_cash": 550.00,
        "cash_sales": 350.00,
        "difference": 0.00
      }
    ],
    "pagination": {...}
  }
}
```

---

### POST /sessions/open

Open a new cash register session.

**Use Case:** Start of shift - count starting cash.

**Request Body:**
```json
{
  "opening_cash": 200.00,
  "denominations": {
    "100": 1,
    "50": 2
  },
  "notes": "Starting morning shift"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `opening_cash` | number | Yes | Total opening cash amount |
| `denominations` | object | No | Count per denomination (denom_id: count) |
| `notes` | string | No | Notes about opening |

**Response:**
```json
{
  "error": false,
  "data": {
    "session": {
      "id": 101,
      "user_id": 1,
      "status": "open",
      "opened_at": "2024-01-15T08:00:00Z",
      "opening_cash": 200.00
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
  "closing_cash": 550.00,
  "denominations": {
    "100": 3,
    "50": 4,
    "20": 2,
    "10": 1
  },
  "notes": "End of shift"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `closing_cash` | number | Yes | Total closing cash amount |
| `denominations` | object | No | Count per denomination |
| `notes` | string | No | Notes about closing |

**Response:**
```json
{
  "error": false,
  "data": {
    "session": {
      "id": 101,
      "status": "closed",
      "opened_at": "2024-01-15T08:00:00Z",
      "closed_at": "2024-01-15T16:00:00Z",
      "opening_cash": 200.00,
      "closing_cash": 550.00,
      "cash_sales": 350.00,
      "card_sales": 150.00,
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
| `currency` | string | SCR | Currency code |

**Response:**
```json
{
  "error": false,
  "data": {
    "denominations": [
      { "id": 1, "currency": "SCR", "value": 500.00, "type": "bill", "display_name": "SCR 500" },
      { "id": 2, "currency": "SCR", "value": 100.00, "type": "bill", "display_name": "SCR 100" },
      { "id": 3, "currency": "SCR", "value": 50.00, "type": "bill", "display_name": "SCR 50" },
      { "id": 4, "currency": "SCR", "value": 25.00, "type": "bill", "display_name": "SCR 25" },
      { "id": 5, "currency": "SCR", "value": 10.00, "type": "coin", "display_name": "SCR 10" },
      { "id": 6, "currency": "SCR", "value": 5.00, "type": "coin", "display_name": "SCR 5" },
      { "id": 7, "currency": "SCR", "value": 1.00, "type": "coin", "display_name": "SCR 1" }
    ]
  }
}
```

---

### GET /denominations/currencies

Get list of available currencies.

**Response:**
```json
{
  "error": false,
  "data": {
    "currencies": ["SCR", "USD", "EUR"]
  }
}
```

---

## Discounts

### POST /discounts/validate

Validate a coupon code.

**Use Case:** Check if a coupon is valid before applying.

**Request Body:**
```json
{
  "code": "SAVE10",
  "subtotal": 100.00,
  "customer_id": 1
}
```

**Response (Valid):**
```json
{
  "error": false,
  "data": {
    "valid": true,
    "discount": {
      "id": 1,
      "code": "SAVE10",
      "type": "percentage",
      "value": 10,
      "discount_amount": 10.00,
      "description": "10% off"
    }
  }
}
```

**Response (Invalid):**
```json
{
  "error": true,
  "message": "Coupon has expired"
}
```

---

### POST /discounts/calculate

Calculate a manual discount.

**Use Case:** Manager applies a custom discount.

**Request Body:**
```json
{
  "subtotal": 100.00,
  "discount_type": "percentage",
  "discount_value": 15,
  "description": "VIP discount"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `subtotal` | number | Yes | Cart subtotal |
| `discount_type` | string | Yes | `percentage` or `fixed` |
| `discount_value` | number | Yes | Percentage (0-100) or fixed amount |
| `description` | string | No | Reason for discount |

**Response:**
```json
{
  "error": false,
  "data": {
    "discount_amount": 15.00,
    "description": "VIP discount"
  }
}
```

---

## Settings

### GET /settings

Get POS application settings.

**Use Case:** Load store configuration on app startup.

**Response:**
```json
{
  "error": false,
  "data": {
    "settings": {
      "store_name": "StampSmart Store",
      "store_address": "123 Main Street, Victoria",
      "store_phone": "+248 123 4567",
      "currency": "SCR",
      "tax_rate": 15.0,
      "receipt_footer": "Thank you for shopping!",
      "auto_print_receipt": true
    }
  }
}
```

---

## Printer

### POST /printer/print-receipt

Print receipt for an order.

**Use Case:** Reprint a receipt.

**Request Body:**
```json
{
  "order_id": 1001
}
```

**Response:**
```json
{
  "error": false,
  "message": "Receipt printed"
}
```

---

### POST /printer/open-drawer

Open the cash drawer.

**Use Case:** Open drawer for cash operations.

**Response:**
```json
{
  "error": false,
  "message": "Cash drawer opened"
}
```

---

### POST /printer/test

Print a test page.

**Use Case:** Verify printer is working.

**Response:**
```json
{
  "error": false,
  "message": "Test page printed"
}
```

---

## Reports

### GET /reports/orders

Get orders report with date filtering.

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `from_date` | string | Yes | Start date (YYYY-MM-DD) |
| `to_date` | string | Yes | End date (YYYY-MM-DD) |

**Example Request:**
```
GET /reports/orders?from_date=2024-01-01&to_date=2024-01-31
```

**Response:**
```json
{
  "error": false,
  "data": {
    "summary": {
      "total_orders": 150,
      "total_revenue": 15000.00,
      "total_tax": 2250.00,
      "total_discount": 500.00,
      "cash_sales": 10000.00,
      "card_sales": 5000.00,
      "average_order_value": 100.00
    },
    "orders": [
      {
        "id": 1001,
        "code": "ORD-2024-001001",
        "amount": 100.00,
        "payment_method": "pos_cash",
        "created_at": "2024-01-15T10:30:00Z"
      }
    ]
  }
}
```

---

### GET /reports/products

Get products sold report.

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `from_date` | string | Yes | Start date (YYYY-MM-DD) |
| `to_date` | string | Yes | End date (YYYY-MM-DD) |
| `sort_by` | string | No | `quantity`, `revenue`, or `name` |
| `sort_order` | string | No | `asc` or `desc` |

**Response:**
```json
{
  "error": false,
  "data": {
    "products": [
      {
        "id": 1,
        "name": "Organic Coffee Beans",
        "sku": "COF-ORG-001",
        "quantity_sold": 100,
        "revenue": 2499.00
      }
    ],
    "summary": {
      "total_products_sold": 500,
      "total_revenue": 15000.00
    }
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
| 429 | Too Many Requests - Rate limit exceeded |
| 500 | Server Error |

---

## Offline Mode

The POS app supports offline mode. When offline:

1. Products are loaded from local SQLite database
2. Orders are queued in `pending_orders` table
3. When back online, pending orders are automatically synced
4. Sessions require online connectivity

---

## Version

**API Version:** v1
**Documentation Version:** 2.0.0
**Last Updated:** January 2025
