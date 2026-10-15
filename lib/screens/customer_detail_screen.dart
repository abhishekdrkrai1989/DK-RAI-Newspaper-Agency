import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/publication.dart';
import '../providers/delivery_provider.dart';
import '../widgets/pause_paper_dialog.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  final DeliveryProvider provider;
  final String customerId;

  const CustomerDetailScreen({
    super.key,
    required this.provider,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final s = provider.strings;
        final customer = provider.allCustomers
            .where((c) => c.id == customerId)
            .firstOrNull;

        if (customer == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Customer not found')),
          );
        }

        final isStarted = customer.isStartedOnDate(provider.selectedDate);
        final canModify = provider.canCurrentUserAccessBlock(customer.block);

        return Scaffold(
          appBar: AppBar(
            title: Text('${customer.houseNumber} • ${customer.name}'),
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            actions: [
              if (canModify) ...[
                IconButton(
                  tooltip: s.editCustomer,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomerFormScreen(
                          provider: provider,
                          existingCustomer: customer,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: s.deleteCustomer,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(s.deleteCustomer),
                        content: Text(
                          s.tr(
                            'Remove ${customer.name} (${customer.houseNumber}) from your distribution list?',
                            'क्या आप ${customer.name} (${customer.houseNumber}) को वितरण सूची से हटाना चाहते हैं?',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(s.cancel),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text(s.confirm),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await provider.deleteCustomer(customer.id);
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!canModify)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: Colors.red.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.cannotModifyOtherBlock,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Main Status Banner Card
              Card(
                elevation: 2,
                color: isStarted ? Colors.green.shade50 : Colors.orange.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isStarted
                        ? Colors.green.shade400
                        : Colors.deepOrange.shade300,
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isStarted
                                  ? Colors.green.shade700
                                  : Colors.deepOrange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isStarted
                                      ? Icons.check_circle
                                      : Icons.pause_circle_filled,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isStarted ? s.statusStarted : s.statusPaused,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '#${customer.sequenceNo}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            customer.houseNumber,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          if (customer.block.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                customer.block,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo.shade900,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              customer.area,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (customer.phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 16),
                            const SizedBox(width: 6),
                            Text(customer.phone),
                          ],
                        ),
                      ],
                      if (customer.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Color(0xFF1E3A8A),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(customer.notes)),
                            ],
                          ),
                        ),
                      ],
                      if (!isStarted &&
                          (customer.pauseReason.isNotEmpty ||
                              customer.pauseStartDate != null ||
                              customer.pauseEndDate != null)) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (customer.pauseStartDate != null ||
                                  customer.pauseEndDate != null)
                                Text(
                                  '${s.pauseFromDate}: ${customer.pauseStartDate != null ? s.formatDate(customer.pauseStartDate!) : "-"}  →  ${customer.pauseEndDate != null ? s.formatDate(customer.pauseEndDate!) : "-"}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              if (customer.pauseReason.isNotEmpty)
                                Text(
                                  customer.pauseReason,
                                  style: const TextStyle(fontSize: 13),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isStarted
                                ? Colors.deepOrange
                                : Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(
                            isStarted ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(
                            isStarted ? s.btnPausePaper : s.btnStartPaper,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          onPressed: !canModify
                              ? null
                              : () {
                                  if (isStarted) {
                                    showPausePaperDialog(
                                      context: context,
                                      provider: provider,
                                      customer: customer,
                                    );
                                  } else {
                                    provider.startCustomerPaper(customer.id);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Subscribed Newspapers & Magazines Section
              Text(
                s.tr(
                  'Subscribed Newspapers & Magazines (Tap switch to pause single paper)',
                  'सब्सक्राइब किए गए अखबार और पत्रिकाएं (किसी एक को बंद करने के लिए स्विच दबाएं)',
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 8),
              ...customer.subscriptions.map((sub) {
                final pub = provider.getPublicationById(sub.publicationId);
                final pubName = pub?.displayName(s) ?? sub.publicationId;
                final isPaperActive = !sub.isPaused && isStarted;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPaperActive
                          ? Colors.blue.shade50
                          : Colors.grey.shade200,
                      child: Icon(
                        pub?.type == PublicationType.magazine
                            ? Icons.menu_book
                            : Icons.newspaper,
                        color: isPaperActive
                            ? const Color(0xFF1E3A8A)
                            : Colors.grey,
                      ),
                    ),
                    title: Text(
                      pubName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration:
                            sub.isPaused ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      '${sub.frequency.label(s)} • ${s.quantityLabel}: ${sub.quantity}',
                    ),
                    trailing: Switch(
                      value: !sub.isPaused,
                      activeThumbColor: Colors.green.shade700,
                      onChanged: !canModify
                          ? null
                          : (_) {
                              provider.toggleSubscriptionItemPause(
                                customer.id,
                                sub.publicationId,
                              );
                            },
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Pause / Start History Log
              Text(
                s.statusHistoryTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 8),
              if (customer.statusHistory.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      s.tr('No history logs yet', 'अभी कोई इतिहास उपलब्ध नहीं है'),
                    ),
                  ),
                )
              else
                ...customer.statusHistory.map((log) {
                  final isLogStarted = log.status == DeliveryStatus.started;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        isLogStarted
                            ? Icons.play_circle_fill
                            : Icons.pause_circle_filled,
                        color: isLogStarted
                            ? Colors.green.shade700
                            : Colors.deepOrange,
                      ),
                      title: Text(
                        isLogStarted ? s.statusStarted : s.statusPaused,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(log.note),
                      trailing: Text(
                        s.formatDate(log.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
