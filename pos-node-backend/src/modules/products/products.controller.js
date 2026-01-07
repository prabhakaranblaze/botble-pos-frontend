const productsService = require('./products.service');
const { z } = require('zod');

const barcodeSchema = z.object({
  barcode: z.string().min(1, 'Barcode is required'),
});

class ProductsController {
  /**
   * GET /products
   */
  async getProducts(req, res, next) {
    try {
      const page = parseInt(req.query.page) || 1;
      const perPage = parseInt(req.query.per_page) || 20;
      const search = req.query.search || null;
      const categoryId = req.query.category_id || null;
      const storeId = req.user?.storeId || null;

      const result = await productsService.getProducts({
        page,
        perPage,
        search,
        categoryId,
        storeId,
      });

      res.json({
        error: false,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /products/scan-barcode
   */
  async scanBarcode(req, res, next) {
    try {
      const { barcode } = barcodeSchema.parse(req.body);

      const product = await productsService.getProductByBarcode(barcode);

      res.json({
        error: false,
        data: { product },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /products/categories
   */
  async getCategories(req, res, next) {
    try {
      const categories = await productsService.getCategories();

      res.json({
        error: false,
        data: { categories },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /products/:id
   */
  async getProduct(req, res, next) {
    try {
      const product = await productsService.getProductById(req.params.id);

      if (!product) {
        return res.status(404).json({
          error: true,
          message: 'Product not found',
        });
      }

      res.json({
        error: false,
        data: { product },
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ProductsController();
