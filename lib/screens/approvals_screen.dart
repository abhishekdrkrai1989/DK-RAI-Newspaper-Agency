import 'package:flutter/material.dart';
import '../models/approval_request.dart';
import '../providers/delivery_provider.dart';

class ApprovalsScreen extends StatefulWidget {
  final DeliveryProvider provider;

  const ApprovalsScreen({
    super.key,
    required this.provider,
  });

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData _iconForAction(ApprovalActionType type) {
    switch (type) {
      case ApprovalActionType.pausePaper:
        return Icons.pause_circle_outline;
      case ApprovalActionType.startPaper:
        return Icons.play_circle_outline;
      case ApprovalActionType.addCustomer:
        return Icons.person_add_outlined;
      case ApprovalActionType.deleteCustomer:
        return Icons.person_remove_outlined;
      case ApprovalActionType.editCustomer:
        return Icons.edit_outlined;
      case ApprovalActionType.addPublication:
        return Icons.newspaper_outlined;
      case ApprovalActionType.deletePublication:
        return Icons.delete_outline;
    }
  }

  Color _colorForAction(ApprovalActionType type) {
    switch (type) {
      case ApprovalActionType.pausePaper:
        return const Color(0xFFD97706); // Amber
      case ApprovalActionType.startPaper:
        return const Color(0xFF059669); // Emerald
      case ApprovalActionType.addCustomer:
        return const Color(0xFF2563EB); // Blue
      case ApprovalActionType.deleteCustomer:
        return const Color(0xFFDC2626); // Red
      case ApprovalActionType.editCustomer:
        return const Color(0xFF7C3AED); // Purple
      case ApprovalActionType.addPublication:
        return const Color(0xFF0D9488); // Teal
      case ApprovalActionType.deletePublication:
        return const Color(0xFFE11D48); // Rose
    }
  }

  String _formatDateTime(DateTime dt) {
    final s = widget.provider.strings;
    final date = s.formatDate(dt);
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$date $hour:$minute $ampm';
  }

  Future<void> _handleApprove(ApprovalRequest req) async {
    await widget.provider.approveRequest(req.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.provider.strings.approvedSuccessMsg),
        backgroundColor: const Color(0xFF059669),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleReject(ApprovalRequest req) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.provider.strings.isHindi
            ? 'कार्य अस्वीकार व वापस लें?'
            : 'Reject & Revert Action?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.provider.strings.isHindi
                  ? 'यह कार्य रद्द हो जाएगा और पहले की स्थिति बहाल हो जाएगी।'
                  : 'This action will be rejected and reverted back to its original state.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: widget.provider.strings.isHindi
                    ? 'कारण (वैकल्पिक)'
                    : 'Rejection Reason (Optional)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(widget.provider.strings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(widget.provider.strings.btnReject),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.provider.rejectRequest(
        req.id,
        reason: noteController.text.trim().isNotEmpty
            ? noteController.text.trim()
            : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.provider.strings.rejectedSuccessMsg),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleApproveAll() async {
    final count = widget.provider.pendingApprovalsCount;
    if (count == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.provider.strings.btnApproveAll),
        content: Text(
          widget.provider.strings.isHindi
              ? 'क्या आप सभी $count लंबित कार्यों को मंज़ूर करना चाहते हैं?'
              : 'Do you want to approve all $count pending delivery boy actions?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(widget.provider.strings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(widget.provider.strings.confirm),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.provider.approveAllPending();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.provider.strings.isHindi
                ? 'सभी $count कार्य मंज़ूर कर दिए गए!'
                : 'All $count actions approved successfully!',
          ),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  Widget _buildRequestCard(ApprovalRequest req) {
    final s = widget.provider.strings;
    final actionColor = _colorForAction(req.actionType);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: req.isPending
              ? actionColor.withOpacity(0.35)
              : Colors.grey.shade200,
          width: req.isPending ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Action badge + status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconForAction(req.actionType),
                        size: 16,
                        color: actionColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        req.actionType.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: actionColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (req.isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Text(
                      s.isHindi ? 'मंज़ूरी बाकी' : 'Pending Review',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  )
                else if (req.isApproved)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 13,
                          color: Color(0xFF065F46),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s.isHindi ? 'मंज़ूर' : 'Approved',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cancel,
                          size: 13,
                          color: Color(0xFF991B1B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s.isHindi ? 'अस्वीकृत' : 'Rejected',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Title
            Text(
              req.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),

            if (req.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                req.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                ),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Submitter & Reviewer info
            Row(
              children: [
                Icon(
                  Icons.delivery_dining,
                  size: 15,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${req.requestedBy} • ${_formatDateTime(req.requestedAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),

            if (req.reviewedBy != null && req.reviewedAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 15,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reviewed by ${req.reviewedBy} • ${_formatDateTime(req.reviewedAt!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],

            if (req.reviewNote != null && req.reviewNote!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Note: ${req.reviewNote}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            // Action Buttons for Pending items
            if (req.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFF87171)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _handleReject(req),
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(s.btnReject),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _handleApprove(req),
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(s.btnApprove),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.provider,
      builder: (context, _) {
        final s = widget.provider.strings;
        final pending = widget.provider.approvalRequests
            .where((r) => r.isPending)
            .toList();
        final approved = widget.provider.approvalRequests
            .where((r) => r.isApproved)
            .toList();
        final rejected = widget.provider.approvalRequests
            .where((r) => r.isRejected)
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(
              s.approvalsTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF38BDF8),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFFCBD5E1),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.pendingApprovalsTab),
                      if (pending.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${pending.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(text: '${s.approvedTab} (${approved.length})'),
                Tab(text: '${s.rejectedTab} (${rejected.length})'),
              ],
            ),
            actions: [
              IconButton(
                tooltip: widget.provider.strings.isHindi
                    ? 'क्लाउड से रिफ्रेश करें'
                    : 'Refresh from Cloud',
                icon: widget.provider.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: widget.provider.isSyncing
                    ? null
                    : () async {
                        final res = await widget.provider
                            .syncWithCloud(forceDownload: true);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.message),
                            backgroundColor: res.success
                                ? const Color(0xFF059669)
                                : const Color(0xFFDC2626),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
              ),
              if (pending.isNotEmpty)
                IconButton(
                  tooltip: s.btnApproveAll,
                  icon: const Icon(Icons.done_all),
                  onPressed: _handleApproveAll,
                ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Pending
              RefreshIndicator(
                onRefresh: () async {
                  await widget.provider.syncWithCloud(forceDownload: true);
                },
                child: pending.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  s.noPendingApprovals,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: pending.length,
                        itemBuilder: (ctx, i) => _buildRequestCard(pending[i]),
                      ),
              ),

              // Tab 2: Approved
              RefreshIndicator(
                onRefresh: () async {
                  await widget.provider.syncWithCloud(forceDownload: true);
                },
                child: approved.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 140),
                          Center(
                            child: Text(
                              s.isHindi
                                  ? 'कोई मंज़ूर किया गया कार्य नहीं है'
                                  : 'No approved action history',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: approved.length,
                        itemBuilder: (ctx, i) => _buildRequestCard(approved[i]),
                      ),
              ),

              // Tab 3: Rejected
              RefreshIndicator(
                onRefresh: () async {
                  await widget.provider.syncWithCloud(forceDownload: true);
                },
                child: rejected.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 140),
                          Center(
                            child: Text(
                              s.isHindi
                                  ? 'कोई अस्वीकृत कार्य नहीं है'
                                  : 'No rejected action history',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: rejected.length,
                        itemBuilder: (ctx, i) => _buildRequestCard(rejected[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
