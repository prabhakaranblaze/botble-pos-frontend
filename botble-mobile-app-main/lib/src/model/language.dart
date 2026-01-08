class Language {
  final int id;
  final String name;
  final String code;
  final String langLocale;
  final String flag;
  final bool isDefault;
  final bool isRtl;
  final int order;

  Language({
    required this.id,
    required this.name,
    required this.code,
    required this.langLocale,
    required this.flag,
    required this.isDefault,
    required this.isRtl,
    required this.order,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['lang_id'] as int,
      name: json['lang_name'] as String,
      code: json['lang_code'] as String,
      langLocale: json['lang_locale'] as String,
      flag: json['lang_flag'] as String,
      isDefault: json['lang_is_default'] as bool,
      isRtl: json['lang_is_rtl'] as bool,
      order: json['lang_order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'lang_locale': langLocale,
      'flag': flag,
      'is_default': isDefault,
      'is_rtl': isRtl,
      'order': order,
    };
  }
}
