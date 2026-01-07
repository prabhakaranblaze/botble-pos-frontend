# POS Node.js Backend

A Node.js backend API for the StampSmart POS system, designed to work alongside Laravel Botble CMS sharing the same MySQL database.

## Features

- **JWT Authentication** - Compatible with existing Botble user system
- **Full POS API** - Products, Cart, Orders, Customers, Sessions
- **ESC/POS Printing** - Native thermal printer support
- **Offline Support** - Session-based cart with sync capabilities
- **Same Database** - Works with existing Botble ecommerce tables

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Express.js |
| ORM | Prisma |
| Auth | JWT (jsonwebtoken) |
| Validation | Zod |
| Printer | escpos |
| Queue | BullMQ (optional) |

## Getting Started

### Prerequisites

- Node.js 18+
- MySQL (same database as Botble)
- Redis (optional, for sessions/queues)

### Installation

```bash
# Navigate to backend directory
cd pos-node-backend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your database credentials
nano .env

# Generate Prisma client
npm run db:generate

# Start development server
npm run dev
```

### Environment Variables

```env
# Database (same as Laravel .env)
DATABASE_URL="mysql://user:password@localhost:3306/botble_db"

# Server
PORT=3001
NODE_ENV=development

# JWT (generate a secure random string)
JWT_SECRET=your-super-secret-key
JWT_EXPIRES_IN=7d

# API Key (must match Flutter app)
API_KEY=GcrrfWGSHhVvwZVh7Skj4GPCQT08skcZ

# Printer
PRINTER_TYPE=network
PRINTER_HOST=192.168.1.100
PRINTER_PORT=9100

# Storage URL for images
STORAGE_URL=https://your-domain.com/storage
```

## API Endpoints

Base URL: `http://localhost:3001/api/v1/pos`

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/login` | Login |
| GET | `/auth/me` | Get current user |
| POST | `/auth/logout` | Logout |

### Products
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/products` | List products |
| POST | `/products/scan-barcode` | Find by barcode |
| GET | `/products/categories` | List categories |

### Cart
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/cart` | Get cart |
| POST | `/cart/add` | Add item |
| POST | `/cart/update` | Update quantity |
| POST | `/cart/remove` | Remove item |
| POST | `/cart/clear` | Clear cart |
| POST | `/cart/update-payment-method` | Set payment |

### Orders
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/orders` | Checkout |
| GET | `/orders/:id` | Get order |
| GET | `/orders/:id/receipt` | Get receipt HTML |

### Customers
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/customers/search` | Search customers |
| POST | `/customers` | Create customer |

### Sessions
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/cash-registers` | List registers |
| GET | `/sessions/active` | Get active session |
| POST | `/sessions/open` | Open session |
| POST | `/sessions/close` | Close session |

### Denominations
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/denominations` | Get by currency |

### Printer
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/printer/print-receipt` | Print receipt |
| POST | `/printer/open-drawer` | Open cash drawer |
| POST | `/printer/test` | Print test page |

## Project Structure

```
pos-node-backend/
├── src/
│   ├── config/
│   │   ├── index.js
│   │   └── database.js
│   ├── middleware/
│   │   ├── auth.middleware.js
│   │   └── error.middleware.js
│   ├── modules/
│   │   ├── auth/
│   │   ├── products/
│   │   ├── cart/
│   │   ├── orders/
│   │   ├── customers/
│   │   ├── sessions/
│   │   ├── denominations/
│   │   └── printer/
│   └── app.js
├── prisma/
│   └── schema.prisma
├── package.json
└── .env
```

## Database Compatibility

This backend connects to the same MySQL database as Laravel Botble CMS. It reads/writes to:

- `users` - Admin/POS users
- `ec_products` - Products
- `ec_orders` - Orders
- `ec_order_product` - Order items
- `ec_customers` - Customers
- `pos_registers` - POS sessions
- `pos_denominations` - Currency denominations

## Running in Production

```bash
# Build (if using TypeScript)
npm run build

# Start with PM2
pm2 start src/app.js --name pos-backend

# Or with systemd
sudo systemctl start pos-backend
```

## Printer Setup

### Network Printer
```env
PRINTER_TYPE=network
PRINTER_HOST=192.168.1.100
PRINTER_PORT=9100
```

### USB Printer
```env
PRINTER_TYPE=usb
```

Note: USB printers may require libusb on Linux:
```bash
sudo apt-get install libusb-1.0-0-dev
```

## License

Proprietary - StampSmart
