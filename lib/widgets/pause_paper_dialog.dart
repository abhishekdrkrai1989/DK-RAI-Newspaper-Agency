import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../providers/delivery_provider.dart';

Future<void> showPausePaperDialog({
  required BuildContext context,
  required DeliveryProvider provider,
  required Customer customer,
}) async {
  final s = provider.strings;
  if (!provider.canCurrentUserAccessBlock(customer.block)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.cannotModifyOtherBlock),
        backgroundColor: Colors.red.shade700,
      ),
    );
    return;
  }
  bool useDateRange = false;
  DateTime startDate = provider.selectedDate;
  DateTime endDate = provider.selectedDate.add(const Duration(days: 3));
  final reasonController = TextEditingController(text: customer.pauseReason);

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.pause_circle_filled, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.pauseDialogTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${customer.houseNumber} • ${customer.name}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RadioGroup<bool>(
                    groupValue: useDateRange,
                    onChanged: (val) => setState(() => useDateRange = val ?? false),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<bool>(
                          contentPadding: EdgeInsets.zero,
                          value: false,
                          title: Text(
                            s.pauseIndefinitely,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        RadioListTile<bool>(
                          contentPadding: EdgeInsets.zero,
                          value: true,
                          title: Text(
                            s.pauseForDateRange,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (useDateRange) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              '${s.pauseFromDate}\n${s.formatDate(startDate)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: startDate,
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() {
                                  startDate = picked;
                                  if (endDate.isBefore(startDate)) {
                                    endDate = startDate;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event_available, size: 16),
                            label: Text(
                              '${s.resumeAfterDate}\n${s.formatDate(endDate)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: endDate,
                                firstDate: startDate,
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() => endDate = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: s.pauseReasonLabel,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(s.cancel),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.pause, size: 18),
                label: Text(s.btnPausePaper),
                onPressed: () async {
                  final isBoy = !provider.isOwner;
                  await provider.pauseCustomerPaper(
                    customer.id,
                    pauseStartDate: useDateRange ? startDate : null,
                    pauseEndDate: useDateRange ? endDate : null,
                    reason: reasonController.text.trim(),
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (isBoy && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          s.tr(
                            'Pause request submitted for Admin/Owner approval',
                            'अखबार बंद करने का अनुरोध एडमिन मंज़ूरी के लिए भेजा गया',
                          ),
                        ),
                        backgroundColor: Colors.amber.shade800,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}
