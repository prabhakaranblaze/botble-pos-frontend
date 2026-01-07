const { prisma } = require('../../config/database');
const config = require('../../config');

class ProductsService {
  /**
   * Get paginated products list
   */
  async getProducts({ page = 1, perPage = 20, search = null, categoryId = null, storeId = null }) {
    const skip = (page - 1) * perPage;

    const where = {
      status: 'published',
      is_available_in_pos: true,
      is_variation: 0, // Only parent products
      deleted_at: null,
    };

    // Search filter
    if (search) {
      where.OR = [
        { name: { contains: search } },
        { sku: { contains: search } },
        { barcode: { contains: search } },
      ];
    }

    // Category filter
    if (categoryId) {
      where.categories = {
        some: { category_id: BigInt(categoryId) },
      };
    }

    // Store filter
    if (storeId) {
      where.store_id = BigInt(storeId);
    }

    const [products, total] = await Promise.all([
      prisma.product.findMany({
        where,
        skip,
        take: perPage,
        orderBy: { name: 'asc' },
        include: {
          categories: {
            include: {
              category: true,
            },
          },
          variations: {
            include: {
              product: true,
              variationItems: {
                include: {
                  attribute: {
                    include: {
                      attributeSet: true,
                    },
                  },
                },
              },
            },
          },
        },
      }),
      prisma.product.count({ where }),
    ]);

    return {
      products: products.map((p) => this.formatProduct(p)),
      pagination: {
        current_page: page,
        per_page: perPage,
        total,
        last_page: Math.ceil(total / perPage),
      },
    };
  }

  /**
   * Get product by barcode
   */
  async getProductByBarcode(barcode) {
    const product = await prisma.product.findFirst({
      where: {
        barcode,
        status: 'published',
        is_available_in_pos: true,
        deleted_at: null,
      },
      include: {
        categories: {
          include: { category: true },
        },
        variations: {
          include: {
            product: true,
            variationItems: {
              include: {
                attribute: {
                  include: {
                    attributeSet: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    return product ? this.formatProduct(product) : null;
  }

  /**
   * Get all categories
   */
  async getCategories() {
    const categories = await prisma.productCategory.findMany({
      where: {
        status: 'published',
        deleted_at: null,
      },
      orderBy: { order: 'asc' },
    });

    // Get product counts
    const categoriesWithCounts = await Promise.all(
      categories.map(async (cat) => {
        const count = await prisma.productCategoryProduct.count({
          where: {
            category_id: cat.id,
            product: {
              status: 'published',
              is_available_in_pos: true,
              deleted_at: null,
            },
          },
        });

        return {
          id: Number(cat.id),
          name: cat.name,
          slug: cat.slug,
          image: cat.image,
          product_count: count,
        };
      })
    );

    return categoriesWithCounts;
  }

  /**
   * Get single product by ID
   */
  async getProductById(id) {
    const product = await prisma.product.findFirst({
      where: {
        id: BigInt(id),
        deleted_at: null,
      },
      include: {
        categories: {
          include: { category: true },
        },
        variations: {
          include: {
            product: true,
            variationItems: {
              include: {
                attribute: {
                  include: {
                    attributeSet: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    return product ? this.formatProduct(product) : null;
  }

  /**
   * Format product for API response
   */
  formatProduct(product) {
    const hasVariations = product.variations_count > 0 || product.variations?.length > 0;

    // Build image URL
    let imageUrl = null;
    if (product.image) {
      imageUrl = product.image.startsWith('http')
        ? product.image
        : `${config.storageUrl}/${product.image}`;
    } else if (product.images) {
      try {
        const images = JSON.parse(product.images);
        if (images.length > 0) {
          imageUrl = images[0].startsWith('http')
            ? images[0]
            : `${config.storageUrl}/${images[0]}`;
        }
      } catch (e) {
        // Ignore parse errors
      }
    }

    // Get final price
    const price = product.price || 0;
    const salePrice = product.sale_price;
    const finalPrice = salePrice && salePrice < price ? salePrice : price;

    return {
      id: Number(product.id),
      name: product.name,
      sku: product.sku,
      barcode: product.barcode,
      price,
      sale_price: salePrice,
      final_price: finalPrice,
      image: imageUrl,
      quantity: product.quantity,
      description: product.description,
      is_available: product.is_available_in_pos && product.stock_status === 'in_stock',
      has_variants: hasVariations,
      variants: hasVariations ? this.formatVariations(product.variations) : null,
    };
  }

  /**
   * Format variations for API response
   * Groups attributes by attribute set (e.g., "Color", "Size")
   */
  formatVariations(variations) {
    if (!variations || variations.length === 0) return [];

    // Collect all attributes from all variations
    const attributeSetMap = new Map();

    for (const variation of variations) {
      if (!variation.variationItems) continue;

      for (const item of variation.variationItems) {
        if (!item.attribute || !item.attribute.attributeSet) continue;

        const attr = item.attribute;
        const attrSet = attr.attributeSet;
        const setId = Number(attrSet.id);

        // Initialize attribute set if not exists
        if (!attributeSetMap.has(setId)) {
          attributeSetMap.set(setId, {
            id: setId,
            name: attrSet.title,
            type: attrSet.slug || attrSet.title,
            options: new Map(),
          });
        }

        // Add option if not exists
        const set = attributeSetMap.get(setId);
        const optionId = Number(attr.id);
        if (!set.options.has(optionId)) {
          // Get price modifier from variation product if available
          let priceModifier = 0;
          if (variation.product) {
            const variantPrice = variation.product.price || 0;
            // Note: price_modifier could be calculated relative to parent price
            priceModifier = variantPrice;
          }

          set.options.set(optionId, {
            id: optionId,
            name: attr.title,
            color: attr.color,
            image: attr.image,
            price_modifier: priceModifier,
          });
        }
      }
    }

    // Convert to array format
    return Array.from(attributeSetMap.values()).map((set) => ({
      id: set.id,
      name: set.name,
      type: set.type,
      options: Array.from(set.options.values()),
    }));
  }
}

module.exports = new ProductsService();
