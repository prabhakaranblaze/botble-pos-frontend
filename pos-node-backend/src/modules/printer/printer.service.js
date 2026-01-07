const config = require('../../config');

/**
 * Printer Service for ESC/POS thermal printers
 * Supports network and USB printers
 */
class PrinterService {
  constructor() {
    this.escpos = null;
    this.device = null;
    this.printer = null;
  }

  /**
   * Initialize printer connection
   */
  async initialize() {
    try {
      // Dynamically import escpos modules
      this.escpos = require('escpos');

      if (config.printer.type === 'network') {
        const Network = require('escpos-network');
        this.escpos.Network = Network;
        this.device = new this.escpos.Network(config.printer.host, config.printer.port);
      } else if (config.printer.type === 'usb') {
        const USB = require('escpos-usb');
        this.escpos.USB = USB;
        this.device = new this.escpos.USB();
      }

      console.log(`🖨️ Printer initialized: ${config.printer.type}`);
      return true;
    } catch (error) {
      console.error('Printer initialization failed:', error.message);
      return false;
    }
  }

  /**
   * Print receipt
   */
  async printReceipt(order) {
    if (!this.escpos || !this.device) {
      console.log('⚠️ Printer not initialized, skipping print');
      return false;
    }

    return new Promise((resolve, reject) => {
      this.device.open((err) => {
        if (err) {
          console.error('Printer open error:', err);
          return resolve(false);
        }

        try {
          this.printer = new this.escpos.Printer(this.device);

          // Header
          this.printer
            .font('a')
            .align('ct')
            .style('b')
            .size(1, 1)
            .text('StampSmart POS')
            .style('normal')
            .text('--------------------------------')
            .align('lt');

          // Order info
          this.printer
            .text(`Order: ${order.code}`)
            .text(`Date: ${new Date(order.created_at).toLocaleString()}`)
            .text('--------------------------------');

          // Items
          order.items.forEach((item) => {
            const lineTotal = (item.price * item.quantity).toFixed(2);
            this.printer
              .text(`${item.name}`)
              .text(`  ${item.quantity} x $${item.price.toFixed(2)}  = $${lineTotal}`);
          });

          // Totals
          this.printer
            .text('--------------------------------')
            .align('rt')
            .text(`Subtotal: $${order.sub_total.toFixed(2)}`)
            .text(`Tax: $${order.tax_amount.toFixed(2)}`)
            .style('b')
            .text(`TOTAL: $${order.amount.toFixed(2)}`)
            .style('normal')
            .text('--------------------------------')
            .align('ct')
            .text('Thank you for your purchase!')
            .text('')
            .text('')
            .cut()
            .close();

          console.log('✅ Receipt printed successfully');
          resolve(true);
        } catch (error) {
          console.error('Print error:', error);
          resolve(false);
        }
      });
    });
  }

  /**
   * Open cash drawer
   */
  async openCashDrawer() {
    if (!this.escpos || !this.device) {
      console.log('⚠️ Printer not initialized, cannot open drawer');
      return false;
    }

    return new Promise((resolve) => {
      this.device.open((err) => {
        if (err) {
          console.error('Device open error:', err);
          return resolve(false);
        }

        try {
          this.printer = new this.escpos.Printer(this.device);
          this.printer.cashdraw(2).close();
          console.log('✅ Cash drawer opened');
          resolve(true);
        } catch (error) {
          console.error('Cash drawer error:', error);
          resolve(false);
        }
      });
    });
  }

  /**
   * Print test page
   */
  async printTestPage() {
    if (!this.escpos || !this.device) {
      console.log('⚠️ Printer not initialized');
      return false;
    }

    return new Promise((resolve) => {
      this.device.open((err) => {
        if (err) {
          return resolve(false);
        }

        try {
          this.printer = new this.escpos.Printer(this.device);
          this.printer
            .align('ct')
            .text('=== PRINTER TEST ===')
            .text(new Date().toLocaleString())
            .text('Printer is working!')
            .text('')
            .cut()
            .close();

          resolve(true);
        } catch (error) {
          resolve(false);
        }
      });
    });
  }
}

module.exports = new PrinterService();
