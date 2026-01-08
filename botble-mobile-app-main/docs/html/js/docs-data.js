// Documentation data structure matching sidebar.ts
const docsData = {
    sections: [
        {
            id: 'overview',
            title: 'Overview',
            content: `
                <h1>MartFury - Flutter E-commerce App for Botble</h1>

                <h2>Introduction</h2>

                <p>MartFury is a feature-rich Flutter mobile application designed to work seamlessly with Botble E-commerce backend. This app provides a complete e-commerce experience with a modern UI and seamless integration with Botble's API. It serves as the mobile client for the <a href="https://codecanyon.net/item/martfury-multipurpose-laravel-ecommerce-system/29925223" target="_blank">MartFury Multipurpose Laravel Ecommerce System</a>.</p>

                <p>The app offers a comprehensive mobile shopping experience with intuitive navigation, secure authentication, advanced product browsing, smart shopping cart management, and complete order tracking capabilities.</p>

                <h2>🚀 Getting Started</h2>

                <p><strong>New to the app? Start here:</strong></p>

                <ol>
                    <li><strong>App Overview</strong> - What is MartFury and how it works (5 min read)</li>
                    <li><strong>Installation</strong> - Set up your development environment (30 min)</li>
                    <li><strong>Configuration</strong> - Connect your app to your website (15 min)</li>
                    <li><strong>Development Guide</strong> - Learn to customize your app</li>
                </ol>

                <h2>🎨 Quick Setup Guides (5-15 minutes each)</h2>

                <p><strong>Customize your app appearance:</strong></p>
                <ol>
                    <li><strong>Theme Colors</strong> - Change your app's colors</li>
                    <li><strong>App Font</strong> - Choose different fonts</li>
                    <li><strong>App Name</strong> - Change the app name</li>
                    <li><strong>App Logo</strong> - Add your logo and icons</li>
                </ol>

                <p><strong>Basic configuration:</strong></p>
                <ol start="5">
                    <li><strong>API Base URL</strong> - Connect to your website</li>
                    <li><strong>Translations</strong> - Set up multiple languages</li>
                    <li><strong>Ad Keys</strong> - Configure advertisements</li>
                    <li><strong>Profile Links</strong> - Set up help and support links</li>
                </ol>

                <p><strong>Build and deploy:</strong></p>
                <ol start="9">
                    <li><strong>Running App</strong> - Test your app</li>
                    <li><strong>Deploying App</strong> - Publish to app stores</li>
                    <li><strong>Version Management</strong> - Manage app versions</li>
                </ol>

                <h2>🔐 Social Login Setup (30-60 minutes each)</h2>

                <p><strong>Allow customers to login with social accounts:</strong></p>
                <ol start="12">
                    <li><strong>Google Login</strong> - Most popular, easiest setup</li>
                    <li><strong>Apple Sign-In</strong> - Required for iOS apps</li>
                    <li><strong>Facebook Login</strong> - Popular social option</li>
                    <li><strong>Twitter/X Login</strong> - Optional social login</li>
                </ol>

                <h2>Key Features</h2>

                <h3>1. <strong>User Authentication & Profile Management</strong></h3>
                <ul>
                    <li>Secure user registration and login system</li>
                    <li>Social login integration (Google, Facebook, Apple)</li>
                    <li>Password recovery with email verification</li>
                    <li>Comprehensive user profile management</li>
                    <li>Personal information editing</li>
                    <li>Address book management</li>
                    <li>Account settings and preferences</li>
                </ul>

                <h3>2. <strong>Advanced Product Browsing</strong></h3>
                <ul>
                    <li>Browse products by categories and collections</li>
                    <li>Featured products and flash sales sections</li>
                    <li>Advanced search functionality with filters</li>
                    <li>Product variations (color, size, attributes)</li>
                    <li>Detailed product information and images</li>
                    <li>Product reviews and ratings system</li>
                    <li>Recently viewed products tracking</li>
                    <li>Product comparison feature for side-by-side analysis</li>
                </ul>

                <h3>3. <strong>Smart Shopping Cart & Checkout</strong></h3>
                <ul>
                    <li>Add products to cart with quantity management</li>
                    <li>Apply coupon codes and discounts</li>
                    <li>Multiple payment gateway integration:
                        <ul>
                            <li>Credit/Debit Cards (Stripe)</li>
                            <li>PayPal</li>
                            <li>Razorpay</li>
                            <li>Mollie</li>
                            <li>SSLCommerz</li>
                            <li>Cash on Delivery (COD)</li>
                        </ul>
                    </li>
                    <li>Secure checkout process</li>
                    <li>Order confirmation and tracking</li>
                </ul>

                <h3>4. <strong>Wishlist & Product Comparison</strong></h3>
                <ul>
                    <li>Save favorite products for later</li>
                    <li>Easy wishlist management</li>
                    <li>Quick add to cart from wishlist</li>
                    <li>Wishlist sharing capabilities</li>
                    <li>Compare products side-by-side</li>
                    <li>Detailed comparison tables with specifications</li>
                    <li>Add products to compare from any listing</li>
                </ul>

                <h3>5. <strong>Order Management & Tracking</strong></h3>
                <ul>
                    <li>Complete order history</li>
                    <li>Real-time order status tracking</li>
                    <li>Order details and invoice access</li>
                    <li>Delivery status monitoring</li>
                    <li>Order tracking with email/order code</li>
                </ul>

                <h3>6. <strong>Multi-language & Currency Support</strong></h3>
                <ul>
                    <li>Support for multiple languages (English, Vietnamese, and more)</li>
                    <li>Multi-currency display</li>
                    <li>Localized content and interface</li>
                    <li>Easy language switching</li>
                </ul>

                <h3>7. <strong>Modern UI/UX Design</strong></h3>
                <ul>
                    <li>Clean and intuitive interface</li>
                    <li>Responsive design for all screen sizes</li>
                    <li>Dark mode support</li>
                    <li>Smooth animations and transitions</li>
                    <li>Material Design principles</li>
                </ul>

                <h3>8. <strong>API Integration</strong></h3>
                <ul>
                    <li>Seamless integration with Botble E-commerce API</li>
                    <li>Real-time data synchronization</li>
                    <li>Secure authentication tokens</li>
                    <li>Comprehensive API documentation</li>
                    <li>Error handling and offline support</li>
                </ul>

                <h2>Technical Specifications</h2>

                <h3>Requirements</h3>
                <ul>
                    <li>Flutter SDK 3.7.2 or higher</li>
                    <li>Dart SDK 3.0.0 or higher</li>
                    <li>Botble E-commerce backend with API access</li>
                    <li>Android Studio / VS Code for development</li>
                </ul>

                <h3>Architecture</h3>
                <ul>
                    <li><strong>Clean Architecture</strong>: Separation of concerns with Model-View-Controller pattern</li>
                    <li><strong>State Management</strong>: GetX for reactive state management and dependency injection</li>
                    <li><strong>API Services</strong>: RESTful API integration with Botble backend</li>
                    <li><strong>Localization</strong>: Easy localization support with JSON translation files</li>
                    <li><strong>Theme System</strong>: Customizable theme and styling system</li>
                </ul>

                <h3>Supported Platforms</h3>
                <ul>
                    <li>Android (API level 21+)</li>
                    <li>iOS (iOS 12.0+)</li>
                    <li>Cross-platform compatibility</li>
                </ul>

                <h2>Integration with Botble E-commerce</h2>

                <p>This Flutter app is specifically designed to work with the <a href="https://codecanyon.net/item/martfury-multipurpose-laravel-ecommerce-system/29925223" target="_blank">Botble MartFury E-commerce System</a>, which provides:</p>

                <ul>
                    <li><strong>Comprehensive Backend</strong>: Full-featured e-commerce backend with admin panel</li>
                    <li><strong>API Endpoints</strong>: RESTful API for mobile integration</li>
                    <li><strong>Multi-vendor Support</strong>: Marketplace functionality</li>
                    <li><strong>Payment Gateways</strong>: Multiple payment method integrations</li>
                    <li><strong>Product Management</strong>: Advanced product catalog management</li>
                    <li><strong>Order Processing</strong>: Complete order management system</li>
                    <li><strong>Customer Management</strong>: User account and profile management</li>
                </ul>

                <h2>API Documentation</h2>

                <p>The app integrates with the Botble E-commerce API, documented at <a href="https://stampsmart.ngrok.app/docs" target="_blank">https://stampsmart.ngrok.app/docs</a>. The API provides endpoints for:</p>

                <ul>
                    <li>Authentication and user management</li>
                    <li>Product catalog and search</li>
                    <li>Shopping cart operations</li>
                    <li>Order processing and tracking</li>
                    <li>Payment gateway integration</li>
                    <li>Wishlist management</li>
                    <li>Address and profile management</li>
                </ul>

                <h2>📞 Contact & Resources</h2>

                <h3><strong>Contact Information:</strong></h3>
                <ul>
                    <li><strong>📧 Email</strong>: contact@botble.com</li>
                    <li><strong>🌐 Website</strong>: https://botble.com</li>
                    <li><strong>🎫 Support Center</strong>: https://botble.ticksy.com</li>
                    <li><strong>📖 Online Documentation</strong>: https://docs.botble.com/martfury-flutter</li>
                </ul>

                <h3><strong>Resources:</strong></h3>
                <ul>
                    <li><strong>🎮 Backend Demo</strong>: https://martfury.botble.com</li>
                    <li><strong>📋 API Documentation</strong>: https://stampsmart.ngrok.app/docs</li>
                    <li><strong>🛒 Backend System</strong>: <a href="https://codecanyon.net/item/martfury-multipurpose-laravel-ecommerce-system/29925223" target="_blank">MartFury Laravel E-commerce</a></li>
                </ul>

                <h2>Botble Team</h2>

                <p>Developed by the Botble team. Visit us at <a href="https://botble.com" target="_blank">botble.com</a>.</p>
            `
        },
        {
            id: 'app-overview',
            title: 'App Overview',
            content: `
                <h1>MartFury Flutter App Overview</h1>

                <h2>What is MartFury Flutter App?</h2>

                <p>MartFury is a complete mobile e-commerce application built with Flutter that connects to your Botble e-commerce website. It provides your customers with a native mobile shopping experience on both Android and iOS devices.</p>

                <h2>📱 Key Features</h2>

                <h3>For Your Customers:</h3>
                <ul>
                    <li><strong>Easy Shopping</strong>: Browse products, search, and shop on mobile</li>
                    <li><strong>Secure Login</strong>: Email/password or social media login (Google, Facebook, Apple)</li>
                    <li><strong>Shopping Cart</strong>: Add items, apply coupons, and checkout securely</li>
                    <li><strong>Order Tracking</strong>: Track orders and view purchase history</li>
                    <li><strong>Wishlist</strong>: Save favorite products for later</li>
                    <li><strong>Multiple Languages</strong>: Shop in their preferred language</li>
                </ul>

                <h3>For Your Business:</h3>
                <ul>
                    <li><strong>Native Mobile App</strong>: Professional iOS and Android apps</li>
                    <li><strong>Your Branding</strong>: Customize colors, logo, and app name</li>
                    <li><strong>Multiple Payment Methods</strong>: Credit cards, PayPal, and more</li>
                    <li><strong>Real-time Sync</strong>: Connects directly to your website</li>
                    <li><strong>App Store Ready</strong>: Deploy to Google Play and Apple App Store</li>
                </ul>

                <h2>🌐 How It Works</h2>

                <ol>
                    <li><strong>Your Website</strong>: You have a Botble e-commerce website</li>
                    <li><strong>Mobile App</strong>: Customers download your branded mobile app</li>
                    <li><strong>Connected</strong>: App connects to your website's data and orders</li>
                    <li><strong>Shopping</strong>: Customers shop through the mobile app</li>
                    <li><strong>Orders</strong>: Orders appear in your website's admin panel</li>
                </ol>

                <h2>💰 What You Need</h2>

                <h3>Required:</h3>
                <ul>
                    <li><strong>Botble E-commerce Website</strong>: Your online store must be built with Botble</li>
                    <li><strong>API Access</strong>: Your website needs API enabled (contact your developer)</li>
                    <li><strong>Developer Accounts</strong>: Google Play ($25) and/or Apple App Store ($99/year)</li>
                </ul>

                <h3>Optional:</h3>
                <ul>
                    <li><strong>Social Login</strong>: Developer accounts for Google, Facebook, Apple login</li>
                    <li><strong>Custom Development</strong>: If you want special features</li>
                </ul>

                <h2>🚀 Getting Started</h2>

                <ol>
                    <li><strong>Install Flutter</strong> - Set up development environment</li>
                    <li><strong>Configure App</strong> - Connect to your website</li>
                    <li><strong>Customize App</strong> - Add your branding</li>
                    <li><strong>Deploy App</strong> - Publish to app stores</li>
                </ol>

                <h2>📞 Contact & Support</h2>

                <h3>📧 <strong>Email</strong>: contact@botble.com</h3>
                <h3>🌐 <strong>Website</strong>: https://botble.com</h3>
                <h3>🎫 <strong>Support Center</strong>: https://botble.ticksy.com</h3>
                <h3>📖 <strong>Online Documentation</strong>: https://docs.botble.com/martfury-flutter</h3>
                <h3>🎮 <strong>Backend Demo</strong>: https://martfury.botble.com</h3>
                <h3>📋 <strong>API Documentation</strong>: https://stampsmart.ngrok.app/docs</h3>

                <h2>🎯 Who Is This For?</h2>

                <h3>Perfect If You:</h3>
                <ul>
                    <li>✅ Have a Botble e-commerce website</li>
                    <li>✅ Want to offer mobile shopping to customers</li>
                    <li>✅ Want professional iOS and Android apps</li>
                    <li>✅ Need apps that sync with your website</li>
                </ul>

                <h3>Not Right If You:</h3>
                <ul>
                    <li>❌ Don't have a Botble website</li>
                    <li>❌ Want a completely custom app</li>
                    <li>❌ Need features not available in e-commerce</li>
                    <li>❌ Don't want to maintain mobile apps</li>
                </ul>

                <h2>💡 Success Tips</h2>

                <h3>Before You Start:</h3>
                <ul>
                    <li>Make sure your website works perfectly</li>
                    <li>Have your branding ready (logo, colors)</li>
                    <li>Plan your app store listings</li>
                    <li>Test everything thoroughly</li>
                </ul>

                <h3>For Best Results:</h3>
                <ul>
                    <li>Keep the app simple and focused</li>
                    <li>Test on real devices</li>
                    <li>Get feedback from real customers</li>
                    <li>Update regularly with your website</li>
                </ul>

                <h2>🆘 Need Help?</h2>

                <ul>
                    <li><strong>Quick Questions</strong>: Check our FAQ</li>
                    <li><strong>Problems</strong>: Read Troubleshooting Guide</li>
                    <li><strong>Support</strong>: Visit our Support Page</li>
                    <li><strong>Community</strong>: Join other Botble users for tips and advice</li>
                </ul>

                <p><strong>Remember</strong>: You're not alone! We're here to help you succeed with your mobile app.</p>
            `
        },
        {
            id: 'getting-started',
            title: 'Getting Started',
            subsections: [
                {
                    id: 'installation',
                    title: 'Installation',
                    content: `
                        <h1>Installation Guide</h1>

                        <p>Simple steps to get your MartFury app running on your computer.</p>

                        <h2>🚀 Quick Start</h2>

                        <h3>What You Need</h3>
                        <ul>
                            <li>A computer (Windows, Mac, or Linux)</li>
                            <li>Internet connection</li>
                            <li>About 30 minutes of your time</li>
                        </ul>

                        <h3>Step 1: Install Flutter</h3>
                        <ol>
                            <li>Go to <a href="https://flutter.dev" target="_blank">flutter.dev</a></li>
                            <li>Click "Get Started"</li>
                            <li>Follow the installation guide for your computer</li>
                            <li>This will take about 15-20 minutes</li>
                        </ol>

                        <h3>Step 2: Get the App Code</h3>
                        <ol>
                            <li>Download your MartFury app files</li>
                            <li>Extract them to a folder on your computer</li>
                            <li>Remember where you put this folder!</li>
                        </ol>

                        <h3>Step 3: Set Up Your App</h3>
                        <ol>
                            <li>Open Terminal (Mac/Linux) or Command Prompt (Windows)</li>
                            <li>Navigate to your app folder:
                                <pre><code>cd path/to/your/martfury-app</code></pre>
                            </li>
                            <li>Install dependencies:
                                <pre><code>flutter pub get</code></pre>
                            </li>
                        </ol>

                        <h3>Step 4: Connect Your Website</h3>
                        <ol>
                            <li>Open the <code>.env</code> file in your app folder</li>
                            <li>Change this line to your website:
                                <pre><code>API_BASE_URL=https://your-website.com</code></pre>
                            </li>
                            <li>Save the file</li>
                        </ol>

                        <h3>Step 5: Test the App</h3>
                        <ol>
                            <li>Connect your phone or start an emulator</li>
                            <li>Run this command:
                                <pre><code>flutter run</code></pre>
                            </li>
                            <li>Your app should start! 🎉</li>
                        </ol>

                        <h2>🔧 If Something Goes Wrong</h2>

                        <h3>"Flutter not found"</h3>
                        <ul>
                            <li>Make sure you installed Flutter correctly</li>
                            <li>Restart your terminal/command prompt</li>
                            <li>Try running <code>flutter doctor</code> to check installation</li>
                        </ul>

                        <h3>"No devices found"</h3>
                        <ul>
                            <li>Connect your phone with USB cable</li>
                            <li>Enable Developer Options on your phone</li>
                            <li>Or start an Android/iOS emulator</li>
                        </ul>

                        <h3>"Build failed"</h3>
                        <p>Run these commands:</p>
                        <pre><code>flutter clean
flutter pub get
flutter run</code></pre>

                        <h2>📱 Next Steps</h2>

                        <p>Once your app is running:</p>
                        <ol>
                            <li><strong>Customize it</strong>: Follow the Quick Setup Guides</li>
                            <li><strong>Set up social login</strong>: Check Social Login Setup</li>
                            <li><strong>Deploy it</strong>: Follow the Deployment Guide</li>
                        </ol>

                        <h2>🆘 Need Help?</h2>

                        <ul>
                            <li>Check the FAQ for common questions</li>
                            <li>Read the Troubleshooting Guide</li>
                            <li>Contact support if you're still stuck</li>
                        </ul>

                        <p><strong>Remember</strong>: Don't worry if this seems complicated at first. Most people get it working within an hour, and we're here to help!</p>
                    `
                },
                {
                    id: 'configuration',
                    title: 'Configuration',
                    content: `
                        <h1>Configuration Guide</h1>

                        <p>How to connect your app to your website and customize basic settings.</p>

                        <h2>🔗 Connect to Your Website</h2>

                        <h3>Step 1: Find Your Website URL</h3>
                        <p>Your website URL is the address people use to visit your online store.</p>
                        <p>Examples:</p>
                        <ul>
                            <li><code>https://mystore.com</code></li>
                            <li><code>https://shop.mycompany.com</code></li>
                            <li><code>https://mystore.botble.com</code></li>
                        </ul>

                        <h3>Step 2: Update App Configuration</h3>
                        <ol>
                            <li>Open the <code>.env</code> file in your app folder</li>
                            <li>Find this line:
                                <pre><code>API_BASE_URL=https://stampsmart.ngrok.app</code></pre>
                            </li>
                            <li>Replace it with your website:
                                <pre><code>API_BASE_URL=https://your-website.com</code></pre>
                            </li>
                            <li>Save the file</li>
                        </ol>

                        <h3>Step 3: Test the Connection</h3>
                        <ol>
                            <li>Run your app:
                                <pre><code>flutter run</code></pre>
                            </li>
                            <li>Try to login with an account from your website</li>
                            <li>If it works, you're connected! 🎉</li>
                        </ol>

                        <h2>⚙️ Basic App Settings</h2>

                        <h3>App Name</h3>
                        <p>Change your app's name by following: <strong>App Name Guide</strong></p>

                        <h3>App Colors</h3>
                        <p>Customize your app's colors: <strong>Theme Colors Guide</strong></p>

                        <h3>App Logo</h3>
                        <p>Add your logo: <strong>App Logo Guide</strong></p>

                        <h3>Languages</h3>
                        <p>Set up multiple languages: <strong>Translations Guide</strong></p>

                        <h2>🔐 Security Settings</h2>

                        <h3>HTTPS Required</h3>
                        <ul>
                            <li>Always use <code>https://</code> in your website URL</li>
                            <li>Never use <code>http://</code> for live websites</li>
                            <li>This keeps your customers' data safe</li>
                        </ul>

                        <h3>API Access</h3>
                        <p>Make sure your website allows the app to connect:</p>
                        <ol>
                            <li>Contact your website developer</li>
                            <li>Tell them you need "API access enabled"</li>
                            <li>They'll know what this means</li>
                        </ol>

                        <h2>🧪 Testing Your Setup</h2>

                        <h3>Test These Features:</h3>
                        <ul>
                            <li>✅ Login with existing account</li>
                            <li>✅ Browse products</li>
                            <li>✅ Add items to cart</li>
                            <li>✅ Search for products</li>
                            <li>✅ View product details</li>
                        </ul>

                        <h3>If Something Doesn't Work:</h3>
                        <ol>
                            <li>Check your website URL is correct</li>
                            <li>Make sure your website is online</li>
                            <li>Try logging in on your website directly</li>
                            <li>Contact support with details</li>
                        </ol>

                        <h2>🚀 Advanced Configuration</h2>

                        <p>For more advanced setup:</p>
                        <ul>
                            <li><strong>API Integration</strong> - Technical details</li>
                            <li><strong>Development Guide</strong> - Customization options</li>
                        </ul>

                        <h2>💡 Tips for Success</h2>

                        <h3>Before Going Live:</h3>
                        <ul>
                            <li>Test everything thoroughly</li>
                            <li>Try on different phones</li>
                            <li>Ask friends to test the app</li>
                            <li>Make sure payments work</li>
                        </ul>

                        <h3>Keep It Simple:</h3>
                        <ul>
                            <li>Start with basic setup</li>
                            <li>Add features gradually</li>
                            <li>Test each change</li>
                            <li>Don't change too many things at once</li>
                        </ul>

                        <h2>🆘 Common Problems</h2>

                        <h3>"Connection Failed"</h3>
                        <ul>
                            <li>Check your website URL</li>
                            <li>Make sure website is online</li>
                            <li>Contact your website developer</li>
                        </ul>

                        <h3>"Login Doesn't Work"</h3>
                        <ul>
                            <li>Test login on your website first</li>
                            <li>Check if API is enabled</li>
                            <li>Verify user accounts exist</li>
                        </ul>

                        <h3>"No Products Show"</h3>
                        <ul>
                            <li>Make sure products exist on website</li>
                            <li>Check if products are published</li>
                            <li>Verify categories are set up</li>
                        </ul>

                        <p>For more help, check the Troubleshooting Guide.</p>
                    `
                },
                {
                    id: 'development',
                    title: 'Development Guide',
                    content: `
                        <h1>Development Guide</h1>

                        <p>This guide helps you customize the MartFury Flutter app. No advanced Flutter knowledge required!</p>

                        <h2>Understanding the App Structure</h2>

                        <p>Think of the app like a house with different rooms:</p>

                        <pre><code>lib/
├── core/                  # 🏠 Main settings (like your house's electrical panel)
│   └── app_config.dart   # App settings (colors, URLs, etc.)
├── main.dart             # 🚪 Front door (app starts here)
└── src/
    ├── controller/       # 🧠 Smart controls (handles app logic)
    ├── model/           # 📋 Data templates (user info, product info)
    ├── service/         # 🌐 Internet connections (talks to your website)
    ├── theme/           # 🎨 Design settings (colors, fonts)
    └── view/            # 👀 What users see
        ├── screen/      # 📱 App pages (login, home, etc.)
        └── widget/      # 🧩 Reusable parts (buttons, cards)</code></pre>

                        <h2>Quick Start</h2>

                        <h3>Before You Begin</h3>

                        <p>✅ <strong>What You Need:</strong></p>
                        <ol>
                            <li>Flutter installed on your computer</li>
                            <li>A code editor (VS Code is easiest)</li>
                            <li>The app source code</li>
                            <li>30 minutes of your time</li>
                        </ol>

                        <h3>First Steps</h3>

                        <ol>
                            <li><strong>Open Terminal/Command Prompt</strong></li>
                            <li><strong>Go to your app folder</strong></li>
                            <li><strong>Install dependencies:</strong>
                                <pre><code>flutter pub get</code></pre>
                            </li>
                            <li><strong>Run the app:</strong>
                                <pre><code>flutter run</code></pre>
                            </li>
                        </ol>

                        <p>That's it! Your app should start running.</p>

                        <h2>Common Customizations</h2>

                        <h3>🎨 Changing Colors and Fonts</h3>

                        <p><strong>Want different colors?</strong></p>
                        <ol>
                            <li>Open <code>lib/src/theme/app_theme.dart</code></li>
                            <li>Find the color you want to change</li>
                            <li>Replace with your color code</li>
                        </ol>

                        <pre><code>// Example: Change primary color to red
static const Color primaryColor = Color(0xFFFF0000); // Red color</code></pre>

                        <p><strong>Want different fonts?</strong></p>
                        <ol>
                            <li>Open <code>lib/src/theme/app_fonts.dart</code></li>
                            <li>Change the font name</li>
                        </ol>

                        <pre><code>// Example: Change to Roboto font
const kAppTextStyle = GoogleFonts.roboto;</code></pre>

                        <h3>📝 Adding New Text</h3>

                        <p><strong>To add new text that can be translated:</strong></p>

                        <ol>
                            <li>Open <code>assets/translations/en.json</code></li>
                            <li>Add your text:
                                <pre><code>{
  "my_new_text": "Hello World"
}</code></pre>
                            </li>
                            <li>Use it in your app:
                                <pre><code>Text('my_new_text'.tr())</code></pre>
                            </li>
                        </ol>

                        <h3>🔗 Adding New API Connections</h3>

                        <p><strong>Need to connect to a new API?</strong></p>

                        <ol>
                            <li><strong>Add the URL</strong> in <code>lib/core/app_config.dart</code>:
                                <pre><code>static const String myNewApiUrl = 'https://api.example.com/data';</code></pre>
                            </li>
                            <li><strong>Create a simple service</strong> in <code>lib/src/service/</code>:
                                <pre><code>class MyNewService {
  static Future&lt;List&lt;dynamic&gt;&gt; getData() async {
    // This gets data from your API
    final response = await http.get(Uri.parse(AppConfig.myNewApiUrl));
    return json.decode(response.body);
  }
}</code></pre>
                            </li>
                            <li><strong>Use it in your screen</strong>:
                                <pre><code>// In your screen file
FutureBuilder(
  future: MyNewService.getData(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return Text('Data loaded!');
    }
    return CircularProgressIndicator();
  },
)</code></pre>
                            </li>
                        </ol>

                        <h2>Testing Your Changes</h2>

                        <h3>🧪 Simple Testing</h3>

                        <p><strong>Before releasing your app:</strong></p>

                        <ol>
                            <li><strong>Test on different devices:</strong>
                                <ul>
                                    <li>Android phone</li>
                                    <li>iPhone (if possible)</li>
                                    <li>Different screen sizes</li>
                                </ul>
                            </li>
                            <li><strong>Test basic functions:</strong>
                                <ul>
                                    <li>Login/logout</li>
                                    <li>Browse products</li>
                                    <li>Add to cart</li>
                                    <li>Search</li>
                                </ul>
                            </li>
                            <li><strong>Test your changes:</strong>
                                <ul>
                                    <li>Did your color changes work?</li>
                                    <li>Do new texts show correctly?</li>
                                    <li>Are new features working?</li>
                                </ul>
                            </li>
                        </ol>

                        <h3>🔧 Quick Fixes</h3>

                        <p><strong>App not starting?</strong></p>
                        <pre><code>flutter clean
flutter pub get
flutter run</code></pre>

                        <p><strong>Colors not changing?</strong></p>
                        <ul>
                            <li>Make sure you saved the file</li>
                            <li>Restart the app (hot reload might not work for theme changes)</li>
                        </ul>

                        <p><strong>New text not showing?</strong></p>
                        <ul>
                            <li>Check spelling in translation files</li>
                            <li>Make sure you're using <code>.tr()</code> at the end</li>
                        </ul>

                        <h2>Building Your App</h2>

                        <h3>📱 For Testing</h3>

                        <p><strong>Android:</strong></p>
                        <pre><code>flutter build apk --debug</code></pre>

                        <p><strong>iPhone:</strong></p>
                        <pre><code>flutter build ios --debug</code></pre>

                        <h3>🚀 For App Store Release</h3>

                        <p><strong>Android (Google Play):</strong></p>
                        <pre><code>flutter build appbundle --release</code></pre>

                        <p><strong>iPhone (App Store):</strong></p>
                        <pre><code>flutter build ios --release</code></pre>

                        <h2>Getting Help</h2>

                        <h3>📚 Useful Resources</h3>

                        <ul>
                            <li><strong>Flutter Documentation</strong>: <a href="https://flutter.dev" target="_blank">flutter.dev</a></li>
                            <li><strong>Quick Setup Guides</strong>: Check files 01-15 in this documentation</li>
                            <li><strong>Social Login Setup</strong>: Check files 12-15 for Facebook, Google, Apple, Twitter</li>
                        </ul>

                        <h3>🆘 Common Problems</h3>

                        <p><strong>Problem: "Flutter not found"</strong></p>
                        <ul><li>Solution: Install Flutter SDK first</li></ul>

                        <p><strong>Problem: "No devices found"</strong></p>
                        <ul><li>Solution: Connect your phone or start an emulator</li></ul>

                        <p><strong>Problem: "Build failed"</strong></p>
                        <ul><li>Solution: Run <code>flutter clean</code> then <code>flutter pub get</code></li></ul>

                        <p><strong>Problem: "App crashes"</strong></p>
                        <ul><li>Solution: Check the error message in terminal/console</li></ul>

                        <h3>💡 Tips for Success</h3>

                        <ol>
                            <li><strong>Start Small</strong>: Make one change at a time</li>
                            <li><strong>Test Often</strong>: Run the app after each change</li>
                            <li><strong>Keep Backups</strong>: Use git to save your work</li>
                            <li><strong>Ask for Help</strong>: Don't hesitate to contact support</li>
                        </ol>

                        <p>Remember: You don't need to be a Flutter expert to customize this app! Start with simple changes like colors and text, then gradually try more advanced features.</p>
                    `
                },
                {
                    id: 'api-integration',
                    title: 'API Integration',
                    content: `
                        <h1>API Integration Guide</h1>

                        <p>Simple guide to connect your app with your website's API. No technical expertise required!</p>

                        <h2>What is API Integration?</h2>

                        <p>Think of API as a bridge between your mobile app and your website. When someone logs in on the app, it talks to your website to check if the login is correct.</p>

                        <h2>🔧 Quick Setup</h2>

                        <h3>Step 1: Set Your Website URL</h3>

                        <ol>
                            <li>Open the <code>.env</code> file in your app folder</li>
                            <li>Change this line to your website address:
                                <pre><code>API_BASE_URL=https://your-website.com</code></pre>
                            </li>
                        </ol>

                        <p><strong>Example:</strong></p>
                        <pre><code>API_BASE_URL=https://mystore.com</code></pre>

                        <h3>Step 2: Test the Connection</h3>

                        <ol>
                            <li>Run your app</li>
                            <li>Try to login</li>
                            <li>If it works, you're connected! 🎉</li>
                        </ol>

                        <p><strong>If it doesn't work:</strong></p>
                        <ul>
                            <li>Make sure your website URL is correct</li>
                            <li>Check if your website is online</li>
                            <li>Contact your website developer</li>
                        </ul>

                        <h2>📱 What Your App Can Do</h2>

                        <p>Your app connects to your website to:</p>

                        <h3>👤 User Features</h3>
                        <ul>
                            <li><strong>Login/Register</strong>: Users can create accounts and sign in</li>
                            <li><strong>Social Login</strong>: Login with Google, Facebook, Apple</li>
                            <li><strong>Profile</strong>: Users can update their information</li>
                            <li><strong>Addresses</strong>: Save shipping addresses</li>
                        </ul>

                        <h3>🛍️ Shopping Features</h3>
                        <ul>
                            <li><strong>Browse Products</strong>: See all your products</li>
                            <li><strong>Search</strong>: Find specific products</li>
                            <li><strong>Categories</strong>: Browse by product categories</li>
                            <li><strong>Shopping Cart</strong>: Add/remove items</li>
                            <li><strong>Wishlist</strong>: Save favorite products</li>
                            <li><strong>Compare</strong>: Compare different products</li>
                        </ul>

                        <h3>📦 Order Features</h3>
                        <ul>
                            <li><strong>Place Orders</strong>: Complete purchases</li>
                            <li><strong>Order History</strong>: See past orders</li>
                            <li><strong>Track Orders</strong>: Check delivery status</li>
                            <li><strong>Reviews</strong>: Rate and review products</li>
                        </ul>

                        <h2>🔍 How to Check if Everything Works</h2>

                        <h3>Test User Login</h3>
                        <ol>
                            <li>Open your app</li>
                            <li>Try to register a new account</li>
                            <li>Try to login with the account</li>
                            <li>✅ <strong>Success</strong>: You see the home screen</li>
                            <li>❌ <strong>Problem</strong>: You see an error message</li>
                        </ol>

                        <h3>Test Product Loading</h3>
                        <ol>
                            <li>Go to the products page</li>
                            <li>✅ <strong>Success</strong>: You see your products from the website</li>
                            <li>❌ <strong>Problem</strong>: No products show or error message</li>
                        </ol>

                        <h3>Test Shopping Cart</h3>
                        <ol>
                            <li>Add a product to cart</li>
                            <li>Go to cart page</li>
                            <li>✅ <strong>Success</strong>: Product appears in cart</li>
                            <li>❌ <strong>Problem</strong>: Cart is empty or error</li>
                        </ol>

                        <h2>🚨 Common Problems & Solutions</h2>

                        <h3>Problem: "Connection Failed" or "Network Error"</h3>

                        <p><strong>Possible Causes:</strong></p>
                        <ul>
                            <li>Wrong website URL in <code>.env</code> file</li>
                            <li>Website is down</li>
                            <li>Internet connection issues</li>
                        </ul>

                        <p><strong>Solutions:</strong></p>
                        <ol>
                            <li>Check your website URL is correct</li>
                            <li>Test your website in a browser</li>
                            <li>Check your internet connection</li>
                            <li>Contact your website developer</li>
                        </ol>

                        <h3>Problem: "Login Failed"</h3>

                        <p><strong>Possible Causes:</strong></p>
                        <ul>
                            <li>API not configured on website</li>
                            <li>Wrong login credentials</li>
                            <li>Account doesn't exist</li>
                        </ul>

                        <p><strong>Solutions:</strong></p>
                        <ol>
                            <li>Make sure you can login on your website</li>
                            <li>Check if API is enabled on your website</li>
                            <li>Try creating a new account first</li>
                        </ol>

                        <h3>Problem: "No Products Showing"</h3>

                        <p><strong>Possible Causes:</strong></p>
                        <ul>
                            <li>No products in your website database</li>
                            <li>API not returning product data</li>
                            <li>Category/filter issues</li>
                        </ul>

                        <p><strong>Solutions:</strong></p>
                        <ol>
                            <li>Check if products exist on your website</li>
                            <li>Try refreshing the app</li>
                            <li>Check if categories are set up correctly</li>
                        </ol>

                        <h3>Problem: "Cart Not Working"</h3>

                        <p><strong>Possible Causes:</strong></p>
                        <ul>
                            <li>User not logged in</li>
                            <li>API session expired</li>
                            <li>Cart API not configured</li>
                        </ul>

                        <p><strong>Solutions:</strong></p>
                        <ol>
                            <li>Make sure user is logged in</li>
                            <li>Try logging out and back in</li>
                            <li>Contact your developer to check cart API</li>
                        </ol>

                        <h2>💡 Tips for Success</h2>

                        <h3>Before You Start</h3>
                        <ol>
                            <li><strong>Make sure your website works</strong> - Test login, products, and orders on your website first</li>
                            <li><strong>Have your website URL ready</strong> - You'll need the exact address</li>
                            <li><strong>Contact your developer</strong> - If you're not technical, ask for help</li>
                        </ol>

                        <h3>During Setup</h3>
                        <ol>
                            <li><strong>Test one thing at a time</strong> - Don't change multiple settings at once</li>
                            <li><strong>Keep backups</strong> - Save your original files before making changes</li>
                            <li><strong>Document changes</strong> - Write down what you changed</li>
                        </ol>

                        <h3>After Setup</h3>
                        <ol>
                            <li><strong>Test everything</strong> - Try all features in the app</li>
                            <li><strong>Test on different devices</strong> - Android and iPhone if possible</li>
                            <li><strong>Ask users to test</strong> - Get feedback from real users</li>
                        </ol>

                        <h2>📞 Getting Help</h2>

                        <h3>When to Contact Support</h3>
                        <ul>
                            <li>App won't connect to your website</li>
                            <li>Login doesn't work</li>
                            <li>Products don't show up</li>
                            <li>Orders aren't working</li>
                            <li>Any error messages you don't understand</li>
                        </ul>

                        <h3>What Information to Provide</h3>
                        <ol>
                            <li><strong>Your website URL</strong></li>
                            <li><strong>What you were trying to do</strong></li>
                            <li><strong>What error message you saw</strong></li>
                            <li><strong>Screenshots if possible</strong></li>
                            <li><strong>Device type</strong> (Android/iPhone)</li>
                        </ol>

                        <h3>Quick Self-Help Checklist</h3>
                        <ul>
                            <li>✅ Is your website online and working?</li>
                            <li>✅ Is the URL in <code>.env</code> file correct?</li>
                            <li>✅ Can you login on your website?</li>
                            <li>✅ Do you have products on your website?</li>
                            <li>✅ Is your internet connection working?</li>
                        </ul>

                        <h2>📚 Additional Resources</h2>

                        <h3>Helpful Links</h3>
                        <ul>
                            <li><strong>API Documentation</strong>: <a href="https://stampsmart.ngrok.app/docs" target="_blank">https://stampsmart.ngrok.app/docs</a></li>
                            <li><strong>Quick Setup Guides</strong>: Check guides 01-15 in this documentation</li>
                            <li><strong>Social Login Setup</strong>: Check guides 12-15 for social authentication</li>
                        </ul>

                        <p>Remember: API integration connects your mobile app to your website. If you're not technical, don't hesitate to ask your developer for help!</p>
                    `
                }
            ]
        },
        {
            id: 'quick-setup',
            title: 'Quick Setup (5-15 min each)',
            subsections: [
                {
                    id: 'theme-colors',
                    title: '1. Theme Colors',
                    content: `
                        <h1>Changing Theme Colors</h1>

                        <h2>Primary Colors</h2>
                        <p>To modify the primary colors of the application:</p>

                        <ol>
                            <li>Navigate to <code>lib/theme/app_theme.dart</code></li>
                            <li>Locate the <code>AppTheme</code> class</li>
                            <li>Modify the following properties:
                                <pre><code>static const Color primaryColor = Color(0xFFYOUR_COLOR);
static const Color secondaryColor = Color(0xFFYOUR_COLOR);</code></pre>
                            </li>
                        </ol>

                        <h2>Customizing Color Schemes</h2>
                        <p>For more detailed color customization:</p>

                        <ol>
                            <li>Open <code>lib/theme/app_theme.dart</code></li>
                            <li>Find the <code>lightTheme</code> and <code>darkTheme</code> methods</li>
                            <li>Modify the <code>ColorScheme</code> properties as needed:
                                <pre><code>ColorScheme(
  primary: YOUR_PRIMARY_COLOR,
  secondary: YOUR_SECONDARY_COLOR,
  // ... other color properties
)</code></pre>
                            </li>
                        </ol>

                        <h2>Screenshots</h2>
                        <img src="images/primary-color-config.png" alt="Theme Colors Configuration" />
                        <p><em>Example of theme color configuration in the app</em></p>
                    `
                },
                {
                    id: 'app-font',
                    title: '2. App Font',
                    content: `
                        <h1>Changing App Font</h1>

                        <p>The app uses Google Fonts with Inter as the default font. To modify the font:</p>

                        <ol>
                            <li>Open <code>lib/src/theme/app_fonts.dart</code></li>
                            <li>Update the font style:
                                <pre><code>const kAppTextStyle = GoogleFonts.YOUR_FONT_NAME;</code></pre>
                            </li>
                        </ol>

                        <p>Available Google Fonts can be found at <a href="https://fonts.google.com/" target="_blank">Google Fonts</a>.</p>

                        <h2>Screenshots</h2>
                        <img src="images/primary-font-config.png" alt="Font Configuration" />
                        <p><em>Example of font configuration in the app</em></p>
                    `
                },
                {
                    id: 'ad-keys',
                    title: '3. Ad Keys',
                    content: `
                        <h1>Setting Up Ad Keys</h1>

                        <h2>Home Screen Ad Configuration</h2>
                        <p>The app uses three different ad placements in the home screen:</p>

                        <ol>
                            <li>Large Banner Ad</li>
                            <li>Small Banner Ad 1</li>
                            <li>Small Banner Ad 2</li>
                        </ol>

                        <img src="images/home-ads.png" alt="Home ads" />

                        <h2>Configuration Methods</h2>

                        <h3>Method 1: Environment Variables (Recommended)</h3>
                        <p>The app supports environment variable configuration for ad keys. This is the recommended approach for production deployments.</p>

                        <ol>
                            <li>Create or update your <code>.env</code> file in the root directory</li>
                            <li>Add the following ad key variables:
                                <pre><code>LARGE_AD_KEY=your_large_ad_key_here
SMALL_AD_KEY_1=your_small_ad_key_1_here
SMALL_AD_KEY_2=your_small_ad_key_2_here</code></pre>
                            </li>
                        </ol>

                        <h3>Method 2: Direct Code Configuration</h3>
                        <p>You can also configure ad keys directly in the code by modifying <code>lib/core/app_config.dart</code>:</p>

                        <pre><code>static String largeAdKey = dotenv.env['LARGE_AD_KEY'] ?? 'YOUR_LARGE_AD_KEY';
static String smallAdKey1 = dotenv.env['SMALL_AD_KEY_1'] ?? 'YOUR_SMALL_AD_KEY_1';
static String smallAdKey2 = dotenv.env['SMALL_AD_KEY_2'] ?? 'YOUR_SMALL_AD_KEY_2';</code></pre>

                        <h2>Default Values</h2>
                        <p>The app includes default ad keys for testing purposes:</p>
                        <ul>
                            <li>Large Ad Key: <code>Q9YDUIC9HSWS</code></li>
                            <li>Small Ad Key 1: <code>NBDWRXTSVZ8N</code></li>
                            <li>Small Ad Key 2: <code>VC2C8Q1UGCBG</code></li>
                        </ul>
                        <p>These defaults will be used if no environment variables are set.</p>

                        <h2>Admin Panel Configuration</h2>
                        <p>These ad keys correspond to the ad placements in your admin panel. You can set the actual ad content for each key in your admin panel at <code>https://your-domain/admin/ads</code>.</p>

                        <h2>Environment Variable Priority</h2>
                        <p>The app follows this priority order for ad key configuration:</p>
                        <ol>
                            <li>Environment variables (<code>.env</code> file)</li>
                            <li>Default values (hardcoded in <code>app_config.dart</code>)</li>
                        </ol>

                        <h2>Screenshots</h2>
                        <img src="images/ads-config.png" alt="Ad Configuration" />
                        <p><em>Example of ad key configuration in app_config.dart</em></p>

                        <img src="images/ads-config-admin.png" alt="Admin Panel Configuration" />
                        <p><em>Example of ad configuration in admin panel</em></p>

                        <h2>Troubleshooting</h2>
                        <ul>
                            <li>If ads are not loading, check that your ad keys are correctly configured</li>
                            <li>Ensure your admin panel has content set for the configured ad keys</li>
                            <li>Verify that the API endpoint is accessible and returning ad data</li>
                            <li>Check the app logs for any ad-related error messages</li>
                        </ul>
                    `
                },
                {
                    id: 'app-name',
                    title: '4. App Name',
                    content: `
                        <h1>Changing App Name</h1>

                        <img src="images/change-app-name.png" alt="App name" />

                        <h2>Android</h2>

                        <ol>
                            <li>Open <code>android/app/src/main/AndroidManifest.xml</code></li>
                            <li>Update the <code>android:label</code> attribute:
                                <pre><code>&lt;application
    android:label="Your New App Name"
    ...
&gt;</code></pre>
                            </li>
                        </ol>

                        <h2>iOS</h2>

                        <ol>
                            <li>Open <code>ios/Runner/Info.plist</code></li>
                            <li>Update the <code>CFBundleName</code> and <code>CFBundleDisplayName</code>:
                                <pre><code>&lt;key&gt;CFBundleName&lt;/key&gt;
&lt;string&gt;Your New App Name&lt;/string&gt;
&lt;key&gt;CFBundleDisplayName&lt;/key&gt;
&lt;string&gt;Your New App Name&lt;/string&gt;</code></pre>
                            </li>
                        </ol>
                    `
                },
                {
                    id: 'app-logo',
                    title: '5. App Logo',
                    content: `
                        <h1>Changing App Logo</h1>

                        <img src="images/change-app-logo.png" alt="App logo" />

                        <h2>Android</h2>
                        <ol>
                            <li>Replace the following files in <code>android/app/src/main/res/</code>:
                                <ul>
                                    <li><code>mipmap-hdpi/ic_launcher.png</code></li>
                                    <li><code>mipmap-mdpi/ic_launcher.png</code></li>
                                    <li><code>mipmap-xhdpi/ic_launcher.png</code></li>
                                    <li><code>mipmap-xxhdpi/ic_launcher.png</code></li>
                                    <li><code>mipmap-xxxhdpi/ic_launcher.png</code></li>
                                </ul>
                            </li>
                            <li>Update <code>android/app/src/main/AndroidManifest.xml</code>:
                                <pre><code>&lt;application
    android:icon="@mipmap/ic_launcher"
    ...
&gt;</code></pre>
                            </li>
                        </ol>

                        <h2>iOS</h2>
                        <ol>
                            <li>Replace the following files in <code>ios/Runner/Assets.xcassets/AppIcon.appiconset/</code>:
                                <ul>
                                    <li>All icon files in various sizes</li>
                                </ul>
                            </li>
                            <li>Update <code>ios/Runner/Info.plist</code>:
                                <pre><code>&lt;key&gt;CFBundleIconName&lt;/key&gt;
&lt;string&gt;AppIcon&lt;/string&gt;</code></pre>
                            </li>
                        </ol>
                    `
                },
                {
                    id: 'api-base-url',
                    title: '6. API Base URL',
                    content: `
                        <h1>Configuring API Base URL</h1>

                        <p>The API base URL is used to connect your app to the backend server. To configure it:</p>

                        <ol>
                            <li>Open <code>.env</code> file in the root directory</li>
                            <li>Update the <code>API_BASE_URL</code> variable:
                                <pre><code>API_BASE_URL=https://your-domain.com</code></pre>
                            </li>
                        </ol>

                        <p>If the <code>.env</code> file doesn't exist:</p>
                        <ol>
                            <li>Copy <code>.env.example</code> to <code>.env</code></li>
                            <li>Update the <code>API_BASE_URL</code> variable</li>
                        </ol>

                        <p>The default API base URL is <code>https://stampsmart.ngrok.app</code> if not specified.</p>

                        <h2>Important Notes</h2>
                        <ul>
                            <li>Make sure to use HTTPS for production environments</li>
                            <li>The URL should not end with a trailing slash (/)</li>
                            <li>The URL should be accessible from your app's target devices</li>
                            <li>For local development, you can use <code>http://localhost:8000</code> or your local IP address</li>
                        </ul>
                    `
                },
                {
                    id: 'translations',
                    title: '7. Translations',
                    content: `
                        <h1>Configuring Translations</h1>

                        <p>The app uses <code>easy_localization</code> for managing multiple languages. Translations are stored in JSON files under the <code>assets/translations</code> directory.</p>

                        <h2>Adding/Modifying Translations</h2>

                        <ol>
                            <li>Navigate to <code>assets/translations/</code></li>
                            <li>Each language has its own JSON file (e.g., <code>en.json</code>, <code>vi.json</code>, <code>ar.json</code>)</li>
                            <li>Update or add new translations in the format:
                                <pre><code>{
  "key": "translated text",
  "nested": {
    "key": "nested translated text"
  }
}</code></pre>
                            </li>
                        </ol>

                        <h2>Supported Languages</h2>
                        <p>The app currently supports:</p>
                        <ul>
                            <li>English (en)</li>
                            <li>Vietnamese (vi)</li>
                            <li>Arabic (ar)</li>
                            <li>Bengali (bn)</li>
                            <li>Spanish (es)</li>
                            <li>French (fr)</li>
                            <li>Hindi (hi)</li>
                            <li>Indonesian (id)</li>
                        </ul>

                        <h2>Adding a New Language</h2>

                        <ol>
                            <li>Create a new JSON file in <code>assets/translations/</code> (e.g., <code>fr.json</code> for French)</li>
                            <li>Add the new locale in <code>lib/main.dart</code>:
                                <pre><code>supportedLocales: const [
  Locale('en'),
  Locale('vi'),
  Locale('ar'),
  // Add your new locale here
  Locale('fr'),
],</code></pre>
                            </li>
                        </ol>

                        <h2>Using Translations in Code</h2>

                        <ol>
                            <li>Import the translation package:
                                <pre><code>import 'package:easy_localization/easy_localization.dart';</code></pre>
                            </li>
                            <li>Use translations in your code:
                                <pre><code>// Simple translation
Text('hello'.tr())

// Translation with parameters
Text('welcome_user'.tr(args: ['John']))

// Pluralization
Text('items_count'.plural(5))</code></pre>
                            </li>
                        </ol>

                        <h2>Important Notes</h2>
                        <ul>
                            <li>Always use meaningful keys for translations</li>
                            <li>Keep translations organized in nested objects for better structure</li>
                            <li>Test all supported languages after making changes</li>
                            <li>Consider RTL (Right-to-Left) support for languages like Arabic</li>
                            <li>Keep translation files in sync across all languages</li>
                        </ul>
                    `
                },
                {
                    id: 'running-app',
                    title: '8. Running App',
                    content: `
                        <h1>Running the App</h1>

                        <h2>Development Mode</h2>
                        <p>To run the app in development mode:</p>

                        <ol>
                            <li>Make sure you have a device/emulator connected:
                                <pre><code>flutter devices</code></pre>
                            </li>
                            <li>Run the app:
                                <pre><code>flutter run</code></pre>
                            </li>
                        </ol>

                        <h2>Debug Mode</h2>
                        <p>For debugging purposes:</p>
                        <pre><code>flutter run --debug</code></pre>

                        <h2>Release Mode (Local Testing)</h2>
                        <p>To test the release version locally:</p>
                        <pre><code>flutter run --release</code></pre>

                        <h2>Profile Mode</h2>
                        <p>For performance profiling:</p>
                        <pre><code>flutter run --profile</code></pre>

                        <h2>Common Issues and Solutions</h2>
                        <ol>
                            <li><strong>Missing Dependencies</strong>
                                <pre><code>flutter pub get</code></pre>
                            </li>
                            <li><strong>Clean Build</strong>
                                <pre><code>flutter clean
flutter pub get
flutter run</code></pre>
                            </li>
                            <li><strong>Hot Reload/Restart</strong>
                                <ul>
                                    <li>Press <code>r</code> for hot reload</li>
                                    <li>Press <code>R</code> for hot restart</li>
                                    <li>Press <code>q</code> to quit</li>
                                </ul>
                            </li>
                        </ol>
                    `
                },
                {
                    id: 'deploying-app',
                    title: '9. Deploying App',
                    content: `
                        <h1>Deploying the App</h1>

                        <h2>Android Deployment</h2>

                        <ol>
                            <li><strong>Generate Keystore</strong>
                                <pre><code>keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload</code></pre>
                            </li>
                            <li><strong>Configure Keystore</strong><br>
                                Create/update <code>android/key.properties</code>:
                                <pre><code>storePassword=&lt;password&gt;
keyPassword=&lt;password&gt;
keyAlias=upload
storeFile=&lt;path to keystore&gt;</code></pre>
                            </li>
                            <li><strong>Update build.gradle</strong><br>
                                In <code>android/app/build.gradle</code>:
                                <pre><code>def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
keystoreProperties.load(new FileInputStream(keystorePropertiesFile))

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
}</code></pre>
                            </li>
                            <li><strong>Build Release APK</strong>
                                <pre><code>flutter build apk --release</code></pre>
                            </li>
                            <li><strong>Build App Bundle</strong>
                                <pre><code>flutter build appbundle</code></pre>
                            </li>
                        </ol>

                        <h2>iOS Deployment</h2>

                        <ol>
                            <li><strong>Setup Apple Developer Account</strong>
                                <ul>
                                    <li>Enroll in Apple Developer Program</li>
                                    <li>Create App ID in Apple Developer Portal</li>
                                    <li>Create Distribution Certificate</li>
                                    <li>Create Provisioning Profile</li>
                                </ul>
                            </li>
                            <li><strong>Configure Xcode</strong>
                                <ul>
                                    <li>Open <code>ios/Runner.xcworkspace</code></li>
                                    <li>Update Bundle Identifier</li>
                                    <li>Configure Signing & Capabilities</li>
                                    <li>Set Version and Build numbers</li>
                                </ul>
                            </li>
                            <li><strong>Build for App Store</strong>
                                <pre><code>flutter build ios --release</code></pre>
                            </li>
                            <li><strong>Archive and Upload</strong>
                                <ul>
                                    <li>Open Xcode</li>
                                    <li>Select Product > Archive</li>
                                    <li>Use Xcode Organizer to upload to App Store</li>
                                </ul>
                            </li>
                        </ol>

                        <h2>Important Notes</h2>
                        <ul>
                            <li>Always test thoroughly before deployment</li>
                            <li>Keep your keystore and certificates secure</li>
                            <li>Follow platform-specific guidelines</li>
                            <li>Consider using CI/CD for automated deployment</li>
                            <li>Keep track of version numbers</li>
                            <li>Test on multiple devices before release</li>
                        </ul>
                    `
                },
                {
                    id: 'version-management',
                    title: '10. Version Management',
                    content: `
                        <h1>Version Management</h1>

                        <h2>Android Version</h2>

                        <ol>
                            <li><strong>Update pubspec.yaml</strong>
                                <pre><code>version: 1.0.0+1  # Format: version_name+version_code</code></pre>
                            </li>
                            <li><strong>Update Android Manifest</strong><br>
                                In <code>android/app/src/main/AndroidManifest.xml</code>:
                                <pre><code>&lt;manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.app"
    android:versionCode="1"
    android:versionName="1.0.0"&gt;</code></pre>
                            </li>
                        </ol>

                        <h2>iOS Version</h2>

                        <ol>
                            <li><strong>Update pubspec.yaml</strong>
                                <pre><code>version: 1.0.0+1  # Format: version_name+version_code</code></pre>
                            </li>
                            <li><strong>Update Info.plist</strong><br>
                                In <code>ios/Runner/Info.plist</code>:
                                <pre><code>&lt;key&gt;CFBundleShortVersionString&lt;/key&gt;
&lt;string&gt;1.0.0&lt;/string&gt;
&lt;key&gt;CFBundleVersion&lt;/key&gt;
&lt;string&gt;1&lt;/string&gt;</code></pre>
                            </li>
                        </ol>

                        <h2>Version Numbering</h2>

                        <ul>
                            <li><strong>Version Name (e.g., 1.0.0)</strong>
                                <ul>
                                    <li>First number: Major version (breaking changes)</li>
                                    <li>Second number: Minor version (new features)</li>
                                    <li>Third number: Patch version (bug fixes)</li>
                                </ul>
                            </li>
                            <li><strong>Version Code (e.g., 1)</strong>
                                <ul>
                                    <li>Increment for each new release</li>
                                    <li>Must be higher than previous version</li>
                                    <li>Used by app stores for updates</li>
                                </ul>
                            </li>
                        </ul>

                        <h2>Best Practices</h2>

                        <ol>
                            <li><strong>Version Synchronization</strong>
                                <ul>
                                    <li>Keep version numbers consistent across platforms</li>
                                    <li>Update all version numbers before release</li>
                                    <li>Document version changes in changelog</li>
                                </ul>
                            </li>
                            <li><strong>Release Process</strong>
                                <ul>
                                    <li>Increment version numbers</li>
                                    <li>Update changelog</li>
                                    <li>Tag release in version control</li>
                                    <li>Build release version</li>
                                    <li>Submit to app stores</li>
                                </ul>
                            </li>
                            <li><strong>Version Control</strong>
                                <pre><code># Tag release
git tag -a v1.0.0 -m "Version 1.0.0"
git push origin v1.0.0</code></pre>
                            </li>
                            <li><strong>Changelog Example</strong>
                                <pre><code># Changelog

## [1.0.0] - 2024-03-20
- Initial release
- Basic features implemented
- Bug fixes

## [0.9.0] - 2024-03-15
- Beta release
- Feature X added
- Performance improvements</code></pre>
                            </li>
                        </ol>
                    `
                },
                {
                    id: 'profile-links',
                    title: '11. Profile Links',
                    content: `
                        <h1>Profile Screen External Links</h1>

                        <img src="images/profile-links.png" alt="Profile links" />

                        <h2>Configuration</h2>

                        <p>The external links are configured in <code>lib/core/app_config.dart</code>:</p>
                        <pre><code>static const String helpCenterUrl = 'https://stampsmart.ngrok.app/contact';
static const String customerSupportUrl = 'https://stampsmart.ngrok.app/contact';
static const String blogUrl = 'https://stampsmart.ngrok.app/blog';</code></pre>

                        <h2>Implementation</h2>

                        <p>The profile screen (<code>lib/src/view/screen/profile_screen.dart</code>) includes a "Support" section with three external links:</p>

                        <ol>
                            <li><strong>Help Center</strong>
                                <ul>
                                    <li>Icon: <code>Icons.help_outline</code></li>
                                    <li>Opens <code>AppConfig.helpCenterUrl</code> in a WebView</li>
                                    <li>Translation key: <code>profile.help_center</code></li>
                                </ul>
                            </li>
                            <li><strong>Customer Service</strong>
                                <ul>
                                    <li>Icon: <code>Icons.headset_mic_outlined</code></li>
                                    <li>Opens <code>AppConfig.customerSupportUrl</code> in a WebView</li>
                                    <li>Translation key: <code>profile.customer_service</code></li>
                                </ul>
                            </li>
                            <li><strong>Blog</strong>
                                <ul>
                                    <li>Icon: <code>Icons.article_outlined</code></li>
                                    <li>Opens <code>AppConfig.blogUrl</code> in a WebView</li>
                                    <li>Translation key: <code>profile.blog</code></li>
                                </ul>
                            </li>
                        </ol>

                        <h2>Usage</h2>

                        <p>Each link is implemented using the <code>_buildMenuItem</code> widget:</p>
                        <pre><code>_buildMenuItem(
  'profile.help_center'.tr(),
  Icons.help_outline,
  onTap: (context) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => WebViewScreen(
        url: AppConfig.helpCenterUrl,
        title: 'profile.help_center'.tr(),
      ),
    ),
  ),
),</code></pre>

                        <h2>Best Practices</h2>

                        <ol>
                            <li><strong>URL Configuration</strong>
                                <ul>
                                    <li>Keep URLs in <code>AppConfig</code> for easy maintenance</li>
                                    <li>Use HTTPS for all external links</li>
                                    <li>Update URLs in one central location</li>
                                </ul>
                            </li>
                            <li><strong>User Experience</strong>
                                <ul>
                                    <li>Use appropriate icons for each link</li>
                                    <li>Provide clear labels using translations</li>
                                    <li>Open links in WebView for better user experience</li>
                                </ul>
                            </li>
                            <li><strong>Security</strong>
                                <ul>
                                    <li>Validate URLs before opening</li>
                                    <li>Use HTTPS links</li>
                                    <li>Handle WebView errors gracefully</li>
                                </ul>
                            </li>
                            <li><strong>Internationalization</strong>
                                <ul>
                                    <li>All labels are translatable</li>
                                    <li>Support RTL layouts</li>
                                    <li>Use translation keys for consistency</li>
                                </ul>
                            </li>
                        </ol>

                        <h2>Example Usage</h2>

                        <pre><code>class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: profileLinks.length,
      itemBuilder: (context, index) {
        return buildLinkItem(profileLinks[index]);
      },
    );
  }
}</code></pre>
                    `
                }
            ]
        },
        {
            id: 'social-login',
            title: 'Social Login (30-60 min each)',
            subsections: [
                {
                    id: 'twitter-login',
                    title: '12. Twitter/X Login',
                    content: `
                        <h1>Twitter/X Login Setup</h1>

                        <h2>Prerequisites</h2>
                        <ul>
                            <li>Twitter Developer Account</li>
                            <li>Twitter App created in Developer Portal</li>
                        </ul>

                        <h2>Step 1: Create Twitter App</h2>
                        <ol>
                            <li>Go to <a href="https://developer.twitter.com" target="_blank">Twitter Developer Portal</a></li>
                            <li>Create a new app</li>
                            <li>Get your Consumer Key and Consumer Secret</li>
                        </ol>

                        <h2>Step 2: Configure Environment</h2>
                        <p>Create or update your <code>.env</code> file with the following variables:</p>
                        <pre><code>TWITTER_CONSUMER_KEY=your_twitter_consumer_key
TWITTER_CONSUMER_SECRET=your_twitter_consumer_secret
TWITTER_REDIRECT_URI=martfury://twitter-auth</code></pre>

                        <h2>Step 3: Test Integration</h2>
                        <ol>
                            <li>Restart your app</li>
                            <li>Try Twitter login</li>
                            <li>Verify authentication works</li>
                        </ol>
                    `
                },
                {
                    id: 'apple-login',
                    title: '13. Apple Sign-In',
                    content: `
                        <h1>Apple Sign-In Setup</h1>

                        <h2>Prerequisites</h2>
                        <ul>
                            <li>Apple Developer Account ($99/year)</li>
                            <li>App ID configured in Apple Developer Portal</li>
                        </ul>

                        <h2>Step 1: Configure Apple Developer Account</h2>
                        <ol>
                            <li>Go to Apple Developer Portal</li>
                            <li>Create App ID with Sign In with Apple capability</li>
                            <li>Get your Service ID, Team ID, and Key ID</li>
                        </ol>

                        <h2>Step 2: Configure Environment</h2>
                        <p>Create or update your <code>.env</code> file with the following variables:</p>
                        <pre><code>APPLE_SERVICE_ID=your_apple_service_id
APPLE_TEAM_ID=your_apple_team_id
APPLE_KEY_ID=your_apple_key_id</code></pre>

                        <h2>Step 3: Test Integration</h2>
                        <ol>
                            <li>Restart your app</li>
                            <li>Try Apple Sign-In</li>
                            <li>Verify authentication works</li>
                        </ol>
                    `
                },
                {
                    id: 'google-login',
                    title: '14. Google Login',
                    content: `
                        <h1>Google Login Setup</h1>

                        <h2>Prerequisites</h2>
                        <ul>
                            <li>Google Cloud Console account</li>
                            <li>OAuth 2.0 credentials configured</li>
                        </ul>

                        <h2>Step 1: Configure Google Cloud Console</h2>
                        <ol>
                            <li>Go to Google Cloud Console</li>
                            <li>Create OAuth 2.0 credentials</li>
                            <li>Get your Client ID and Server Client ID</li>
                        </ol>

                        <h2>Step 2: Configure Environment</h2>
                        <p>Create or update your <code>.env</code> file with the following variables:</p>
                        <pre><code>GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_SERVER_CLIENT_ID=your_google_server_client_id</code></pre>

                        <h2>Step 3: Configure Android</h2>
                        <p>And in your app's <code>build.gradle</code>:</p>
                        <pre><code>defaultConfig {
    // ...
    manifestPlaceholders += [
        'appAuthRedirectScheme': 'com.googleusercontent.apps.YOUR_CLIENT_ID'
    ]
}</code></pre>

                        <h2>Step 4: Test Integration</h2>
                        <ol>
                            <li>Restart your app</li>
                            <li>Try Google login</li>
                            <li>Verify authentication works</li>
                        </ol>
                    `
                },
                {
                    id: 'facebook-login',
                    title: '15. Facebook Login',
                    content: `
                        <h1>Facebook Login Setup</h1>

                        <h2>Prerequisites</h2>
                        <ul>
                            <li>Facebook Developer Account</li>
                            <li>Facebook App created in Developer Portal</li>
                        </ul>

                        <h2>Step 1: Create Facebook App</h2>
                        <ol>
                            <li>Go to Facebook Developer Portal</li>
                            <li>Create a new app</li>
                            <li>Get your App ID and Client Token</li>
                        </ol>

                        <h2>Step 2: Configure Environment</h2>
                        <p>Create or update your <code>.env</code> file with the following variables:</p>
                        <pre><code>FACEBOOK_APP_ID=your_facebook_app_id
FACEBOOK_CLIENT_TOKEN=your_facebook_client_token</code></pre>

                        <h2>Step 3: Configure Android</h2>
                        <p>And in your app's <code>build.gradle</code>:</p>
                        <pre><code>defaultConfig {
    // ...
    manifestPlaceholders += [
        'facebookAppId': 'YOUR_APP_ID',
        'facebookClientToken': 'YOUR_CLIENT_TOKEN'
    ]
}</code></pre>

                        <h2>Step 4: Test Integration</h2>
                        <ol>
                            <li>Restart your app</li>
                            <li>Try Facebook login</li>
                            <li>Verify authentication works</li>
                        </ol>
                    `
                }
            ]
        },
        {
            id: 'help-support',
            title: 'Help & Support',
            subsections: [
                {
                    id: 'support',
                    title: 'Support & Contact',
                    content: `
                        <h1>Support & Contact Information</h1>

                        <p>Need help with your MartFury Flutter app? We're here to support you every step of the way!</p>

                        <h2>🆘 Quick Help</h2>

                        <h3>Before Contacting Support:</h3>
                        <ol>
                            <li><strong>Check the FAQ</strong> - Most common questions are answered here</li>
                            <li><strong>Try the Troubleshooting Guide</strong> - Step-by-step problem solving</li>
                            <li><strong>Read the relevant setup guide</strong> - Guides 01-15 cover most setup issues</li>
                            <li><strong>Test on your website first</strong> - Make sure your website works before testing the app</li>
                        </ol>

                        <h2>📞 Contact Options</h2>

                        <h3>📖 <strong>Read the Documentation</strong></h3>
                        <p><strong>https://docs.botble.com/martfury-flutter</strong></p>
                        <ul>
                            <li>Complete guides and tutorials</li>
                            <li>Step-by-step instructions</li>
                            <li>Updated regularly with new features</li>
                        </ul>

                        <h3>🎫 <strong>Submit Support Ticket</strong></h3>
                        <p><strong>https://botble.ticksy.com</strong></p>
                        <ul>
                            <li>For technical issues and bugs</li>
                            <li>Account and licensing questions</li>
                            <li>Custom development requests</li>
                            <li>Response within 24-48 hours</li>
                        </ul>

                        <h3>💬 <strong>Join Our Community</strong></h3>
                        <p><strong>Forums</strong>: https://forums.botble.com</p>
                        <p><strong>Facebook Group</strong>: https://www.facebook.com/groups/botble.technologies</p>
                        <ul>
                            <li>Get tips from other users</li>
                            <li>Share experiences and solutions</li>
                            <li>Ask questions to the community</li>
                            <li>Learn best practices</li>
                        </ul>

                        <h3>📧 <strong>Email Us Directly</strong></h3>
                        <p><strong>contact@botble.com</strong></p>
                        <ul>
                            <li>General inquiries</li>
                            <li>Business questions</li>
                            <li>Partnership opportunities</li>
                            <li>Feedback and suggestions</li>
                        </ul>

                        <h2>🎯 How to Get the Best Support</h2>

                        <h3>When Submitting a Ticket:</h3>

                        <h4>✅ <strong>Include This Information:</strong></h4>
                        <ul>
                            <li><strong>What you were trying to do</strong> (step-by-step)</li>
                            <li><strong>What happened instead</strong> (exact error message)</li>
                            <li><strong>What you already tried</strong> (troubleshooting steps)</li>
                            <li><strong>Your setup details</strong>:
                                <ul>
                                    <li>Your website URL</li>
                                    <li>Flutter version (<code>flutter --version</code>)</li>
                                    <li>Device/computer you're using</li>
                                    <li>Which guide you were following</li>
                                </ul>
                            </li>
                        </ul>

                        <h4>✅ <strong>Attach These Files (if relevant):</strong></h4>
                        <ul>
                            <li>Screenshots of error messages</li>
                            <li>Your <code>.env</code> file (remove sensitive info)</li>
                            <li>Console/terminal output</li>
                            <li>Relevant configuration files</li>
                        </ul>

                        <h4>❌ <strong>Don't Include:</strong></h4>
                        <ul>
                            <li>Passwords or API keys</li>
                            <li>Customer personal information</li>
                            <li>Unrelated questions in the same ticket</li>
                        </ul>

                        <h3>Response Times:</h3>
                        <ul>
                            <li><strong>Support Tickets</strong>: 24-48 hours</li>
                            <li><strong>Community Forums</strong>: Usually same day</li>
                            <li><strong>Email</strong>: 2-3 business days</li>
                        </ul>

                        <h2>🔧 Self-Help Resources</h2>

                        <h3>📚 <strong>Documentation</strong></h3>
                        <ul>
                            <li><strong>Installation Guide</strong> - Get started</li>
                            <li><strong>Configuration Guide</strong> - Basic setup</li>
                            <li><strong>Quick Setup Guides</strong> - Customize your app</li>
                            <li><strong>Social Login Setup</strong> - Add social features</li>
                        </ul>

                        <h3>🚨 <strong>Common Issues</strong></h3>
                        <ul>
                            <li><strong>FAQ</strong> - Quick answers to common questions</li>
                            <li><strong>Troubleshooting</strong> - Fix problems yourself</li>
                            <li><strong>Upgrade Guide</strong> - Update safely</li>
                        </ul>

                        <h3>🌐 <strong>External Resources</strong></h3>
                        <ul>
                            <li><strong><a href="https://flutter.dev/docs" target="_blank">Flutter Documentation</a></strong> - Learn Flutter</li>
                            <li><strong><a href="https://martfury.botble.com" target="_blank">Botble Backend Demo</a></strong> - See how it works</li>
                            <li><strong><a href="https://stampsmart.ngrok.app/docs" target="_blank">API Documentation</a></strong> - Technical details</li>
                        </ul>

                        <h2>💡 Tips for Success</h2>

                        <h3>Before You Start:</h3>
                        <ul>
                            <li>Read the overview and installation guide completely</li>
                            <li>Make sure you have all requirements</li>
                            <li>Set aside enough time (don't rush)</li>
                            <li>Have your website working perfectly first</li>
                        </ul>

                        <h3>When You Get Stuck:</h3>
                        <ul>
                            <li>Take a break and come back fresh</li>
                            <li>Try the "magic fix": <code>flutter clean</code> then <code>flutter pub get</code></li>
                            <li>Check if others had the same problem (search forums)</li>
                            <li>Ask for help early rather than struggling alone</li>
                        </ul>

                        <h3>Working with Support:</h3>
                        <ul>
                            <li>Be patient - we want to help you succeed</li>
                            <li>Provide complete information upfront</li>
                            <li>Follow up if you don't hear back in 48 hours</li>
                            <li>Let us know when your issue is resolved</li>
                        </ul>

                        <p><strong>Remember</strong>: Your success is our success! We're invested in helping you create an amazing mobile app for your customers.</p>
                    `
                },
                {
                    id: 'faq',
                    title: 'FAQ',
                    content: `
                        <h1>Frequently Asked Questions</h1>

                        <p>Simple answers to common questions about your MartFury mobile app.</p>

                        <h2>🤔 Basic Questions</h2>

                        <h3>What is this app?</h3>
                        <p>It's a mobile shopping app that connects to your website. Customers can browse products, shop, and place orders from their phones.</p>

                        <h3>Do I need to know programming?</h3>
                        <p>No! The app is ready to use. You just need to:</p>
                        <ul>
                            <li>Change your website URL</li>
                            <li>Update colors and logo (optional)</li>
                            <li>Publish to app stores</li>
                        </ul>

                        <h3>How much does it cost to publish?</h3>
                        <ul>
                            <li><strong>Google Play Store:</strong> $25 one-time fee</li>
                            <li><strong>Apple App Store:</strong> $99 per year</li>
                            <li>You need developer accounts for both</li>
                        </ul>

                        <h3>Will it work with my website?</h3>
                        <p>Yes, if your website uses Botble E-commerce system. The app connects to your website automatically.</p>

                        <h2>📱 App Features</h2>

                        <h3>What can customers do?</h3>
                        <ul>
                            <li>Browse and search products</li>
                            <li>Add items to cart and wishlist</li>
                            <li>Login with email or social accounts (Google, Facebook, Apple)</li>
                            <li>Track their orders</li>
                            <li>Leave reviews</li>
                            <li>Compare products</li>
                            <li>Save addresses</li>
                        </ul>

                        <h3>What languages does it support?</h3>
                        <p>English, Vietnamese, Spanish, French, Arabic, Hindi, Bengali, Indonesian. You can add more languages easily.</p>

                        <h3>What payment methods work?</h3>
                        <ul>
                            <li>Credit/debit cards (Stripe)</li>
                            <li>PayPal</li>
                            <li>Cash on delivery</li>
                            <li>Regional options (Razorpay, Mollie, SSLCommerz)</li>
                        </ul>
                        <p><em>Note: Payment methods depend on your website setup.</em></p>

                        <h2>🔧 Setup Questions</h2>

                        <h3>How do I connect the app to my website?</h3>
                        <ol>
                            <li>Open the <code>.env</code> file</li>
                            <li>Change <code>API_BASE_URL=https://your-website.com</code></li>
                            <li>Save and test the app</li>
                        </ol>

                        <h3>How do I change the app colors?</h3>
                        <ol>
                            <li>Open <code>lib/src/theme/app_theme.dart</code></li>
                            <li>Change the color codes</li>
                            <li>Save and restart the app</li>
                        </ol>

                        <h2>🚨 Common Problems</h2>

                        <h3>App won't connect to my website</h3>
                        <ul>
                            <li>Check your website URL in <code>.env</code> file</li>
                            <li>Make sure your website is online</li>
                            <li>Contact your website developer</li>
                        </ul>

                        <h3>Login doesn't work</h3>
                        <ul>
                            <li>Test login on your website first</li>
                            <li>Make sure API is enabled on your website</li>
                            <li>Check internet connection</li>
                        </ul>

                        <h3>No products showing</h3>
                        <ul>
                            <li>Make sure you have products on your website</li>
                            <li>Check if categories are set up</li>
                            <li>Try refreshing the app</li>
                        </ul>

                        <h2>💡 Tips for Success</h2>

                        <h3>Before Publishing</h3>
                        <ul>
                            <li>Test the app thoroughly on different phones</li>
                            <li>Make sure all features work with your website</li>
                            <li>Check that payments work correctly</li>
                            <li>Test with real customers if possible</li>
                        </ul>

                        <h3>After Publishing</h3>
                        <ul>
                            <li>Monitor app reviews and ratings</li>
                            <li>Respond to customer feedback</li>
                            <li>Keep your website and app in sync</li>
                            <li>Update the app when needed</li>
                        </ul>

                        <p><strong>Remember:</strong> Most problems are simple to fix! Don't worry if you're not technical - the guides are written for beginners.</p>
                    `
                },
                {
                    id: 'troubleshooting',
                    title: 'Troubleshooting',
                    content: `
                        <h1>Troubleshooting Guide</h1>

                        <p>Simple solutions to common problems. Don't worry - most issues are easy to fix!</p>

                        <h2>🚨 Most Common Problems</h2>

                        <h3>App Won't Start</h3>
                        <p><strong>Problem:</strong> App crashes when you try to run it</p>
                        <p><strong>Quick Fix:</strong></p>
                        <pre><code>flutter clean
flutter pub get
flutter run</code></pre>

                        <p><strong>If that doesn't work:</strong></p>
                        <ul>
                            <li>Restart your computer</li>
                            <li>Check if Flutter is installed correctly</li>
                            <li>Make sure your phone/emulator is connected</li>
                        </ul>

                        <h3>Can't Connect to Website</h3>
                        <p><strong>Problem:</strong> App shows "connection error" or "network error"</p>
                        <p><strong>Quick Fix:</strong></p>
                        <ol>
                            <li>Check your <code>.env</code> file</li>
                            <li>Make sure <code>API_BASE_URL=https://your-website.com</code> is correct</li>
                            <li>Test your website in a browser first</li>
                        </ol>

                        <p><strong>Common mistakes:</strong></p>
                        <ul>
                            <li>Wrong website URL</li>
                            <li>Website is down</li>
                            <li>No internet connection</li>
                        </ul>

                        <h3>Login Doesn't Work</h3>
                        <p><strong>Problem:</strong> Users can't login to the app</p>
                        <p><strong>Quick Fix:</strong></p>
                        <ol>
                            <li>Test login on your website first</li>
                            <li>Make sure the website login works</li>
                            <li>Check if API is enabled on your website</li>
                        </ol>

                        <h3>No Products Showing</h3>
                        <p><strong>Problem:</strong> App loads but no products appear</p>
                        <p><strong>Quick Fix:</strong></p>
                        <ol>
                            <li>Make sure you have products on your website</li>
                            <li>Check if categories are set up correctly</li>
                            <li>Try refreshing the app (pull down on the screen)</li>
                        </ol>

                        <h2>🔧 Setup Problems</h2>

                        <h3>Colors Not Changing</h3>
                        <p><strong>Problem:</strong> Changed colors but app still looks the same</p>
                        <p><strong>Solution:</strong></p>
                        <ol>
                            <li>Make sure you saved the file</li>
                            <li>Stop the app completely</li>
                            <li>Run: <code>flutter clean</code></li>
                            <li>Start the app again</li>
                        </ol>

                        <h3>App Name Not Changing</h3>
                        <p><strong>Problem:</strong> Changed app name but it's still "MartFury"</p>
                        <p><strong>Solution:</strong></p>
                        <ol>
                            <li>Follow the App Name guide exactly</li>
                            <li>Change it in BOTH Android and iOS files</li>
                            <li>Rebuild the app completely</li>
                        </ol>

                        <h2>💡 Quick Fixes for Everything</h2>

                        <h3>The "Magic" Fix</h3>
                        <p>When nothing else works, try this:</p>
                        <pre><code>flutter clean
flutter pub get
flutter run</code></pre>
                        <p>This fixes about 80% of all problems!</p>

                        <h3>Restart Everything</h3>
                        <p>Sometimes you just need to restart:</p>
                        <ol>
                            <li>Close the app</li>
                            <li>Restart your phone/emulator</li>
                            <li>Restart your computer</li>
                            <li>Try again</li>
                        </ol>

                        <h3>Check the Basics</h3>
                        <p>Before asking for help:</p>
                        <ul>
                            <li>✅ Is your internet working?</li>
                            <li>✅ Is your website online?</li>
                            <li>✅ Did you save all your changes?</li>
                            <li>✅ Did you follow the guides exactly?</li>
                        </ul>

                        <h2>🆘 When to Ask for Help</h2>

                        <h3>You Should Try First</h3>
                        <ul>
                            <li>Read the error message carefully</li>
                            <li>Try the "magic fix" above</li>
                            <li>Check the setup guides</li>
                            <li>Restart everything</li>
                        </ul>

                        <h3>Ask for Help When</h3>
                        <ul>
                            <li>You get the same error after trying everything</li>
                            <li>You don't understand the error message</li>
                            <li>Something worked before but stopped working</li>
                            <li>You're completely stuck</li>
                        </ul>

                        <h3>How to Ask for Help</h3>
                        <p>When contacting support, include:</p>
                        <ol>
                            <li><strong>What you were trying to do</strong></li>
                            <li><strong>What error message you saw</strong> (screenshot if possible)</li>
                            <li><strong>What you already tried</strong></li>
                            <li><strong>Your website URL</strong></li>
                            <li><strong>What device/computer you're using</strong></li>
                        </ol>

                        <p><strong>Remember:</strong> There's no such thing as a stupid question! Everyone gets stuck sometimes, and most problems have simple solutions.</p>
                    `
                },
                {
                    id: 'upgrade',
                    title: 'Upgrade Guide',
                    content: `
                        <h1>Upgrading Your App</h1>

                        <p>Simple guide to update your MartFury app to the latest version.</p>

                        <h2>🚨 Before You Start</h2>

                        <h3>⚠️ Important: Make a Backup!</h3>
                        <p><strong>Save your current app first:</strong></p>
                        <ol>
                            <li>Copy your entire app folder to a safe place</li>
                            <li>Name it something like "martfury-backup-old-version"</li>
                            <li>This way you can go back if something goes wrong</li>
                        </ol>

                        <p><strong>Save your settings:</strong></p>
                        <ul>
                            <li>Copy your <code>.env</code> file</li>
                            <li>Save any color/logo changes you made</li>
                            <li>Write down your website URL</li>
                        </ul>

                        <h2>📱 Simple Upgrade Steps</h2>

                        <h3>Step 1: Download New Version</h3>
                        <ol>
                            <li>Download the latest app version</li>
                            <li>Extract it to a new folder</li>
                            <li>Don't delete your old version yet!</li>
                        </ol>

                        <h3>Step 2: Copy Your Settings</h3>
                        <ol>
                            <li><strong>Copy your <code>.env</code> file</strong> from old app to new app</li>
                            <li><strong>Copy your changes:</strong>
                                <ul>
                                    <li>If you changed colors: copy your theme files</li>
                                    <li>If you changed logo: copy your logo files</li>
                                    <li>If you added translations: copy your translation files</li>
                                </ul>
                            </li>
                        </ol>

                        <h3>Step 3: Update the App</h3>
                        <ol>
                            <li>Open terminal/command prompt</li>
                            <li>Go to your new app folder</li>
                            <li>Run these commands:
                                <pre><code>flutter clean
flutter pub get
flutter run</code></pre>
                            </li>
                        </ol>

                        <h3>Step 4: Test Everything</h3>
                        <p><strong>Test basic features:</strong></p>
                        <ul>
                            <li>Login/logout</li>
                            <li>Browse products</li>
                            <li>Add to cart</li>
                            <li>Search</li>
                        </ul>

                        <p><strong>Test your customizations:</strong></p>
                        <ul>
                            <li>Check if your colors are right</li>
                            <li>Check if your logo shows</li>
                            <li>Test your website connection</li>
                        </ul>

                        <p><strong>If something is wrong:</strong></p>
                        <ul>
                            <li>Go back to your backup</li>
                            <li>Contact support for help</li>
                            <li>Don't panic - your backup is safe!</li>
                        </ul>

                        <h2>💡 Tips for Success</h2>

                        <h3>Before Upgrading</h3>
                        <ul>
                            <li>✅ Read what's new in the update</li>
                            <li>✅ Make sure you have time to fix problems</li>
                            <li>✅ Don't upgrade right before important deadlines</li>
                            <li>✅ Test on a copy first if possible</li>
                        </ul>

                        <h3>After Upgrading</h3>
                        <ul>
                            <li>📱 Test on real phones, not just computer</li>
                            <li>👥 Ask other people to test the app</li>
                            <li>📊 Monitor for any problems</li>
                            <li>🔄 Be ready to go back to old version if needed</li>
                        </ul>

                        <p><strong>Remember:</strong> Upgrading is optional! If your current app works well, you might not need to upgrade at all. Only upgrade when you really need new features or bug fixes.</p>
                    `
                },
                {
                    id: 'releases',
                    title: 'Release Notes',
                    content: `
                        <h1>Release Notes</h1>

                        <p>Check release notes on <a href="https://codecanyon.net/user/botble/portfolio" target="_blank">https://codecanyon.net/user/botble/portfolio</a>.</p>
                    `
                }
            ]
        }
    ]
};

// Export for use in other scripts
window.docsData = docsData;
