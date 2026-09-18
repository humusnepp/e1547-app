import 'package:e1547/post/post.dart';
import 'package:e1547/tag/tag.dart';
import 'package:flutter/material.dart';

class TagDisplay extends StatelessWidget {
  const TagDisplay({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    Widget tagCategory(String category) {
      return Wrap(
        children: [
          ...post.tags[category]!.map(
            (tag) => TagCard(tag: tag, category: category),
          ),
        ],
      );
    }

    Widget categoryTile(String category) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              '${category[0].toUpperCase()}${category.substring(1)}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Row(children: [Expanded(child: tagCategory(category))]),
          const Divider(),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: post.tags.keys
          .where((category) => post.tags[category]?.isNotEmpty ?? false)
          .map((category) => categoryTile(category))
          .toList(),
    );
  }
}
