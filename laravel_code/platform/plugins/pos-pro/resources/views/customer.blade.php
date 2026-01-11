<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ trans('plugins/pos-pro::pos.customer_display') }} - {{ setting('admin_title', 'POS Pro') }}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/vue@3/dist/vue.global.js"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        primary: '#206bc4',
                        secondary: '#64748b',
                        dark: '#0f172a'
                    },
                    fontFamily: {
                        sans: ['Plus Jakarta Sans', 'sans-serif']
                    }
                }
            }
        }
    </script>
    <style>
        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
            background: #f3f4f6;
            overflow: hidden;
        }
        [v-cloak] {
            display: none;
        }
        .cart-item-enter-active,
        .cart-item-leave-active {
            transition: all 0.3s ease;
        }
        .cart-item-enter-from {
            opacity: 0;
            transform: translateX(-30px);
        }
        .cart-item-leave-to {
            opacity: 0;
            transform: translateX(30px);
        }
    </style>
</head>
<body class="text-slate-800">
    <div id="customer-display-app" v-cloak class="h-screen flex flex-col p-6">

        <!-- HEADER -->
        <div class="flex justify-between items-center mb-6 border-b border-gray-200 pb-4 bg-white p-4 rounded-xl shadow-sm">
            <div class="flex items-center gap-4">
                <img src="{{ setting('admin_logo') ? RvMedia::getImageUrl(setting('admin_logo')) : asset('vendor/core/core/base/images/logo.png') }}" class="h-12" alt="Logo">
                <div class="text-3xl font-bold text-primary">{{ setting('admin_title', 'Store') }}</div>
            </div>
            <div class="text-xl font-bold text-slate-500 uppercase tracking-widest">{{ trans('plugins/pos-pro::pos.customer_display') }}</div>
        </div>

        <!-- CONTENT -->
        <div class="flex-1 flex gap-6 overflow-hidden">

            <!-- LEFT: ITEMS LIST -->
            <div class="w-2/3 bg-white rounded-2xl shadow-lg border border-gray-200 flex flex-col overflow-hidden">
                <div class="p-4 bg-gray-50 border-b border-gray-200 font-bold text-gray-500 uppercase text-sm flex justify-between items-center">
                    <span>{{ trans('plugins/pos-pro::pos.cart') }}</span>
                    <span v-if="cart.length > 0" class="bg-primary text-white px-3 py-1 rounded-full text-xs">@{{ cart.length }} {{ trans('plugins/pos-pro::pos.items') }}</span>
                </div>

                <div class="flex-1 overflow-y-auto p-4 space-y-4">
                    <!-- Empty State -->
                    <div v-if="cart.length === 0" class="h-full flex flex-col items-center justify-center text-slate-300">
                        <i class="fa fa-basket-shopping text-9xl mb-6 opacity-30"></i>
                        <div class="text-3xl font-bold text-slate-400">{{ trans('plugins/pos-pro::pos.welcome') }}</div>
                        <p class="text-lg">{{ trans('plugins/pos-pro::pos.next_customer_please') }}</p>
                    </div>

                    <!-- Items -->
                    <transition-group name="cart-item">
                        <div v-for="item in cart" :key="item.id" class="flex items-center gap-4 p-4 border rounded-xl bg-gray-50 hover:border-primary transition-colors">
                            <img :src="item.image || 'https://placehold.co/100'" class="w-20 h-20 rounded-lg object-cover bg-white border" :alt="item.name">
                            <div class="flex-1">
                                <div class="text-xl font-bold text-slate-800">@{{ item.name }}</div>
                                <div class="text-slate-500 font-medium">@{{ item.qty }} x @{{ formatPrice(item.price) }}</div>
                            </div>
                            <div class="text-2xl font-black text-primary">@{{ formatPrice(item.price * item.qty) }}</div>
                        </div>
                    </transition-group>
                </div>
            </div>

            <!-- RIGHT: TOTALS -->
            <div class="w-1/3 flex flex-col gap-6">
                <!-- Total Card -->
                <div class="bg-dark text-white rounded-3xl p-4 lg:p-8 shadow-2xl text-center flex-1 flex flex-col justify-center relative overflow-hidden min-h-0">
                    <div class="absolute top-0 right-0 w-40 h-40 bg-primary/20 rounded-full blur-3xl -mr-10 -mt-10"></div>
                    <div class="relative z-10 overflow-hidden">
                        <div class="text-lg lg:text-2xl font-medium text-gray-400 mb-2 uppercase tracking-widest">{{ trans('plugins/pos-pro::pos.total_to_pay') }}</div>
                        <div class="text-4xl sm:text-5xl lg:text-6xl xl:text-7xl font-black tracking-tight my-2 lg:my-4 break-all">@{{ formatPrice(total) }}</div>
                        <div class="text-base lg:text-lg text-gray-400">{{ trans('plugins/pos-pro::pos.thank_you_for_shopping') }}</div>
                    </div>
                </div>

                <!-- Breakdown -->
                <div class="bg-white rounded-3xl p-4 lg:p-8 shadow-lg border border-gray-200 flex flex-col justify-center overflow-hidden">
                    <div class="flex justify-between text-base lg:text-xl mb-3 lg:mb-4 text-gray-600">
                        <span class="truncate mr-2">{{ trans('plugins/pos-pro::pos.subtotal') }}</span>
                        <span class="font-bold whitespace-nowrap">@{{ formatPrice(subTotal) }}</span>
                    </div>
                    <div v-if="tax > 0" class="flex justify-between text-base lg:text-xl mb-3 lg:mb-4 text-gray-600">
                        <span class="truncate mr-2">{{ trans('plugins/pos-pro::pos.tax') }}</span>
                        <span class="font-bold whitespace-nowrap">@{{ formatPrice(tax) }}</span>
                    </div>
                    <div v-if="discount > 0" class="flex justify-between text-base lg:text-xl mb-3 lg:mb-4 text-green-600">
                        <span class="truncate mr-2">{{ trans('plugins/pos-pro::pos.discount_amount') }}</span>
                        <span class="font-bold whitespace-nowrap">-@{{ formatPrice(discount) }}</span>
                    </div>
                    <div v-if="shipping > 0" class="flex justify-between text-base lg:text-xl mb-3 lg:mb-4 text-gray-600">
                        <span class="truncate mr-2">{{ trans('plugins/pos-pro::pos.shipping') }}</span>
                        <span class="font-bold whitespace-nowrap">@{{ formatPrice(shipping) }}</span>
                    </div>
                    <div class="flex justify-between text-lg lg:text-2xl font-bold text-slate-800 pt-3 lg:pt-4 border-t border-dashed">
                        <span class="truncate mr-2">{{ trans('plugins/pos-pro::pos.total') }}</span>
                        <span class="text-primary whitespace-nowrap">@{{ formatPrice(total) }}</span>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        const { createApp } = Vue;
        createApp({
            data() {
                return {
                    cart: [],
                    discount: 0,
                    shipping: 0,
                    currency: '{{ get_application_currency()->symbol }}',
                    currencyIsPrefix: {{ get_application_currency()->is_prefix_symbol ? 'true' : 'false' }}
                }
            },
            computed: {
                subTotal() {
                    return this.cart.reduce((sum, item) => sum + (parseFloat(item.price) * item.qty), 0);
                },
                tax() {
                    return this.cart.reduce((sum, item) => {
                        const rate = parseFloat(item.tax_rate) || 0;
                        return sum + (parseFloat(item.price) * item.qty * (rate / 100));
                    }, 0);
                },
                total() {
                    return this.subTotal + this.tax + this.shipping - this.discount;
                }
            },
            methods: {
                formatPrice(value) {
                    const num = parseFloat(value) || 0;
                    const formatted = num.toLocaleString('en-US', {
                        minimumFractionDigits: 2,
                        maximumFractionDigits: 2
                    });
                    return this.currencyIsPrefix
                        ? this.currency + formatted
                        : formatted + this.currency;
                }
            },
            mounted() {
                // Listen for data from POS Terminal via BroadcastChannel
                const channel = new BroadcastChannel('pos_channel');
                channel.onmessage = (event) => {
                    if (event.data.type === 'UPDATE_CART') {
                        this.cart = event.data.cart || [];
                        this.discount = parseFloat(event.data.discount) || 0;
                        this.shipping = parseFloat(event.data.shipping) || 0;
                    } else if (event.data.type === 'CLEAR') {
                        this.cart = [];
                        this.discount = 0;
                        this.shipping = 0;
                    }
                };
            }
        }).mount('#customer-display-app');
    </script>
</body>
</html>
