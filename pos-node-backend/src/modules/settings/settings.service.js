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

      // Get default tax from settings (stores tax_id, not percentage)
      // Using raw SQL to avoid Prisma model dependency
      let defaultTax = null;
      try {
        const taxSetting = await prisma.$queryRaw`
          SELECT * FROM settings WHERE \`key\` = 'ecommerce_default_tax_rate' LIMIT 1
        `;
        if (taxSetting && taxSetting.length > 0) {
          const defaultTaxId = parseInt(taxSetting[0].value);
          if (defaultTaxId > 0) {
            // Look up the actual tax record via raw SQL
            const taxRecords = await prisma.$queryRaw`
              SELECT id, title, percentage
              FROM ec_taxes
              WHERE id = ${defaultTaxId}
                AND status = 'published'
                AND deleted_at IS NULL
              LIMIT 1
            `;
            if (taxRecords && taxRecords.length > 0) {
              const taxRecord = taxRecords[0];
              defaultTax = {
                id: Number(taxRecord.id),
                title: taxRecord.title,
                percentage: parseFloat(taxRecord.percentage) || 0,
              };
            }
          }
        }
      } catch (e) {
        console.warn('Error fetching default tax:', e.message);
      }

      return {
        currency,
        default_tax: defaultTax,
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
        default_tax: null,
        store_name: 'StampSmart POS',
      };
    }
  }
}

module.exports = new SettingsService();
