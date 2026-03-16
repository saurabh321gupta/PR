import 'package:flutter/material.dart';
import '../services/block_service.dart';

/// Shows a bottom sheet with Block and Report options.
/// [onBlocked] is called after a successful block so the caller can
/// remove the user from their local list.
Future<void> showBlockReportSheet({
  required BuildContext context,
  required String currentUserId,
  required String targetUserId,
  required String targetName,
  VoidCallback? onBlocked,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _BlockReportSheet(
      currentUserId: currentUserId,
      targetUserId: targetUserId,
      targetName: targetName,
      onBlocked: onBlocked,
    ),
  );
}

class _BlockReportSheet extends StatelessWidget {
  final String currentUserId;
  final String targetUserId;
  final String targetName;
  final VoidCallback? onBlocked;

  const _BlockReportSheet({
    required this.currentUserId,
    required this.targetUserId,
    required this.targetName,
    this.onBlocked,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            targetName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Block
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: Text('Block $targetName'),
            subtitle: const Text('They won\'t appear in your feed'),
            onTap: () async {
              Navigator.pop(context);
              await _confirmBlock(context);
            },
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Report
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Colors.orange),
            title: Text('Report $targetName'),
            subtitle: const Text('Let us know what\'s wrong'),
            onTap: () {
              Navigator.pop(context);
              _showReportDialog(context);
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _confirmBlock(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Block $targetName?'),
        content: Text(
            '$targetName won\'t be able to see you and will disappear from your feed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await BlockService().blockUser(
      currentUserId: currentUserId,
      targetUserId: targetUserId,
    );

    onBlocked?.call();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$targetName has been blocked.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showReportDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _ReportDialog(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
        targetName: targetName,
      ),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;
  final String targetName;

  const _ReportDialog({
    required this.currentUserId,
    required this.targetUserId,
    required this.targetName,
  });

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  static const _reasons = [
    'Inappropriate content',
    'Fake profile',
    'Harassment',
    'Spam',
    'Other',
  ];

  String? _selectedReason;
  bool _isSending = false;

  Future<void> _submit() async {
    if (_selectedReason == null) return;
    setState(() => _isSending = true);

    await BlockService().reportUser(
      reportedBy: widget.currentUserId,
      reportedUser: widget.targetUserId,
      reason: _selectedReason!,
    );

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.targetName} has been reported. Thank you.'),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Report ${widget.targetName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _reasons.map((reason) {
          return RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            title: Text(reason, style: const TextStyle(fontSize: 14)),
            value: reason,
            groupValue: _selectedReason,
            activeColor: Colors.pink,
            onChanged: (val) => setState(() => _selectedReason = val),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_selectedReason == null || _isSending) ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Submit'),
        ),
      ],
    );
  }
}
