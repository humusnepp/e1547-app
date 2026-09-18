import 'package:drift/native.dart';
import 'package:e1547/app/app.dart';
import 'package:e1547/client/client.dart';
import 'package:e1547/identity/identity.dart';
import 'package:e1547/post/post.dart';
import 'package:e1547/query/query.dart';
import 'package:e1547/settings/settings.dart';
import 'package:e1547/shared/shared.dart';
import 'package:e1547/traits/traits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notified_preferences/notified_preferences.dart';

import '../../_support/fake_e621.dart';
import '../../_support/fixtures.dart';
import '../../_support/harness.dart';
import '../../_support/images.dart';
import '../../_support/posts.dart';
import '../../_support/video.dart';

void main() {
  late FakeE621 fake;
  late Client client;
  late ValueNotifier<Traits> traits;
  late AppDatabase sqlite;
  late AppStorage storage;
  late VideoService videos;
  late Settings settings;

  setUpAll(() async {
    await initializeTestApp();
    sqlite = AppDatabase(NativeDatabase.memory());
  });

  tearDownAll(() => sqlite.close());

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fake = await FakeE621.start();
    videos = fakeVideoService();
    settings = Settings(await SharedPreferences.getInstance());
    traits = ValueNotifier(
      const Traits(
        id: 1,
        userId: null,
        denylist: [],
        homeTags: '',
        avatar: null,
        perPage: null,
      ),
    );
    storage = AppStorage(
      preferences: await SharedPreferences.getInstance(),
      temporaryFiles: '.',
      queryCache: CachedQuery.asNewInstance()
        ..config(
          config: const GlobalQueryConfig(
            cacheDuration: Duration(milliseconds: 1),
          ),
        ),
      sqlite: sqlite,
    );
    client = Client(
      identity: Identity(id: 1, host: fake.url, username: null, headers: null),
      traits: traits,
      storage: storage,
    );
  });

  tearDown(() async {
    traits.dispose();
    videos.dispose();
    await fake.stop();
  });

  Future<void> show(WidgetTester tester, Client client, Post post) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<Client>.value(value: client),
            Provider<BaseCacheManager>.value(
              value: const NoImageCacheManager(),
            ),
            ChangeNotifierProvider<VideoService>.value(value: videos),
            Provider<Settings>.value(value: settings),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: SimilarSection(post: post),
                ),
              ),
            ),
          ),
        ),
      );
      // Let the similar request land before the tree is torn down.
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
  }

  List<int> expectedIds() => loadFixtureList('posts.json')
      .map((e) => e['id']! as int)
      .where((id) => id != 1000)
      .toList()
      .reversed
      .toList();

  group('SimilarSection', () {
    displayTest('lists posts similar by tag by default', (tester) async {
      await show(tester, client, samplePost(id: 1000));

      expect(find.text('Similar'), findsOneWidget);
      expect(find.text('Tags'), findsOneWidget);
      expect(find.text('Artist'), findsOneWidget);
      expect(find.text('tags model'), findsOneWidget);

      expect(find.byType(PostSimilarTile), findsWidgets);
      expect(find.text('#${expectedIds().first}'), findsOneWidget);
      expect(fake.requests.last.path, '/posts/1000/similar/tags.json');
    });

    displayTest('reloads for the artist on selection', (tester) async {
      await show(tester, client, samplePost(id: 1000));

      await tester.runAsync(() async {
        await tester.tap(find.text('Artist'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(find.text('artist model'), findsOneWidget);
      expect(fake.requests.last.path, '/posts/1000/similar/artist.json');
      expect(find.byType(PostSimilarTile), findsWidgets);
    });

    displayTest('reports when there are no similar posts', (tester) async {
      fake.state.posts
        ..clear()
        ..add(loadFixtureList('posts.json').first);

      await show(tester, client, samplePost(id: 1000));

      expect(find.text('No similar posts found'), findsOneWidget);
    });

    displayTest('recovers from a load failure', (tester) async {
      fake.state.errorPaths.add('/posts/1000/similar/tags.json');

      await show(tester, client, samplePost(id: 1000));

      expect(find.text('Failed to load similar posts'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    displayTest('opens the post of a tapped tile', (tester) async {
      await show(tester, client, samplePost(id: 1000));

      await tester.runAsync(() async {
        await tester.tap(find.byType(PostSimilarTile).first);
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      final opened = find.byWidgetPredicate(
        (widget) => widget is PostDetail,
      );
      expect(opened, findsOneWidget);
    });
  });
}
