import 'package:e1547/client/client.dart';
import 'package:e1547/reply/reply.dart';
import 'package:e1547/shared/shared.dart';
import 'package:e1547/ticket/ticket.dart';
import 'package:flutter/material.dart';

class ReplyReportScreen extends StatelessWidget {
  const ReplyReportScreen({super.key, required this.reply});

  final Reply reply;

  @override
  Widget build(BuildContext context) {
    return ReasonReportScreen(
      title: Text('Reply #${reply.id}'),
      onReport: (reason) => validateCall(
        () => context.read<Client>().tickets.create(
          type: TicketType.forum,
          item: reply.id,
          reason: reason,
        ),
      ),
      onSuccess: 'Reported reply #${reply.id}',
      onFailure: 'Failed to report reply #${reply.id}',
      previewBuilder: (context, isLoading) => Card(
        clipBehavior: Clip.antiAlias,
        child: ReportLoadingOverlay(
          isLoading: isLoading,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ReplyTile(reply: reply, hasActions: false),
          ),
        ),
      ),
    );
  }
}
