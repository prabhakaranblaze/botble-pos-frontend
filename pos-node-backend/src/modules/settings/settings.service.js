const { prisma } = require('../../config/database');

class SettingsService {
  // Cache for media settings (loaded once on startup)
  _mediaSettings = null;

  /**
   * Get media storage settings from database
   * Caches the result for performance
   */
  async getMediaSettings() {
    if (this._mediaSettings) {
      return this._mediaSettings;
    }

    try {
      // Fetch media_driver and media_r2_url from settings table
      const settings = await prisma.setting.findMany({
        where: {
          key: {
            in: ['media_driver', 'media_r2_url'],
          },
        },
      });

      const settingsMap = {};
      for (const s of settings) {
        settingsMap[s.key] = s.value;
      }

      this._mediaSettings = {
        driver: settingsMap['media_driver'] || 'public',
        r2Url: settingsMap['media_r2_url'] || null,
      };

      console.log('📦 Media settings loaded:', this._mediaSettings);
      return this._mediaSettings;
    } catch (e) {
      console.error('Error fetching media settings:', e);
      return { driver: 'public', r2Url: null };
    }
  }

  /**
   * Get the base URL for media/images based on media_driver setting
   * @returns {Promise<string>} Base URL for images
   */
  async getMediaBaseUrl() {
    const media = await this.getMediaSettings();

    if (media.driver === 'r2' && media.r2Url) {
      return media.r2Url;
    }

    // For 'public' driver, use STORAGE_URL from environment
    return process.env.STORAGE_URL || '';
  }

  /**
   * Build full image URL from relative path
   * @param {string} relativePath - Relative path from database (e.g., 'products/image.jpg')
   * @returns {Promise<string|null>} Full image URL
   */
  async buildImageUrl(relativePath) {
    if (!relativePath) return null;

    // If already a full URL, return as-is
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }

    const baseUrl = await this.getMediaBaseUrl();
    if (!baseUrl) return null;

    // Clean up the path
    const cleanPath = relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
    return `${baseUrl}/${cleanPath}`;
  }

  /**
   * Get POS settings including currency
   */
  async getSettings() {
    try {
      // Try to fetch currency settings from ec_currencies table
      const defaultCurrency = await prisma.$queryRaw`
        SELECT * FROM ec_currencies WHERE is_default = 1 LIMIT 1
      `;

      let currency = {
        code: 'SCR',
        symbol: 'SCR',
        name: 'Seychelles Rupee',
        decimal_digits: 2,
        is_prefix: false,
      };

      if (defaultCurrency && defaultCurrency.length > 0) {
        const curr = defaultCurrency[0];
        currency = {
          code: curr.title || 'SCR',
          symbol: curr.symbol || 'SCR',
          name: curr.title || 'Seychelles Rupee',
          decimal_digits: curr.decimals || 2,
          is_prefix: curr.is_prefix_symbol === 1,
        };
      }

      // Fetch formatting settings from settings table
      const formattingSettings = await prisma.setting.findMany({
        where: {
          key: {
            in: [
              'ecommerce_default_tax_rate',
              'ecommerce_tax_is_inclusive',
              'ecommerce_add_space_between_price_and_currency',
              'ecommerce_thousands_separator',
              'ecommerce_decimal_separator',
            ],
          },
        },
      });

      const settingsMap = {};
      for (const s of formattingSettings) {
        settingsMap[s.key] = s.value;
      }

      // Currency formatting options
      currency.add_space = settingsMap['ecommerce_add_space_between_price_and_currency'] === '1';
      currency.thousands_separator = settingsMap['ecommerce_thousands_separator'] || ',';
      currency.decimal_separator = settingsMap['ecommerce_decimal_separator'] || '.';

      // Tax settings
      let defaultTax = null;
      const taxIsInclusive = settingsMap['ecommerce_tax_is_inclusive'] === '1';

      try {
        const defaultTaxId = parseInt(settingsMap['ecommerce_default_tax_rate'] || '0');
        if (defaultTaxId > 0) {
          const taxRecord = await prisma.tax.findFirst({
            where: {
              id: BigInt(defaultTaxId),
              status: 'published',
              deleted_at: null,
            },
          });
          if (taxRecord) {
            defaultTax = {
              id: Number(taxRecord.id),
              title: taxRecord.title,
              percentage: parseFloat(taxRecord.percentage) || 0,
            };
          }
        }
      } catch (e) {
        console.warn('Error fetching default tax:', e.message);
      }

      return {
        currency,
        default_tax: defaultTax,
        tax_is_inclusive: taxIsInclusive,
        store_name: 'Seychelles Post POS',
      };
    } catch (e) {
      console.error('Error fetching settings:', e);
      // Return defaults if database query fails
      return {
        currency: {
          code: 'SCR',
          symbol: 'SCR',
          name: 'Seychelles Rupee',
          decimal_digits: 2,
          is_prefix: false,
          add_space: true,
          thousands_separator: ',',
          decimal_separator: '.',
        },
        default_tax: null,
        store_name: 'Seychelles Post POS',
      };
    }
  }
  // Cache for currency formatting settings
  _currencySettings = null;

  /**
   * Get cached currency settings (loads once from DB)
   */
  async getCurrencySettings() {
    if (this._currencySettings) {
      return this._currencySettings;
    }

    const settings = await this.getSettings();
    this._currencySettings = settings.currency;
    return this._currencySettings;
  }

  /**
   * Format a price amount using the configured currency settings
   * @param {number} amount
   * @returns {Promise<string>} Formatted price, e.g. "100.00 SCR"
   */
  async formatPrice(amount) {
    const curr = await this.getCurrencySettings();
    const space = curr.add_space ? ' ' : '';
    const decimals = curr.decimal_digits ?? 2;

    // Format number with separators
    const parts = amount.toFixed(decimals).split('.');
    const intPart = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, curr.thousands_separator || ',');
    const decPart = parts[1];
    const sep = curr.decimal_separator || '.';
    const formatted = decPart ? `${intPart}${sep}${decPart}` : intPart;

    if (curr.is_prefix) {
      return `${curr.symbol}${space}${formatted}`;
    }
    return `${formatted}${space}${curr.symbol}`;
  }
}

module.exports = new SettingsService();
