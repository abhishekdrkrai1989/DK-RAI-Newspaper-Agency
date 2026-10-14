import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../models/customer.dart';
import '../models/publication.dart';
import '../providers/delivery_provider.dart';

class CustomerMonthlySummary {
  final Customer customer;
  final int activeDays;
  final int pausedDays;
  final Map<SubscriptionItem, int> itemDeliveredDays;
  final Map<SubscriptionItem, double> itemAmounts;
  final double totalBill;

  const CustomerMonthlySummary({
    required this.customer,
    required this.activeDays,
    required this.pausedDays,
    required this.itemDeliveredDays,
    required this.itemAmounts,
    required this.totalBill,
  });
}

class MonthlyBillingReportScreen extends StatefulWidget {
  final DeliveryProvider provider;

  const MonthlyBillingReportScreen({super.key, required this.provider});

  @override
  State<MonthlyBillingReportScreen> createState() =>
      _MonthlyBillingReportScreenState();
}

class _MonthlyBillingReportScreenState
    extends State<MonthlyBillingReportScreen> {
  late int _year;
  late int _month;
  String? _selectedSociety;
  String? _selectedBlock;

  @override
  void initState() {
    super.initState();
    final d = widget.provider.selectedDate;
    _year = d.year;
    _month = d.month;
    _selectedSociety = widget.provider.selectedArea;
    _selectedBlock = widget.provider.selectedBlock;
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year -= 1;
      } else {
        _month -= 1;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year += 1;
      } else {
        _month += 1;
      }
    });
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  CustomerMonthlySummary _computeCustomerMonthlySummary(Customer customer) {
    final totalDays = _daysInMonth(_year, _month);
    int activeDays = 0;
    int pausedDays = 0;

    final itemDays = <SubscriptionItem, int>{
      for (final sub in customer.subscriptions) sub: 0,
    };
    final itemAmounts = <SubscriptionItem, double>{
      for (final sub in customer.subscriptions) sub: 0.0,
    };

    for (int day = 1; day <= totalDays; day++) {
      final date = DateTime(_year, _month, day);
      final isStarted = customer.isStartedOnDate(date);
      if (isStarted) {
        activeDays++;
        for (final sub in customer.subscriptions) {
          if (sub.isDeliverableOnDate(date)) {
            final pub = widget.provider.getPublicationById(sub.publicationId);
            final price = pub?.priceForDate(date) ?? 5.0;
            itemDays[sub] = (itemDays[sub] ?? 0) + 1;
            itemAmounts[sub] =
                (itemAmounts[sub] ?? 0.0) + (price * sub.quantity);
          }
        }
      } else {
        pausedDays++;
      }
    }

    final totalBill =
        itemAmounts.values.fold<double>(0.0, (sum, val) => sum + val);

    return CustomerMonthlySummary(
      customer: customer,
      activeDays: activeDays,
      pausedDays: pausedDays,
      itemDeliveredDays: itemDays,
      itemAmounts: itemAmounts,
      totalBill: totalBill,
    );
  }

  List<String> _availableBlocks(List<Customer> all) {
    final set = <String>{};
    for (final c in all) {
      if (_selectedSociety != null &&
          _selectedSociety!.isNotEmpty &&
          c.area.trim().toLowerCase() != _selectedSociety!.toLowerCase()) {
        continue;
      }
      if (c.block.trim().isNotEmpty) {
        set.add(c.block.trim());
      }
    }
    return set.toList()..sort();
  }

  /// Groups filtered customers Society-wise and sorts Address-wise (Block -> House No.)
  Map<String, List<CustomerMonthlySummary>> _groupedBySociety() {
    final filtered = widget.provider.allCustomers.where((c) {
      if (_selectedSociety != null && _selectedSociety!.isNotEmpty) {
        if (c.area.trim().toLowerCase() != _selectedSociety!.toLowerCase()) {
          return false;
        }
      }
      if (_selectedBlock != null && _selectedBlock!.isNotEmpty) {
        if (c.block.trim().toLowerCase() != _selectedBlock!.toLowerCase()) {
          return false;
        }
      }
      return true;
    }).toList();

    // Sort address-wise: Society -> Block -> House Number
    filtered.sort((a, b) {
      final socCmp = a.area.toLowerCase().compareTo(b.area.toLowerCase());
      if (socCmp != 0) return socCmp;
      final blkCmp = a.block.toLowerCase().compareTo(b.block.toLowerCase());
      if (blkCmp != 0) return blkCmp;
      return a.houseNumber
          .toLowerCase()
          .compareTo(b.houseNumber.toLowerCase());
    });

    final grouped = <String, List<CustomerMonthlySummary>>{};
    for (final c in filtered) {
      final societyKey = c.area.trim().isNotEmpty ? c.area.trim() : 'General';
      grouped.putIfAbsent(societyKey, () => []);
      grouped[societyKey]!.add(_computeCustomerMonthlySummary(c));
    }
    return grouped;
  }

  Future<void> _copyReportToClipboard(
    Map<String, List<CustomerMonthlySummary>> grouped,
    AppStrings s,
  ) async {
    final buf = StringBuffer();
    buf.writeln(s.appTitle);
    buf.writeln(
      '${s.monthlyBillingTitle} — ${s.monthYearName(_year, _month)}',
    );
    buf.writeln('================================================');

    for (final entry in grouped.entries) {
      final society = entry.key;
      final summaries = entry.value;
      final societyTotal = summaries.fold<double>(
        0.0,
        (sum, item) => sum + item.totalBill,
      );

      buf.writeln('\n🏢 $society (${s.totalSocietyBill}: ₹${societyTotal.toStringAsFixed(0)})');
      buf.writeln('------------------------------------------------');

      for (final summary in summaries) {
        final c = summary.customer;
        final addr = [
          if (c.block.isNotEmpty) c.block,
          c.houseNumber,
        ].join(' • ');
        buf.writeln(
          '• $addr — ${c.name}  |  Bill: ₹${summary.totalBill.toStringAsFixed(0)} (${s.activeDaysLabel}: ${summary.activeDays}, ${s.pausedDaysLabel}: ${summary.pausedDays})',
        );

        // Newspapers
        for (final sub in c.subscriptions) {
          final pub = widget.provider.getPublicationById(sub.publicationId);
          final pubName = pub?.displayName(s) ?? sub.publicationId;
          final days = summary.itemDeliveredDays[sub] ?? 0;
          final amt = summary.itemAmounts[sub] ?? 0.0;
          buf.writeln(
            '   Newspaper: $pubName (${sub.frequency.shortLabel(s)} ×${sub.quantity}) -> $days days = ₹${amt.toStringAsFixed(0)}${sub.isPaused ? " [PAUSED]" : ""}',
          );
        }

        // Activities (Pause / Start / Added / Removed newspaper)
        if (c.statusHistory.isNotEmpty) {
          for (final log in c.statusHistory) {
            buf.writeln(
              '   Activity [${s.formatDate(log.timestamp)}]: ${log.note}',
            );
          }
        }
      }
    }

    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.listCopiedMsg),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final p = widget.provider;
        final s = p.strings;
        final societies = p.availableAreas;
        final blocks = _availableBlocks(p.allCustomers);
        final grouped = _groupedBySociety();

        final grandTotalBill = grouped.values
            .expand((e) => e)
            .fold<double>(0.0, (sum, item) => sum + item.totalBill);
        final totalHomes =
            grouped.values.fold<int>(0, (sum, list) => sum + list.length);

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6FB),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.monthlyBillingTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  s.monthYearName(_year, _month),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.amberAccent,
                  ),
                ),
              ],
            ),
            actions: [
              if (grouped.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                    ),
                    icon: const Icon(Icons.copy, size: 16),
                    label: Text(
                      s.copyBillingBtn,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _copyReportToClipboard(grouped, s),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Month Selector + Society/Block Filter Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month Navigation Row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEF8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.chevron_left,
                              color: Color(0xFF1E3A8A),
                            ),
                            onPressed: _prevMonth,
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                s.monthYearName(_year, _month),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF1E3A8A),
                            ),
                            onPressed: _nextMonth,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Society Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            visualDensity: VisualDensity.compact,
                            label: Text(s.allSocieties),
                            selected: _selectedSociety == null,
                            selectedColor: const Color(0xFF1E3A8A),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _selectedSociety == null
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                            onSelected: (_) {
                              setState(() => _selectedSociety = null);
                            },
                          ),
                          ...societies.map((soc) {
                            final isSelected = _selectedSociety != null &&
                                _selectedSociety!.toLowerCase() ==
                                    soc.toLowerCase();
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: ChoiceChip(
                                visualDensity: VisualDensity.compact,
                                label: Text(soc),
                                selected: isSelected,
                                selectedColor: const Color(0xFF1E3A8A),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isSelected ? Colors.white : Colors.black87,
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    _selectedSociety = isSelected ? null : soc;
                                    final newBlocks =
                                        _availableBlocks(p.allCustomers);
                                    if (_selectedBlock != null &&
                                        !newBlocks.any(
                                          (b) =>
                                              b.toLowerCase() ==
                                              _selectedBlock!.toLowerCase(),
                                        )) {
                                      _selectedBlock = null;
                                    }
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    if (blocks.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              visualDensity: VisualDensity.compact,
                              label: Text(s.allBlocks),
                              selected: _selectedBlock == null,
                              selectedColor: Colors.indigo.shade700,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _selectedBlock == null
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              onSelected: (_) {
                                setState(() => _selectedBlock = null);
                              },
                            ),
                            ...blocks.map((blk) {
                              final isSelected = _selectedBlock != null &&
                                  _selectedBlock!.toLowerCase() ==
                                      blk.toLowerCase();
                              return Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: ChoiceChip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(blk),
                                  selected: isSelected,
                                  selectedColor: Colors.indigo.shade700,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedBlock = isSelected ? null : blk;
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),

              // Grand Total Bar
              Container(
                width: double.infinity,
                color: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      '${s.totalCustomers}: $totalHomes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${s.totalSocietyBill}: ₹${grandTotalBill.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              // Society-Wise & Address-Wise Customer Billing & Activity Cards
              Expanded(
                child: grouped.isEmpty
                    ? Center(
                        child: Text(
                          s.noActivePapersForDay,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: grouped.length,
                        itemBuilder: (context, socIndex) {
                          final societyName =
                              grouped.keys.elementAt(socIndex);
                          final summaries = grouped[societyName]!;
                          final societyBill = summaries.fold<double>(
                            0.0,
                            (sum, item) => sum + item.totalBill,
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Society Header Banner
                              Container(
                                margin: const EdgeInsets.only(
                                  top: 6,
                                  bottom: 8,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade900,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.apartment,
                                      color: Colors.amberAccent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$societyName (${summaries.length})',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '₹${societyBill.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.amberAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Address-Wise Customer Cards within this Society
                              ...summaries.map((summary) {
                                final c = summary.customer;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: summary.pausedDays > 0
                                          ? Colors.orange.shade300
                                          : Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Top Row: Address (Block + Flat No.) + Customer Name + Monthly Bill
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 9,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1E3A8A),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                c.block.isNotEmpty
                                                    ? '${c.block} • ${c.houseNumber}'
                                                    : c.houseNumber,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    c.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  Text(
                                                    c.area,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.green.shade400,
                                                ),
                                              ),
                                              child: Text(
                                                '₹${summary.totalBill.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Colors.green.shade900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // Active Days vs Paused Days Chips
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${s.activeDaysLabel}: ${summary.activeDays}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green.shade900,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: summary.pausedDays > 0
                                                    ? Colors.deepOrange.shade100
                                                    : Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${s.pausedDaysLabel}: ${summary.pausedDays}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: summary.pausedDays > 0
                                                      ? Colors
                                                          .deepOrange.shade900
                                                      : Colors.grey.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 16),

                                        // Subscribed Newspapers & Monthly Breakdown
                                        ...c.subscriptions.map((sub) {
                                          final pub = p.getPublicationById(
                                            sub.publicationId,
                                          );
                                          final pubName = pub?.displayName(s) ??
                                              sub.publicationId;
                                          final days =
                                              summary.itemDeliveredDays[sub] ??
                                                  0;
                                          final amt =
                                              summary.itemAmounts[sub] ?? 0.0;

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.newspaper,
                                                  size: 15,
                                                  color: Color(0xFF1E3A8A),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    '$pubName (${sub.frequency.shortLabel(s)} ×${sub.quantity})',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      decoration: sub.isPaused
                                                          ? TextDecoration
                                                              .lineThrough
                                                          : null,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '$days d  •  ₹${amt.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1E3A8A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),

                                        const SizedBox(height: 8),
                                        // Activity Log Section (All Pause, Start, Added & Removed Newspaper logs)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                s.monthlyActivitiesLabel,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey.shade800,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              if (c.statusHistory.isEmpty)
                                                Text(
                                                  s.noActivityRecorded,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                )
                                              else
                                                ...c.statusHistory.map((log) {
                                                  final isAddedOrStarted = log
                                                              .status ==
                                                          DeliveryStatus
                                                              .started &&
                                                      !log.note
                                                          .toLowerCase()
                                                          .contains('removed');
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      top: 3,
                                                    ),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Icon(
                                                          isAddedOrStarted
                                                              ? Icons
                                                                  .add_circle_outline
                                                              : Icons
                                                                  .remove_circle_outline,
                                                          size: 14,
                                                          color: isAddedOrStarted
                                                              ? Colors
                                                                  .green.shade700
                                                              : Colors
                                                                  .deepOrange,
                                                        ),
                                                        const SizedBox(width: 5),
                                                        Expanded(
                                                          child: Text(
                                                            log.note,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          s.formatDate(
                                                            log.timestamp,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors
                                                                .grey.shade600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
