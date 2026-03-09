class DailySummaryTokenModel {
  DailySummaryTokenModel({required this.token, required this.url});

  final String token;
  final String url;

  factory DailySummaryTokenModel.fromMap(Map<String, dynamic> map) {
    return DailySummaryTokenModel(
      token: map['token'] as String? ?? '',
      url: map['url'] as String? ?? '',
    );
  }
}
