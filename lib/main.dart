import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:web_scraper/web_scraper.dart';
import 'package:url_launcher/url_launcher.dart';

final textProvider = StateProvider<String>((_) => '');
final rakumaProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final String text = "flutter"; //useProvider(textProvider).state ;
  final webScraper = WebScraper('https://fril.jp');
  List<Map<String, dynamic>> items = [];
  if (await webScraper.loadWebPage('/s?category_id=733&query=$text')) {
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

String _useDebouncedSearch(TextEditingController controller) {
  final search = useState(controller.text);

  useEffect(() {
    Timer timer;
    void listener() {
      timer?.cancel();
      timer = Timer(
        const Duration(milliseconds: 1000),
        () => search.value = controller.text,
      );
    }

    controller.addListener(listener);
    return () {
      timer?.cancel();
      controller.removeListener(listener);
    };
  }, [controller]);

  return search.value;
}

class MyApp extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final text = useProvider(textProvider);
    print(_useDebouncedSearch(controller));
    //text.state = _useDebouncedSearch(controller);
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: Text("Book Price Scouter"),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(48.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 12.0, bottom: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: "Search for a word",
                            contentPadding: const EdgeInsets.only(left: 24.0),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.search,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            body: MyHome()));
  }
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
