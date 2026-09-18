import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sub/flutter_sub.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class PullToRefresh extends StatelessWidget {
  const PullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  final Widget child;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return SubValue(
      create: () => RefreshController(),
      builder: (context, refreshController) => SubEffect(
        effect: () {
          bool handler(KeyEvent event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.f5) {
              refreshController.requestRefresh(
                duration: const Duration(milliseconds: 100),
              );
              return true;
            }
            return false;
          }

          HardwareKeyboard.instance.addHandler(handler);
          return () => HardwareKeyboard.instance.removeHandler(handler);
        },
        keys: const [],
        child: SmartRefresher(
          controller: refreshController,
          onRefresh: () async {
            try {
              await onRefresh();
              refreshController.refreshCompleted();
            } on Object {
              refreshController.refreshFailed();
            }
          },
          header: const ClassicHeader(),
          child: child,
        ),
      ),
    );
  }
}
