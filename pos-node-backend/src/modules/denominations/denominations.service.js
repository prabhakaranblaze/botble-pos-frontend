const { prisma } = require('../../config/database');

class DenominationsService {
  /**
   * Get denominations by currency
   */
  async getDenominations(currency = 'USD') {
    const denominations = await prisma.posDenomination.findMany({
      where: {
        currency_code: currency.toUpperCase(),
        is_active: true,
        deleted_at: null,
      },
      orderBy: { sort_order: 'asc' },
    });

    return denominations.map((d) => ({
      id: Number(d.id),
      currency: d.currency_code,
      value: Number(d.value),
      type: d.type,
      display_name: d.label,
    }));
  }

  /**
   * Get all available currencies
   */
  async getAvailableCurrencies() {
    const currencies = await prisma.posDenomination.findMany({
      where: {
        is_active: true,
        deleted_at: null,
      },
      distinct: ['currency_code'],
      select: {
        currency_code: true,
      },
    });

    return currencies.map((c) => c.currency_code);
  }
}

module.exports = new DenominationsService();
