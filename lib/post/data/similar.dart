import 'package:deep_pick/deep_pick.dart';
import 'package:e1547/post/post.dart';
import 'package:flutter/foundation.dart';

/// How the similar posts were computed by e621.
///
/// Matches the `/posts/{id}/similar/{kind}.json` routes.
enum PostSimilarKind { artist, tags }

/// A bundle of posts similar to a single post.
@immutable
class PostSimilar {
  const PostSimilar({
    required this.postId,
    required this.kind,
    required this.results,
  });

  /// Parses the response of `/posts/{id}/similar/{kind}.json`.
  factory PostSimilar.fromJson(PostSimilarKind kind, dynamic json) {
    final Pick root = pick(json);
    final int postId = root('post_id').asIntOrNull() ?? 0;
    final List<PostSimilarResult?> data =
        root('post_data').asListOrNull(PostSimilarResult.tryParse) ?? const [];
    final Map<int, PostSimilarResult> table = {
      for (final result in data)
        if (result != null) result.id: result,
    };
    final List<int> order =
        (root('results').asListOrNull(
                      (post) => post('post_id').asIntOrNull(),
                    ) ??
                    const <int>[])
            .whereType<int>()
            .toList();
    return PostSimilar(
      postId: postId,
      kind: kind,
      results: [
        for (final id in order)
          if (table[id] != null) table[id]!,
      ],
    );
  }

  /// The id of the post the results were computed for.
  final int postId;

  /// The model which computed the results.
  final PostSimilarKind kind;

  /// The similar posts, ordered by relevance.
  final List<PostSimilarResult> results;
}

/// A single similar post.
///
/// The `/posts/{id}/similar/{kind}.json` endpoints return posts in a reduced
/// format, so this model only mirrors the fields that are available there.
@immutable
class PostSimilarResult {
  const PostSimilarResult({
    required this.id,
    required this.width,
    required this.height,
    required this.score,
    required this.favCount,
    required this.isFavorited,
    required this.commentCount,
    required this.tags,
    this.size,
    this.fileExt,
    this.previewUrl,
    this.previewWebp,
    this.sampleUrl,
    this.fileUrl,
    this.uploaderId,
    this.uploaderName,
    this.vote,
    this.createdAt,
    this.rating,
    this.pools = const [],
  });

/// Parses a single entry of `post_data`, or null if it has no id.
  static PostSimilarResult? tryParse(RequiredPick post) {
    final int? id = post('id').asIntOrNull();
    if (id == null) return null;

    final String? tagString = post('tags').asStringOrNull();
    final String? rating = post('rating').asStringOrNull();
    final String? pools = post('pools').asStringOrNull();

    return PostSimilarResult(
      id: id,
      width: post('width').asIntOrNull() ?? 0,
      height: post('height').asIntOrNull() ?? 0,
      score: post('score').asIntOrNull() ?? 0,
      favCount: post('fav_count').asIntOrNull() ?? 0,
      isFavorited: post('is_favorited').asBoolOrNull() ?? false,
      commentCount: post('comment_count').asIntOrNull() ?? 0,
      size: post('size').asIntOrNull(),
      fileExt: post('file_ext').asStringOrNull(),
      previewUrl: post('preview_url').asStringOrNull(),
      previewWebp: post('preview_webp').asStringOrNull(),
      sampleUrl: post('sample_url').asStringOrNull(),
      fileUrl: post('file_url').asStringOrNull(),
      uploaderId: post('uploader_id').asIntOrNull(),
      uploaderName: post('uploader').asStringOrNull(),
      vote: post('vote').asIntOrNull(),
      createdAt: post('created_at').asDateTimeOrNull(),
      rating: rating == null ? null : Rating.values.asNameMap()[rating],
      pools: pools == null
          ? const []
          : pools
                .split(RegExp(r'\s+'))
                .map(int.tryParse)
                .whereType<int>()
                .toList(),
      tags: {
        'general': tagString == null
            ? const []
            : tagString
                  .split(' ')
                  .where((tag) => tag.isNotEmpty)
                  .toList(),
      },
    );
  }

  final int id;
  final int width;
  final int height;
  final int score;
  final int favCount;
  final bool isFavorited;
  final int commentCount;

  /// The tags of the post, grouped by category.
  ///
  /// The reduced similar-post format does not carry category information,
  /// so every tag lands in the `general` category.
  final Map<String, List<String>> tags;

  final int? size;
  final String? fileExt;
  final String? previewUrl;
  final String? previewWebp;
  final String? sampleUrl;
  final String? fileUrl;
  final int? uploaderId;
  final String? uploaderName;
  final int? vote;
  final DateTime? createdAt;
  final Rating? rating;
  final List<int> pools;
}
