import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/news_article.dart';

class RssNewsService {
  static const String feedUrl = 'https://www.moneycontrol.com/rss/latestnews.xml';

  static Future<List<NewsArticle>> fetchNews() async {
    final response = await http.get(Uri.parse(feedUrl));

    if (response.statusCode == 200) {
      final document = xml.XmlDocument.parse(response.body);
      final items = document.findAllElements('item');

      return items.map((item) {
        final title = item.getElement('title')?.text ?? 'No title';
        final link = item.getElement('link')?.text ?? '';
        return NewsArticle(title: title, link: link);
      }).toList();
    } else {
      throw Exception('Failed to load RSS feed');
    }
  }
}
