import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/customer.dart';
import '../models/publication.dart';
import '../providers/delivery_provider.dart';

class CustomerFormScreen extends StatefulWidget {
  final DeliveryProvider provider;
  final Customer? existingCustomer;

  const CustomerFormScreen({
    super.key,
    required this.provider,
    this.existingCustomer,
  });

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _houseCtrl;
  late TextEditingController _blockCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _seqCtrl;
  late TextEditingController _notesCtrl;

  late DeliveryStatus _status;
  String? _selectedDeliveryBoyId;
  final Map<String, SubscriptionItem> _selectedSubs = {};

  @override
  void initState() {
    super.initState();
    final c = widget.existingCustomer;
    if (widget.provider.isDeliveryBoy) {
      _selectedDeliveryBoyId = widget.provider.currentUser?.id;
    } else {
      _selectedDeliveryBoyId = c?.deliveryBoyId;
    }
    final nextSeq = widget.provider.allCustomers.isEmpty
        ? 1
        : (widget.provider.allCustomers
                .map((e) => e.sequenceNo)
                .reduce((a, b) => a > b ? a : b) +
            1);

    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _houseCtrl = TextEditingController(text: c?.houseNumber ?? '');

    String initialBlock = c?.block ?? (widget.provider.selectedBlock ?? '');
    if (initialBlock.isEmpty && widget.provider.isDeliveryBoy) {
      initialBlock =
          widget.provider.currentUser?.assignedBlocks.firstOrNull ?? '';
    }
    _blockCtrl = TextEditingController(text: initialBlock);
    _areaCtrl = TextEditingController(
      text: c?.area ?? (widget.provider.selectedArea ?? ''),
    );
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _seqCtrl =
        TextEditingController(text: (c?.sequenceNo ?? nextSeq).toString());
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
    _status = c?.status ?? DeliveryStatus.started;

    if (c != null) {
      for (final sub in c.subscriptions) {
        _selectedSubs[sub.publicationId] = sub;
      }
    } else if (widget.provider.publications.isNotEmpty) {
      final firstPub = widget.provider.publications.first;
      _selectedSubs[firstPub.id] = SubscriptionItem(
        publicationId: firstPub.id,
        frequency: firstPub.defaultFrequency,
        quantity: 1,
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _houseCtrl.dispose();
    _blockCtrl.dispose();
    _areaCtrl.dispose();
    _phoneCtrl.dispose();
    _seqCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final s = widget.provider.strings;
    if (_selectedSubs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.tr(
              'Please select at least one newspaper or magazine',
              'कृपया कम से कम एक अखबार या पत्रिका चुनें',
            ),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final existing = widget.existingCustomer;
    final seq = int.tryParse(_seqCtrl.text.trim()) ?? 1;
    final now = DateTime.now();

    final history = existing != null
        ? [...existing.statusHistory]
        : [
            StatusLog(
              status: _status,
              timestamp: now,
              note: _status == DeliveryStatus.started
                  ? 'Initial registration (Started)'
                  : 'Initial registration (Paused)',
            ),
          ];

    if (existing != null) {
      final oldMap = {
        for (final sub in existing.subscriptions) sub.publicationId: sub,
      };
      // Check added or modified newspapers
      for (final entry in _selectedSubs.entries) {
        final pub = widget.provider.getPublicationById(entry.key);
        final pubName = pub?.nameEn ?? entry.key;
        final oldSub = oldMap[entry.key];
        if (oldSub == null) {
          history.insert(
            0,
            StatusLog(
              status: DeliveryStatus.started,
              timestamp: now,
              note:
                  'Added Newspaper: $pubName (${entry.value.frequency.shortLabel(s)} ×${entry.value.quantity})',
            ),
          );
        } else if (oldSub.frequency != entry.value.frequency ||
            oldSub.quantity != entry.value.quantity) {
          history.insert(
            0,
            StatusLog(
              status: _status,
              timestamp: now,
              note:
                  'Updated Newspaper: $pubName (${entry.value.frequency.shortLabel(s)} ×${entry.value.quantity})',
            ),
          );
        }
      }
      // Check removed newspapers
      for (final oldSub in existing.subscriptions) {
        if (!_selectedSubs.containsKey(oldSub.publicationId)) {
          final pub = widget.provider.getPublicationById(oldSub.publicationId);
          final pubName = pub?.nameEn ?? oldSub.publicationId;
          history.insert(
            0,
            StatusLog(
              status: DeliveryStatus.paused,
              timestamp: now,
              note: 'Removed Newspaper: $pubName',
            ),
          );
        }
      }
    }

    if (existing != null && existing.status != _status) {
      history.insert(
        0,
        StatusLog(
          status: _status,
          timestamp: now,
          note: _status == DeliveryStatus.started
              ? 'Updated to Started'
              : 'Updated to Paused',
        ),
      );
    }

    final houseNo = _houseCtrl.text.trim();
    final blockText = _blockCtrl.text.trim();
    final resolvedBlock = blockText.isNotEmpty
        ? blockText
        : Customer.inferBlockFromHouseNumber(houseNo);

    if (widget.provider.isDeliveryBoy &&
        !widget.provider.canCurrentUserAccessBlock(resolvedBlock)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.cannotModifyOtherBlock),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    if (existing != null &&
        widget.provider.isDeliveryBoy &&
        !widget.provider.canCurrentUserAccessBlock(existing.block)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.cannotModifyOtherBlock),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    String? assignedName;
    if (_selectedDeliveryBoyId != null && _selectedDeliveryBoyId!.isNotEmpty) {
      final boy = widget.provider.allUsers.firstWhere(
        (u) => u.id == _selectedDeliveryBoyId,
        orElse: () => AppUser(
          id: '',
          name: '',
          role: UserRole.deliveryBoy,
          pin: '',
        ),
      );
      if (boy.name.isNotEmpty) assignedName = boy.name;
    }

    final customer = Customer(
      id: existing?.id ?? 'cust_${now.millisecondsSinceEpoch}',
      sequenceNo: seq,
      name: _nameCtrl.text.trim(),
      houseNumber: houseNo,
      block: resolvedBlock,
      area: _areaCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      status: _status,
      pauseStartDate:
          _status == DeliveryStatus.paused ? existing?.pauseStartDate : null,
      pauseEndDate:
          _status == DeliveryStatus.paused ? existing?.pauseEndDate : null,
      pauseReason:
          _status == DeliveryStatus.paused ? (existing?.pauseReason ?? '') : '',
      deliveryBoyId: _selectedDeliveryBoyId ?? '',
      deliveryBoyName: assignedName ?? '',
      subscriptions: _selectedSubs.values.toList(),
      deliveredDates: existing?.deliveredDates ?? const [],
      statusHistory: history,
      notes: _notesCtrl.text.trim(),
    );

    final ok = await widget.provider.saveCustomer(customer);
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.cannotModifyOtherBlock),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return;
    }
    if (mounted) {
      if (!widget.provider.isOwner) {
        final isEdit = widget.existingCustomer != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? s.tr(
                      'Customer update submitted for Admin/Owner approval',
                      'ग्राहक अपडेट एडमिन मंज़ूरी के लिए भेजा गया',
                    )
                  : s.tr(
                      'New customer submitted for Admin/Owner approval',
                      'नया ग्राहक एडमिन मंज़ूरी के लिए भेजा गया',
                    ),
            ),
            backgroundColor: Colors.amber.shade800,
          ),
        );
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.provider.strings;
    final isEditing = widget.existingCustomer != null;
    final canEditCurrent = !isEditing ||
        !widget.provider.isDeliveryBoy ||
        widget.provider
            .canCurrentUserAccessBlock(widget.existingCustomer!.block);
    final publications = widget.provider.publications;
    final existingSocieties = widget.provider.availableAreas;
    final existingBlocks = widget.provider.isDeliveryBoy
        ? (widget.provider.currentUser?.assignedBlocks ?? const <String>[])
        : widget.provider.allManagedBlocks;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? s.editCustomer : s.addCustomer),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!canEditCurrent)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
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
            // Route Sequence & House Number Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _seqCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: s.sequenceNumber,
                      prefixIcon: const Icon(Icons.format_list_numbered),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _houseCtrl,
                    decoration: InputDecoration(
                      labelText: s.houseNumber,
                      prefixIcon: const Icon(Icons.home_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      if (_blockCtrl.text.trim().isEmpty) {
                        final inferred =
                            Customer.inferBlockFromHouseNumber(val);
                        if (inferred.isNotEmpty) {
                          _blockCtrl.text = inferred;
                        }
                      }
                    },
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? s.tr('Required', 'आवश्यक है')
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: s.customerName,
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? s.tr('Enter customer name', 'ग्राहक का नाम दर्ज करें')
                  : null,
            ),
            const SizedBox(height: 14),

            // Society / Colony Field + Quick Chips
            TextFormField(
              controller: _areaCtrl,
              decoration: InputDecoration(
                labelText: s.areaColony,
                prefixIcon: const Icon(Icons.apartment_outlined),
                border: const OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? s.tr('Enter society or colony', 'सोसाइटी/कॉलोनी दर्ज करें')
                  : null,
            ),
            if (existingSocieties.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: existingSocieties.map((soc) {
                  return ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.apartment, size: 14),
                    label: Text(soc, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        _areaCtrl.text = soc;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 14),

            // Block / Wing / Tower Field + Quick Chips
            TextFormField(
              controller: _blockCtrl,
              readOnly: !canEditCurrent ||
                  (widget.provider.isDeliveryBoy &&
                      (widget.provider.currentUser?.assignedBlocks.length ??
                              0) <=
                          1),
              decoration: InputDecoration(
                labelText: s.blockTower,
                prefixIcon: const Icon(Icons.domain_outlined),
                helperText: widget.provider.isDeliveryBoy
                    ? '${s.assignedBlocksLabel}: ${(widget.provider.currentUser?.assignedBlocks ?? []).join(", ")}'
                    : null,
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final text = (v ?? '').trim();
                final resolved = text.isNotEmpty
                    ? text
                    : Customer.inferBlockFromHouseNumber(
                        _houseCtrl.text.trim(),
                      );
                if (widget.provider.isDeliveryBoy &&
                    !widget.provider.canCurrentUserAccessBlock(resolved)) {
                  return s.cannotModifyOtherBlock;
                }
                return null;
              },
            ),
            if (existingBlocks.isNotEmpty && canEditCurrent) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: existingBlocks.map((blk) {
                  return ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.grid_view, size: 14),
                    label: Text(blk, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        _blockCtrl.text = blk;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 14),

            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: s.phoneNumber,
                prefixIcon: const Icon(Icons.phone_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            // Delivery Boy / Hawker Assignment (Admin / Owner only)
            if (widget.provider.isOwner) ...[
              DropdownButtonFormField<String?>(
                value: _selectedDeliveryBoyId,
                decoration: InputDecoration(
                  labelText: s.tr(
                    'Assigned Hawker / Delivery Boy',
                    'सौंपा गया हॉकर / डिलीवरी बॉय',
                  ),
                  prefixIcon: const Icon(Icons.two_wheeler_outlined),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child:
                        Text(s.tr('Auto / Unassigned', 'स्वचालित / कोई नहीं')),
                  ),
                  ...widget.provider.allUsers
                      .where((u) => u.isDeliveryBoy)
                      .map((boy) {
                    return DropdownMenuItem<String?>(
                      value: boy.id,
                      child: Text(
                        '${boy.name} (${boy.assignedArea.isNotEmpty ? boy.assignedArea : boy.phone})',
                      ),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedDeliveryBoyId = val;
                  });
                },
              ),
              const SizedBox(height: 14),
            ],

            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: s.deliveryNotes,
                prefixIcon: const Icon(Icons.sticky_note_2_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),

            // Status Selector Card (Started vs Paused)
            Card(
              elevation: 0,
              color: _status == DeliveryStatus.started
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _status == DeliveryStatus.started
                      ? Colors.green.shade300
                      : Colors.orange.shade300,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      _status == DeliveryStatus.started
                          ? Icons.play_circle_fill
                          : Icons.pause_circle_filled,
                      color: _status == DeliveryStatus.started
                          ? Colors.green.shade700
                          : Colors.deepOrange,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.tr('Paper Delivery Status', 'पेपर वितरण स्थिति'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _status == DeliveryStatus.started
                                ? s.statusStarted
                                : s.statusPaused,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _status == DeliveryStatus.started
                                  ? Colors.green.shade800
                                  : Colors.deepOrange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _status == DeliveryStatus.started,
                      activeThumbColor: Colors.green.shade700,
                      onChanged: (val) {
                        setState(() {
                          _status = val
                              ? DeliveryStatus.started
                              : DeliveryStatus.paused;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Multiple Newspapers & Magazines Section with Daily/Weekend Variants
            Text(
              s.selectSubscriptions,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            ...publications.map((pub) {
              final isSelected = _selectedSubs.containsKey(pub.id);
              final sub = _selectedSubs[pub.id];

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: isSelected ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF1E3A8A)
                        : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isSelected,
                        activeColor: const Color(0xFF1E3A8A),
                        title: Row(
                          children: [
                            Icon(
                              pub.type == PublicationType.magazine
                                  ? Icons.menu_book
                                  : Icons.newspaper,
                              size: 20,
                              color: pub.type == PublicationType.magazine
                                  ? Colors.purple.shade700
                                  : Colors.blue.shade800,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pub.displayName(s),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${pub.type == PublicationType.magazine ? s.magazineLabel : s.newspaperLabel} • ₹${pub.weekdayPrice.toStringAsFixed(0)} / ₹${pub.weekendPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedSubs[pub.id] = SubscriptionItem(
                                publicationId: pub.id,
                                frequency: pub.defaultFrequency,
                                quantity: 1,
                              );
                            } else {
                              _selectedSubs.remove(pub.id);
                            }
                          });
                        },
                      ),
                      if (isSelected && sub != null) ...[
                        const Divider(height: 12),
                        Row(
                          children: [
                            // Variant Dropdown (Daily / Weekdays / Weekends / Sunday / Saturday)
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<DeliveryFrequency>(
                                initialValue: sub.frequency,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: s.variantLabel,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                                items: DeliveryFrequency.values.map((freq) {
                                  return DropdownMenuItem(
                                    value: freq,
                                    child: Text(
                                      freq.label(s),
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newFreq) {
                                  if (newFreq != null) {
                                    setState(() {
                                      _selectedSubs[pub.id] =
                                          sub.copyWith(frequency: newFreq);
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Quantity Stepper
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: sub.quantity > 1
                                        ? () {
                                            setState(() {
                                              _selectedSubs[pub.id] =
                                                  sub.copyWith(
                                                quantity: sub.quantity - 1,
                                              );
                                            });
                                          }
                                        : null,
                                  ),
                                  Text(
                                    '${sub.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      setState(() {
                                        _selectedSubs[pub.id] = sub.copyWith(
                                          quantity: sub.quantity + 1,
                                        );
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  s.saveCustomer,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: canEditCurrent ? _save : null,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
