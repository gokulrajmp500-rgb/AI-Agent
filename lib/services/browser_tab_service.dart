import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/browser_tab.dart';

class BrowserTabService {
  final String chromeHost;
  final int chromePort;

  BrowserTabService({this.chromeHost = '127.0.0.1', this.chromePort = 9222});

  Uri get _baseUri => Uri.parse('http://$chromeHost:$chromePort');

  Future<bool> isBrowserDebuggingAvailable() async {
    try {
      final response = await http.get(_baseUri.replace(path: '/json/version')).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<BrowserTab>> listTabs() async {
    final response = await http.get(_baseUri.replace(path: '/json'));
    if (response.statusCode != 200) {
      throw Exception('Browser debugging interface not available.');
    }

    final jsonList = jsonDecode(response.body) as List<dynamic>;
    final tabs = <BrowserTab>[];
    for (var i = 0; i < jsonList.length; i++) {
      final json = jsonList[i] as Map<String, dynamic>;
      tabs.add(BrowserTab.fromJson(json, i));
    }
    return tabs;
  }

  Future<String> closeTab(String tabId) async {
    final tabs = await listTabs();
    final tab = tabs.firstWhere((t) => t.id == tabId, orElse: () => throw Exception('Tab not found')); 
    final closeUri = Uri.parse('${_baseUri.toString()}/json/close/$tabId');
    final response = await http.get(closeUri);
    if (response.statusCode != 200) {
      throw Exception('Could not close tab.');
    }
    return 'Closed tab: ${tab.title}';
  }

  Future<String> activateTab(String tabId) async {
    final activateUri = Uri.parse('${_baseUri.toString()}/json/activate/$tabId');
    final response = await http.get(activateUri);
    if (response.statusCode != 200) {
      throw Exception('Could not activate tab.');
    }
    return 'Activated tab.';
  }

  Future<String> openNewTab([String url = 'about:blank']) async {
    final createUri = Uri.parse('${_baseUri.toString()}/json/new?$url');
    final response = await http.get(createUri);
    if (response.statusCode != 200) {
      throw Exception('Could not open new tab.');
    }
    return 'Opened a new tab.';
  }

  Future<String> reopenLastClosedTab() async {
    throw UnimplementedError('Browser devtools reopen tab is not available in this simple implementation.');
  }
}
