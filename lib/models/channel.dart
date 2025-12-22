class Channel {
  final String name;
  final String url;

  /// اختياري (مستقبلًا):
  final String? logo;
  final String? group;

  /// هيدرز اختياري (لو بعض روابطك تحتاج Referer/UA…)
  final Map<String, String>? headers;

  const Channel({
    required this.name,
    required this.url,
    this.logo,
    this.group,
    this.headers,
  });

  Channel copyWith({
    String? name,
    String? url,
    String? logo,
    String? group,
    Map<String, String>? headers,
  }) {
    return Channel(
      name: name ?? this.name,
      url: url ?? this.url,
      logo: logo ?? this.logo,
      group: group ?? this.group,
      headers: headers ?? this.headers,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    if (logo != null) 'logo': logo,
    if (group != null) 'group': group,
    if (headers != null) 'headers': headers,
  };

  factory Channel.fromJson(Map<String, dynamic> j) {
    final h = j['headers'];
    return Channel(
      name: (j['name'] ?? '').toString(),
      url: (j['url'] ?? '').toString(),
      logo: j['logo']?.toString(),
      group: j['group']?.toString(),
      headers: (h is Map)
          ? h.map((k, v) => MapEntry(k.toString(), v.toString()))
          : null,
    );
  }
}
