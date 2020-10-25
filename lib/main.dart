import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:web_scraper/web_scraper.dart';
import 'package:url_launcher/url_launcher.dart';

final rakumaProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final webScraper = WebScraper('https://fril.jp');
  List<Map<String, dynamic>> items = [];
  if (await webScraper.loadWebPage('/s?category_id=733&query=flutter')) {
    Map<String, dynamic> item;
    List<Map<String, dynamic>> titles = webScraper.getElement(
        'div.item-box__image-wrapper > a.link_search_image > img',
        ['alt', 'data-original']);
    List<Map<String, dynamic>> links = webScraper.getElement(
        'div.item-box__image-wrapper > a.link_search_image', ['href']);
    List<Map<String, dynamic>> prices =
        webScraper.getElement('span[itemProp="price"]', ['data-content']);
    titles.asMap().forEach((i, title) {
      item = {
        "title": title["attributes"]["alt"],
        "img": title["attributes"]["data-original"],
        "link": links[i]["attributes"]["href"],
        "price": prices[i]["attributes"]["data-content"]
      };
      items.add(item);
    });
  }
  return items;
});

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: Text("Product Catalog"),
          ),
          body: MyHome()));
}

class MyHome extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Map<String, dynamic>>> list =
        useProvider(rakumaProvider);

    return list.when(
        loading: () => const CircularProgressIndicator(),
        error: (err, stack) => Text('Error: $err'),
        data: (items) {
          return ListView.builder(
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                    child: InkWell(
                  onTap: () async {
                    String url = items[index]['link'];
                    if (await canLaunch(url)) {
                      await launch(url);
                    } else {
                      throw 'Could not launch $url';
                    }
                  },
                  child:
                      Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                    Text("${items[index]['title']}"),
                    Text("${items[index]['price']}"),
                    Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Image.network(items[index]['img']))
                  ]),
                ));
              });
        });
  }
}
