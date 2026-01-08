class Order {
  final int id;
  final String code;
  final OrderStatus status;
  final String statusHtml;
  final OrderCustomer customer;
  final String createdAt;
  final String amount;
  final String amountFormatted;
  final String taxAmount;
  final String taxAmountFormatted;
  final String shippingAmount;
  final String shippingAmountFormatted;
  final OrderMethod shippingMethod;
  final OrderStatus shippingStatus;
  final String shippingStatusHtml;
  final OrderMethod paymentMethod;
  final OrderStatus paymentStatus;
  final String paymentStatusHtml;
  final int productsCount;
  final List<dynamic> products;

  Order({
    required this.id,
    required this.code,
    required this.status,
    required this.statusHtml,
    required this.customer,
    required this.createdAt,
    required this.amount,
    required this.amountFormatted,
    required this.taxAmount,
    required this.taxAmountFormatted,
    required this.shippingAmount,
    required this.shippingAmountFormatted,
    required this.shippingMethod,
    required this.shippingStatus,
    required this.shippingStatusHtml,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentStatusHtml,
    required this.productsCount,
    required this.products,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      code: json['code'],
      status: OrderStatus.fromJson(json['status']),
      statusHtml: json['status_html'],
      customer: OrderCustomer.fromJson(json['customer']),
      createdAt: json['created_at'],
      amount: json['amount'],
      amountFormatted: json['amount_formatted'],
      taxAmount: json['tax_amount'],
      taxAmountFormatted: json['tax_amount_formatted'],
      shippingAmount: json['shipping_amount'],
      shippingAmountFormatted: json['shipping_amount_formatted'],
      shippingMethod: OrderMethod.fromJson(json['shipping_method']),
      shippingStatus: OrderStatus.fromJson(json['shipping_status']),
      shippingStatusHtml: json['shipping_status_html'],
      paymentMethod: OrderMethod.fromJson(json['payment_method']),
      paymentStatus: OrderStatus.fromJson(json['payment_status']),
      paymentStatusHtml: json['payment_status_html'],
      productsCount: json['products_count'] ?? 0,
      products: json['products'].toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'status': status.toJson(),
      'status_html': statusHtml,
      'customer': customer.toJson(),
      'created_at': createdAt,
      'amount': amount,
      'amount_formatted': amountFormatted,
      'tax_amount': taxAmount,
      'tax_amount_formatted': taxAmountFormatted,
      'shipping_amount': shippingAmount,
      'shipping_amount_formatted': shippingAmountFormatted,
      'shipping_method': shippingMethod.toJson(),
      'shipping_status': shippingStatus.toJson(),
      'shipping_status_html': shippingStatusHtml,
      'payment_method': paymentMethod.toJson(),
      'payment_status': paymentStatus.toJson(),
      'payment_status_html': paymentStatusHtml,
      'products_count': productsCount,
    };
  }
}

class OrderStatus {
  final String value;
  final String label;

  OrderStatus({required this.value, required this.label});

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    return OrderStatus(value: json['value'] ?? '', label: json['label'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'value': value, 'label': label};
  }
}

class OrderMethod {
  final String value;
  final String label;

  OrderMethod({required this.value, required this.label});

  factory OrderMethod.fromJson(Map<String, dynamic> json) {
    return OrderMethod(value: json['value'] ?? '', label: json['label'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'value': value, 'label': label};
  }
}

class OrderCustomer {
  final String name;
  final String email;
  final String phone;

  OrderCustomer({required this.name, required this.email, required this.phone});

  factory OrderCustomer.fromJson(Map<String, dynamic> json) {
    return OrderCustomer(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'email': email, 'phone': phone};
  }
}

class OrderListResponse {
  final List<Order> data;
  final OrderLinks links;
  final OrderMeta meta;
  final bool error;
  final String? message;

  OrderListResponse({
    required this.data,
    required this.links,
    required this.meta,
    required this.error,
    this.message,
  });

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    return OrderListResponse(
      data: (json['data'] as List).map((item) => Order.fromJson(item)).toList(),
      links: OrderLinks.fromJson(json['links']),
      meta: OrderMeta.fromJson(json['meta']),
      error: json['error'] ?? false,
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
      'links': links.toJson(),
      'meta': meta.toJson(),
      'error': error,
      'message': message,
    };
  }
}

class OrderLinks {
  final String first;
  final String last;
  final String? prev;
  final String? next;

  OrderLinks({required this.first, required this.last, this.prev, this.next});

  factory OrderLinks.fromJson(Map<String, dynamic> json) {
    return OrderLinks(
      first: json['first'],
      last: json['last'],
      prev: json['prev'],
      next: json['next'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'first': first, 'last': last, 'prev': prev, 'next': next};
  }
}

class OrderMeta {
  final int currentPage;
  final int from;
  final int lastPage;
  final List<OrderMetaLink> links;
  final String path;
  final int perPage;
  final int to;
  final int total;

  OrderMeta({
    required this.currentPage,
    required this.from,
    required this.lastPage,
    required this.links,
    required this.path,
    required this.perPage,
    required this.to,
    required this.total,
  });

  factory OrderMeta.fromJson(Map<String, dynamic> json) {
    return OrderMeta(
      currentPage: json['current_page'],
      from: json['from'],
      lastPage: json['last_page'],
      links:
          (json['links'] as List)
              .map((item) => OrderMetaLink.fromJson(item))
              .toList(),
      path: json['path'],
      perPage: json['per_page'],
      to: json['to'],
      total: json['total'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'from': from,
      'last_page': lastPage,
      'links': links.map((item) => item.toJson()).toList(),
      'path': path,
      'per_page': perPage,
      'to': to,
      'total': total,
    };
  }
}

class OrderMetaLink {
  final String? url;
  final String label;
  final bool active;

  OrderMetaLink({this.url, required this.label, required this.active});

  factory OrderMetaLink.fromJson(Map<String, dynamic> json) {
    return OrderMetaLink(
      url: json['url'],
      label: json['label'],
      active: json['active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'label': label, 'active': active};
  }
}
