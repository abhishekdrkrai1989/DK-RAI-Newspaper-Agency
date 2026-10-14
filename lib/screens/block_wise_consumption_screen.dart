import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../models/customer.dart';
import '../models/publication.dart';
import '../providers/delivery_provider.dart';

class BlockConsumptionGroup {
  final String blockName;
  final String societyName;
  final int activeHomesCount;
  final Map<Publication, int> paperCounts;

  const BlockConsumptionGroup({
    required this.blockName,
    required this.societyName,
    required this.activeHomesCount,
    required this.paperCounts,
  });

  int get totalCopies =>
      paperCounts.values.fold<int>(0, (sum, count) => sum + count);
}

class BlockWiseConsumptionScreen extends StatefulWidget {
  final DeliveryProvider provider;

  const BlockWiseConsumptionScreen({super.key, required this.provider});

  @override
  State<BlockWiseConsumptionScreen> createState() =>
      _BlockWiseConsumptionScreenState();
}

class _BlockWiseConsumptionScreenState
    extends State<BlockWiseConsumptionScreen> {
  late DateTime _date;
  String? _selectedSociety;
  String? _selectedBlock;

  @override
  void initState() {
    super.initState();
    _date = widget.provider.selectedDate;
    _selectedSociety = widget.provider.selectedArea;
    _selectedBlock = widget.provider.selectedBlock;
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

  List<Customer> _matchingCustomers() {
    return widget.provider.allCustomers.where((c) {
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
  }

  /// Overall newspaper consumption for [_date] across matching customers
  Map<Publication, int> _overallConsumption(List<Customer> customers) {
    final counts = <String, int>{};
    for (final c in customers) {
      for (final sub in c.deliverableSubscriptionsOnDate(_date)) {
        counts[sub.publicationId] =
            (counts[sub.publicationId] ?? 0) + sub.quantity;
      }
    }
    final result = <Publication, int>{};
    for (final pub in widget.provider.publications) {
      final count = counts[pub.id] ?? 0;
      if (count > 0) {
        result[pub] = count;
      }
    }
    return result;
  }

  /// Block-wise breakdown of newspaper consumption for [_date]
  List<BlockConsumptionGroup> _blockWiseGroups(
    List<Customer> customers,
    AppStrings s,
  ) {
    final mapByKey = <String, List<Customer>>{};
    for (final c in customers) {
      final society = c.area.trim().isNotEmpty
          ? c.area.trim()
          : s.tr('General Society', 'सामान्य कॉलोनी');
      final block = c.block.trim().isNotEmpty
          ? c.block.trim()
          : s.tr('General Block', 'सामान्य ब्लॉक');
      final key = '$society|||$block';
      mapByKey.putIfAbsent(key, () => []);
      mapByKey[key]!.add(c);
    }

    final sortedKeys = mapByKey.keys.toList()..sort();
    final groups = <BlockConsumptionGroup>[];

    for (final key in sortedKeys) {
      final parts = key.split('|||');
      final societyName = parts[0];
      final blockName = parts[1];
      final blockCustomers = mapByKey[key]!;

      int activeHomes = 0;
      final counts = <String, int>{};
      for (final c in blockCustomers) {
        final subs = c.deliverableSubscriptionsOnDate(_date);
        if (subs.isNotEmpty) {
          activeHomes++;
          for (final sub in subs) {
            counts[sub.publicationId] =
                (counts[sub.publicationId] ?? 0) + sub.quantity;
          }
        }
      }

      final pubCounts = <Publication, int>{};
      for (final pub in widget.provider.publications) {
        final cnt = counts[pub.id] ?? 0;
        if (cnt > 0) {
          pubCounts[pub] = cnt;
        }
      }

      groups.add(
        BlockConsumptionGroup(
          blockName: blockName,
          societyName: societyName,
          activeHomesCount: activeHomes,
          paperCounts: pubCounts,
        ),
      );
    }
    return groups;
  }

  Future<void> _copyConsumptionReport(
    Map<Publication, int> overall,
    List<BlockConsumptionGroup> groups,
    AppStrings s,
  ) async {
    final dateStr = s.formatDateDash(_date);
    final buf = StringBuffer();
    buf.writeln(s.appTitle);

    final filterLabel = [
      if (_selectedSociety != null) _selectedSociety!,
      if (_selectedBlock != null) _selectedBlock!,
    ].join(' - ');

    buf.writeln(
      filterLabel.isNotEmpty
          ? 'For $dateStr ($filterLabel):'
          : 'For $dateStr:',
    );
    if (overall.isEmpty) {
      buf.writeln('No active newspapers scheduled.');
    } else {
      for (final entry in overall.entries) {
        buf.writeln('${entry.key.displayName(s)}: ${entry.value}');
      }
    }

    if (groups.isNotEmpty) {
      buf.writeln('\n--- ${s.blockWiseBreakdownTitle} ($dateStr) ---');
      for (final g in groups) {
        buf.writeln('\n[${g.blockName} • ${g.societyName}]');
        if (g.paperCounts.isEmpty) {
          buf.writeln('  (0 active papers)');
        } else {
          for (final entry in g.paperCounts.entries) {
            buf.writeln('  ${entry.key.displayName(s)}: ${entry.value}');
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
        final matching = _matchingCustomers();
        final overall = _overallConsumption(matching);
        final groups = _blockWiseGroups(matching, s);
        final totalCopies =
            overall.values.fold<int>(0, (sum, count) => sum + count);
        final dateStr = s.formatDateDash(_date);

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6FB),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.blockConsumptionTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${s.weekdayName(_date.weekday)} • $dateStr',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.amberAccent,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                  ),
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(
                    s.copyListBtn,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () =>
                      _copyConsumptionReport(overall, groups, s),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Date Picker & Society/Block Filter Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Selector Strip
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
                            onPressed: () {
                              setState(() {
                                _date = _date.subtract(const Duration(days: 1));
                              });
                            },
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _date,
                                  firstDate: DateTime(2024),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() => _date = picked);
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.calendar_month,
                                    size: 16,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'For $dateStr (${s.weekdayName(_date.weekday)})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF1E3A8A),
                            ),
                            onPressed: () {
                              setState(() {
                                _date = _date.add(const Duration(days: 1));
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Society Filter Chips
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
                      // Block Filter Chips
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

              // Main Content: 1) Overall "For DD-MM-YYYY:" Card + 2) Block-Wise Cards
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // 1. Top Summary Card ("For 21-10-2026: \n Times Of India: 10 ...")
                    Card(
                      elevation: 2,
                      color: const Color(0xFF1E3A8A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.summarize_outlined,
                                  color: Colors.amberAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'For $dateStr${_selectedBlock != null ? " ($_selectedBlock)" : (_selectedSociety != null ? " ($_selectedSociety)" : "")}:',
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${s.todayCopies}: $totalCopies',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24, height: 20),
                            if (overall.isEmpty)
                              Text(
                                s.noActivePapersForDay,
                                style: const TextStyle(color: Colors.white70),
                              )
                            else
                              ...overall.entries.map((entry) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${entry.key.displayName(s)}:',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amberAccent,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${entry.value}',
                                          style: const TextStyle(
                                            color: Color(0xFF1E3A8A),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Block-Wise Breakdown Header
                    Text(
                      '${s.blockWiseBreakdownTitle} ($dateStr)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Block-Wise Cards
                    ...groups.map((group) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.indigo.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade800,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      group.blockName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      group.societyName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      '${group.totalCopies} ${s.copiesUnit}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 18),
                              Text(
                                'For $dateStr (${group.blockName}):',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (group.paperCounts.isEmpty)
                                Text(
                                  s.noActivePapersForDay,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                )
                              else
                                ...group.paperCounts.entries.map((entry) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        Icon(
                                          entry.key.type ==
                                                  PublicationType.magazine
                                              ? Icons.menu_book
                                              : Icons.newspaper,
                                          size: 16,
                                          color: const Color(0xFF1E3A8A),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${entry.key.displayName(s)}:',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.blue.shade200,
                                            ),
                                          ),
                                          child: Text(
                                            '${entry.value}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E3A8A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
