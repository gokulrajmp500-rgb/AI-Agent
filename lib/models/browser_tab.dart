class BrowserTab {
  final String id;
  final String title;
  final String url;
  final String browser;
  final int index;

  BrowserTab({
    required this.id,
    required this.title,
    required this.url,
    required this.browser,
    required this.index,
  });

  factory BrowserTab.fromJson(Map<String, dynamic> json, int index, {String browser = 'Chrome'}) {
    return BrowserTab(
      id: json['id']?.toString() ?? json['webSocketDebuggerUrl']?.toString() ?? 'unknown-$index',
      title: json['title']?.toString() ?? 'Unknown',
      url: json['url']?.toString() ?? '',
      browser: browser,
      index: index,
    );
  }
}
