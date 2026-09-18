import 'package:cached_network_image/cached_network_image.dart';
import 'package:e1547/client/client.dart';
import 'package:e1547/post/post.dart';
import 'package:e1547/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// A section which shows posts similar to a post, selectable by
/// shared tags or by the artist.
class SimilarSection extends StatefulWidget {
  const SimilarSection({super.key, required this.post});

  /// The post for which similar posts are shown.
  final Post post;

  @override
  State<SimilarSection> createState() => _SimilarSectionState();
}

class _SimilarSectionState extends State<SimilarSection> {
  PostSimilarKind kind = PostSimilarKind.tags;
  Future<PostSimilar>? future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    future ??= _query(kind);
  }

  Future<PostSimilar> _query(PostSimilarKind kind) =>
      context.read<Client>().posts.similar(id: widget.post.id, kind: kind);

  void _changeKind(PostSimilarKind value) {
    if (value == kind) return;
    setState(() {
      kind = value;
      future = _query(value);
    });
  }

  void _refresh() {
    setState(() {
      future = _query(kind);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Similar',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${kind == PostSimilarKind.tags ? 'tags' : 'artist'} model',
                style: TextStyle(
                  fontSize: 12,
                  color: dimTextColor(context),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<PostSimilarKind>(
                  segments: const [
                    ButtonSegment(
                      value: PostSimilarKind.tags,
                      label: Text('Tags'),
                      icon: Icon(Icons.local_offer, size: 16),
                    ),
                    ButtonSegment(
                      value: PostSimilarKind.artist,
                      label: Text('Artist'),
                      icon: Icon(Icons.palette, size: 16),
                    ),
                  ],
                  selected: {kind},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      _changeKind(selection.first),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _refresh,
              ),
            ],
          ),
        ),
        SizedBox(height: 190, child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    return FutureBuilder<PostSimilar>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline),
                const SizedBox(height: 8),
                const Text('Failed to load similar posts'),
                TextButton(
                  onPressed: _refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final PostSimilar? similar = snapshot.data;
        if (similar == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (similar.results.isEmpty) {
          return const Center(child: Text('No similar posts found'));
        }

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: similar.results.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) => SizedBox(
            width: 120,
            height: 190,
            child: PostSimilarTile(post: similar.results[index]),
          ),
        );
      },
    );
  }
}

/// A compact square card for a similar post.
class PostSimilarTile extends StatelessWidget {
  const PostSimilarTile({super.key, required this.post});

  final PostSimilarResult post;

  @override
  Widget build(BuildContext context) {
    final TextStyle infoStyle = TextStyle(
      fontSize: 12,
      color: dimTextColor(context),
    );
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => PostLoadingPage(post.id)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _image(context)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${post.id}',
                      overflow: TextOverflow.ellipsis,
                      style: infoStyle,
                    ),
                  ),
                  Icon(
                    Icons.favorite,
                    size: 12,
                    color: post.isFavorited ? Colors.pinkAccent : null,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    post.favCount.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image(BuildContext context) {
    final String? url = post.previewUrl ?? post.sampleUrl;
    if (url == null) {
      return const Center(child: Icon(Icons.broken_image_outlined));
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      cacheManager: context.read<BaseCacheManager>(),
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}
