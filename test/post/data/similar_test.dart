import 'package:e1547/post/post.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> entry({
  required int id,
  String rating = 's',
  String? tags,
  List<int> pools = const [],
  bool isFavorited = false,
  int score = 5,
  int favCount = 10,
  int commentCount = 2,
}) => {
  'id': id,
  'created_at': '2024-01-01T00:00:00.000Z',
  'md5': 'md5$id',
  'file_ext': 'jpg',
  'width': 2048,
  'height': 1024,
  'size': 1000,
  'preview_url': 'https://host/previews/$id.jpg',
  'preview_webp': 'https://host/previews/$id.webp',
  'sample_url': 'https://host/samples/$id.jpg',
  'file_url': 'https://host/files/$id.jpg',
  'uploader_id': 42,
  'uploader': 'artist_$id',
  'score': score,
  'fav_count': favCount,
  'is_favorited': isFavorited,
  'vote': 1,
  'comment_count': commentCount,
  'pools': pools.isEmpty ? null : pools.join(' '),
  'rating': rating,
  'tags': tags,
};

Map<String, Object?> response({
  required String kind,
  required List<Map<String, Object?>> postData,
  List<int>? order,
}) => {
  'post_id': 1000,
  'model_version': 'os.$kind',
  'results': [
    for (final id in (order ?? postData.map((e) => e['id']! as int)))
      {'post_id': id, 'score': 1, 'explanation': null},
  ],
  'post_data': postData,
};

void main() {
  group('PostSimilar.fromJson', () {
    test('parses a full artist response onto the model', () {
      final similar = PostSimilar.fromJson(
        PostSimilarKind.artist,
        response(
          kind: 'artist',
          postData: [
            entry(
              id: 2,
              tags: 'fox red fox_tail',
              rating: 'e',
              pools: const [1, 30],
              isFavorited: true,
            ),
          ],
        ),
      );

      expect(similar.postId, 1000);
      expect(similar.kind, PostSimilarKind.artist);
      expect(similar.results.map((e) => e.id), [2]);

      final post = similar.results.single;
      expect(post.rating, Rating.e);
      expect(post.isFavorited, isTrue);
      expect(post.favCount, 10);
      expect(post.commentCount, 2);
      expect(post.score, 5);
      expect(post.width, 2048);
      expect(post.height, 1024);
      expect(post.size, 1000);
      expect(post.fileExt, 'jpg');
      expect(post.previewUrl, 'https://host/previews/2.jpg');
      expect(post.previewWebp, 'https://host/previews/2.webp');
      expect(post.sampleUrl, 'https://host/samples/2.jpg');
      expect(post.fileUrl, 'https://host/files/2.jpg');
      expect(post.uploaderId, 42);
      expect(post.uploaderName, 'artist_2');
      expect(post.vote, 1);
      expect(post.pools, [1, 30]);
      expect(post.createdAt, DateTime.utc(2024));
      expect(post.tags['general'], ['fox', 'red', 'fox_tail']);
    });

    test('parses a tags response onto the model', () {
      final similar = PostSimilar.fromJson(
        PostSimilarKind.tags,
        response(kind: 'tags', postData: [entry(id: 3)]),
      );

      expect(similar.kind, PostSimilarKind.tags);
      expect(similar.results.single.id, 3);
    });

    test('keeps the results order above the post_data order', () {
      final similar = PostSimilar.fromJson(
        PostSimilarKind.tags,
        response(
          kind: 'tags',
          postData: [entry(id: 10), entry(id: 11), entry(id: 12)],
          order: [11, 10, 12],
        ),
      );

      expect(similar.results.map((e) => e.id), [11, 10, 12]);
    });

    test('skips results without matching post data', () {
      final similar = PostSimilar.fromJson(
        PostSimilarKind.tags,
        response(kind: 'tags', postData: [entry(id: 10)], order: [10, 99]),
      );

      expect(similar.results.map((e) => e.id), [10]);
    });

    test('drops post data entries without an id', () {
      final similar = PostSimilar.fromJson(
        PostSimilarKind.tags,
        response(kind: 'tags', postData: [entry(id: 10), {'foo': 'bar'}], order: [10]),
      );

      expect(similar.results.map((e) => e.id), [10]);
    });

    test('handles an empty response', () {
      final similar = PostSimilar.fromJson(
        PostSimilarKind.tags,
        response(kind: 'tags', postData: const []),
      );

      expect(similar.postId, 1000);
      expect(similar.results, isEmpty);
    });

    test('defaults missing fields', () {
      final similar = PostSimilar.fromJson(
        PostSimilarKind.tags,
        const {
          'post_id': 1000,
          'model_version': 'os.tags',
          'results': [
            {'post_id': 7, 'score': 1, 'explanation': null},
          ],
          'post_data': [
            {'id': 7},
          ],
        },
      );

      final post = similar.results.single;
      expect(post.id, 7);
      expect(post.width, 0);
      expect(post.height, 0);
      expect(post.score, 0);
      expect(post.favCount, 0);
      expect(post.isFavorited, isFalse);
      expect(post.commentCount, 0);
      expect(post.tags['general'], isEmpty);
      expect(post.pools, isEmpty);
      expect(post.size, isNull);
      expect(post.fileExt, isNull);
      expect(post.previewUrl, isNull);
      expect(post.rating, isNull);
      expect(post.uploaderName, isNull);
      expect(post.createdAt, isNull);
    });

    test('ignores an unknown rating', () {
      final similar = PostSimilar.fromJson(
        PostSimilarKind.tags,
        response(kind: 'tags', postData: [entry(id: 4, rating: 'x')]),
      );

      expect(similar.results.single.rating, isNull);
    });

    test('leaves the general group empty when tags are missing', () {
      final similar = PostSimilar.fromJson(
        PostSimilarKind.tags,
        response(kind: 'tags', postData: [entry(id: 5)]),
      );

      expect(similar.results.single.tags['general'], isEmpty);
    });
  });
}
