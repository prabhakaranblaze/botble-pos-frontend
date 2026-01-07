const { prisma } = require('../../config/database');

class SettingsService {
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
        symbol: 'Rs',
        name: 'Seychelles Rupee',
        decimal_digits: 2,
        is_prefix: false, // Symbol after amount (e.g., 100Rs)
      };

      if (defaultCurrency && defaultCurrency.length > 0) {
        const curr = defaultCurrency[0];
        currency = {
          code: curr.title || 'SCR',
          symbol: curr.symbol || 'Rs',
          name: curr.title || 'Seychelles Rupee',
          decimal_digits: curr.decimals || 2,
          is_prefix: curr.is_prefix_symbol === 1,
        };
      }

      // Try to get tax rate from settings
      let taxRate = 0.15; // Default 15% tax
      try {
        const taxSetting = await prisma.$queryRaw`
          SELECT * FROM settings WHERE key = 'ecommerce_tax_percentage' LIMIT 1
        `;
        if (taxSetting && taxSetting.length > 0) {
          taxRate = parseFloat(taxSetting[0].value) / 100 || 0.15;
        }
      } catch (e) {
        // Ignore - use default
      }

      return {
        currency,
        tax_rate: taxRate,
        store_name: 'StampSmart POS',
      };
    } catch (e) {
      console.error('Error fetching settings:', e);
      // Return defaults if database query fails
      return {
        currency: {
          code: 'SCR',
          symbol: 'Rs',
          name: 'Seychelles Rupee',
          decimal_digits: 2,
          is_prefix: false,
        },
        tax_rate: 0.15,
        store_name: 'StampSmart POS',
      };
    }
  }
}

module.exports = new SettingsService();
