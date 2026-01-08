class Notification {
  final String id;
  final String type;
  final String title;
  final String? description;
  final String? data;
  final String? actionUrl;
  final String? icon;
  final bool isRead;
  final bool isClicked;
  final String createdAt;
  final String updatedAt;

  Notification({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.data,
    this.actionUrl,
    this.icon,
    required this.isRead,
    required this.isClicked,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      data: json['data']?.toString(),
      actionUrl: json['action_url'] as String?,
      icon: json['icon'] as String?,
      isRead: json['is_read'] == true || json['is_read'] == 1,
      isClicked: json['is_clicked'] == true || json['is_clicked'] == 1,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'data': data,
      'action_url': actionUrl,
      'icon': icon,
      'is_read': isRead,
      'is_clicked': isClicked,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class NotificationStats {
  final int total;
  final int unread;
  final int unclicked;

  NotificationStats({
    required this.total,
    required this.unread,
    required this.unclicked,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      total: json['total'] as int? ?? 0,
      unread: json['unread'] as int? ?? 0,
      unclicked: json['unclicked'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'unread': unread,
      'unclicked': unclicked,
    };
  }
}

class NotificationListResponse {
  final List<Notification> data;
  final NotificationLinks? links;
  final NotificationMeta? meta;
  final bool error;
  final String? message;

  NotificationListResponse({
    required this.data,
    this.links,
    this.meta,
    required this.error,
    this.message,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    List<Notification> notifications = [];
    NotificationLinks? links;
    NotificationMeta? meta;
    
    // Check if this is a paginated response structure
    if (json['data'] != null && json['data'] is Map) {
      final dataMap = json['data'] as Map<String, dynamic>;
      
      // Check if data contains the actual notifications list
      if (dataMap['data'] is List) {
        notifications = (dataMap['data'] as List)
            .map((item) => Notification.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      
      // Check if pagination info is nested within data
      if (dataMap['links'] != null) {
        links = NotificationLinks.fromJson(dataMap['links']);
      }
      if (dataMap['meta'] != null) {
        meta = NotificationMeta.fromJson(dataMap['meta']);
      }
    } else if (json['data'] is List) {
      // If data is directly a list
      notifications = (json['data'] as List)
          .map((item) => Notification.fromJson(item as Map<String, dynamic>))
          .toList();
      
      // Check for pagination at root level
      if (json['links'] != null) {
        links = NotificationLinks.fromJson(json['links']);
      }
      if (json['meta'] != null) {
        meta = NotificationMeta.fromJson(json['meta']);
      }
    }
    
    return NotificationListResponse(
      data: notifications,
      links: links,
      meta: meta,
      error: json['error'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
      'links': links?.toJson(),
      'meta': meta?.toJson(),
      'error': error,
      'message': message,
    };
  }
}

class NotificationLinks {
  final String? first;
  final String? last;
  final String? prev;
  final String? next;

  NotificationLinks({
    this.first,
    this.last,
    this.prev,
    this.next,
  });

  factory NotificationLinks.fromJson(Map<String, dynamic> json) {
    return NotificationLinks(
      first: json['first'] as String?,
      last: json['last'] as String?,
      prev: json['prev'] as String?,
      next: json['next'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first': first,
      'last': last,
      'prev': prev,
      'next': next,
    };
  }
}

class NotificationMeta {
  final int currentPage;
  final int from;
  final int lastPage;
  final int perPage;
  final int to;
  final int total;

  NotificationMeta({
    required this.currentPage,
    required this.from,
    required this.lastPage,
    required this.perPage,
    required this.to,
    required this.total,
  });

  factory NotificationMeta.fromJson(Map<String, dynamic> json) {
    return NotificationMeta(
      currentPage: json['current_page'] as int? ?? 1,
      from: json['from'] as int? ?? 0,
      lastPage: json['last_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 10,
      to: json['to'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'from': from,
      'last_page': lastPage,
      'per_page': perPage,
      'to': to,
      'total': total,
    };
  }
}