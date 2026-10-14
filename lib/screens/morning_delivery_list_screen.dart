import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../models/customer.dart';
import '../models/publication.dart';
import '../providers/delivery_provider.dart';

class MorningDeliveryListScreen extends StatefulWidget {
  final DeliveryProvider provider;

  const MorningDeliveryListScreen({super.key, required this.provider});

  @override
  State<MorningDeliveryListScreen> createState() =>
      _MorningDeliveryListScreenState();
}

class _MorningDeliveryListScreenState extends State<MorningDeliveryListScreen> {
  String? _selectedSociety;
  String? _selectedBlock;

  @override
  void initState() {
    super.initState();
    _selectedSociety = widget.provider.selectedArea;
    _selectedBlock = widget.provider.selectedBlock;
  }

  List<String> _availableBlocksForSociety(List<Customer> all) {
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

  List<Customer> _activeFlatsForMorning(DateTime date) {
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
      // Only include active (started) homes that have at least one paper today
      final subsToday = c.deliverableSubscriptionsOnDate(date);
      return subsToday.isNotEmpty;
    }).toList();
  }

  String _formatPapersForCustomer(
    Customer customer,
    DateTime date,
    AppStrings s,
  ) {
    final subs = customer.deliverableSubscriptionsOnDate(date);
    return subs.map((sub) {
      final pub = widget.provider.getPublicationById(sub.publicationId);
      final name = pub?.displayName(s) ?? sub.publicationId;
      return sub.quantity > 1 ? '$name (×${sub.quantity})' : name;
    }).join(', ');
  }

  Map<Publication, int> _bundleCountForList(
    List<Customer> flats,
    DateTime date,
  ) {
    final counts = <String, int>{};
    for (final c in flats) {
      for (final sub in c.deliverableSubscriptionsOnDate(date)) {
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

  Future<void> _copyToClipboard(
    List<Customer> flats,
    DateTime date,
    AppStrings s,
  ) async {
    final headerParts = <String>[
      s.appTitle,
      s.morningListTitle,
      '${s.weekdayName(date.weekday)} • ${s.formatDate(date)}',
      if (_selectedSociety != null) _selectedSociety!,
      if (_selectedBlock != null) _selectedBlock!,
    ];

    final buffer = StringBuffer();
    buffer.writeln(headerParts.join(' | '));
    buffer.writeln('------------------------------------');
    for (final c in flats) {
      final papers = _formatPapersForCustomer(c, date, s);
      buffer.writeln('${c.houseNumber.padRight(8)} ->  $papers');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
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
        final date = p.selectedDate;
        final societies = p.availableAreas;
        final blocks = _availableBlocksForSociety(p.allCustomers);
        final activeFlats = _activeFlatsForMorning(date);
        final bundle = _bundleCountForList(activeFlats, date);
        final totalCopies = bundle.values.fold<int>(0, (a, b) => a + b);

        final locationTitle = [
          if (_selectedSociety != null) _selectedSociety!,
          if (_selectedBlock != null) _selectedBlock!,
        ].join(' • ');

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6FB),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.morningListTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${s.weekdayName(date.weekday)} • ${s.formatDate(date)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.amberAccent,
                  ),
                ),
              ],
            ),
            actions: [
              if (activeFlats.isNotEmpty)
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
                    onPressed: () => _copyToClipboard(activeFlats, date, s),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Society & Block Selector Bar
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.filterByBlockSociety,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 6),
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
                              setState(() {
                                _selectedSociety = null;
                              });
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
                                        _availableBlocksForSociety(
                                      p.allCustomers,
                                    );
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
                      // Block Chips
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

              // Summary Banner for Selected Society/Block
              Container(
                width: double.infinity,
                color: const Color(0xFFE8EEF8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Color(0xFF1E3A8A),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            locationTitle.isNotEmpty
                                ? locationTitle
                                : '${s.allSocieties} • ${s.allBlocks}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${s.activeFlatsCount}: ${activeFlats.length}  |  ${s.todayCopies}: $totalCopies',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (bundle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: bundle.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              '${e.key.displayName(s)}: ${e.value}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Table Column Headers: ONLY Flat No. and Newspaper Name
              Container(
                color: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 115,
                      child: Text(
                        s.flatNoColumn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.newspaperColumn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Minimalist Flat No. + Newspaper Name List
              Expanded(
                child: activeFlats.isEmpty
                    ? Center(
                        child: Text(
                          s.noActivePapersForDay,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: activeFlats.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final customer = activeFlats[index];
                          final deliverableSubs =
                              customer.deliverableSubscriptionsOnDate(date);

                          return Container(
                            color: index.isEven
                                ? Colors.white
                                : const Color(0xFFF8FAFC),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // ONLY Flat / House No.
                                SizedBox(
                                  width: 115,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E3A8A),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          customer.houseNumber,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // ONLY Newspaper / Magazine Name(s)
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: deliverableSubs.map((sub) {
                                      final pub = p.getPublicationById(
                                        sub.publicationId,
                                      );
                                      final paperName = pub?.displayName(s) ??
                                          sub.publicationId;
                                      final text = sub.quantity > 1
                                          ? '$paperName (×${sub.quantity})'
                                          : paperName;

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
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
                                          text,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E3A8A),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
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
