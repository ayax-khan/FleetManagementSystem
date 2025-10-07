// lib/ui/widgets/audit_timeline.dart
import 'package:fleet_management/models/audit_log.dart';
import 'package:flutter/material.dart';

class AuditTimeline extends StatelessWidget {
  final List<AuditLog> audits;

  const AuditTimeline({Key? key, required this.audits}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: audits.length,
      itemBuilder: (context, index) {
        final audit = audits[index];
        return ListTile(
          title: Text('${audit.action} on ${audit.entityType}'),
          subtitle: Text(audit.timestamp.toString()),
          trailing: Text('By ${audit.userId}'),
        );
      },
    );
  }
}
