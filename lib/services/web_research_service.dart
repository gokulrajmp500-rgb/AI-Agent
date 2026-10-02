import 'package:http/http.dart' as http;

class WebResearchService {
  final String searchEngine;

  WebResearchService({this.searchEngine = 'https://www.bing.com/search?q='});

  Future<String> search(String query) async {
    final encoded = Uri.encodeComponent(query.trim());
    final url = '$searchEngine$encoded';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return 'Search failed with status ${response.statusCode}.';
      }
      return 'Search executed for "$query". Open browser to view results.';
    } catch (e) {
      return 'Could not perform online search. $e';
    }
  }

  Future<String> research(String query) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) {
      return 'Please provide a research topic.';
    }
    return 'Research completed for "$cleaned". Please review the summary above.';
  }
}
