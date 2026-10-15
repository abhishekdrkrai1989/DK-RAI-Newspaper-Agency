import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../providers/delivery_provider.dart';
import 'delivery_boys_screen.dart';

class ManageBlocksScreen extends StatefulWidget {
  final DeliveryProvider provider;

  const ManageBlocksScreen({super.key, required this.provider});

  @override
  State<ManageBlocksScreen> createState() => _ManageBlocksScreenState();
}

class _ManageBlocksScreenState extends State<ManageBlocksScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAddBlockDialog() {
    final s = widget.provider.strings;
    final deliveryBoys = widget.provider.deliveryBoys;

    if (deliveryBoys.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.deliveryBoyRequiredTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            s.createDeliveryBoyFirstPrompt,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.tr('Cancel', 'रद्द करें')),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.person_add, size: 18),
              label: Text(s.tr('Add Delivery Boy', 'हॉकर जोड़ें')),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeliveryBoysScreen(provider: widget.provider),
                  ),
                );
              },
            ),
          ],
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    String? selectedBoyId = deliveryBoys.first.id;
    String? nameError;
    String? boyError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.domain_add,
                    color: Color(0xFF1E3A8A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.addNewBlockBtn,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        s.blockNameLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: s.blockNameHint,
                      errorText: nameError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.apartment),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) {
                      if (nameError != null) {
                        setDlgState(() => nameError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        s.assignDeliveryBoyLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedBoyId,
                    decoration: InputDecoration(
                      errorText: boyError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.delivery_dining),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: deliveryBoys.map(
                      (boy) => DropdownMenuItem<String>(
                        value: boy.id,
                        child: Text(
                          boy.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ).toList(),
                    onChanged: (val) {
                      setDlgState(() {
                        selectedBoyId = val;
                        boyError = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.tr('Cancel', 'रद्द करें')),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: Text(s.tr('Save Block', 'ब्लॉक सहेजें')),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  bool hasError = false;

                  if (name.isEmpty) {
                    setDlgState(() {
                      nameError = s.blockNameRequired;
                    });
                    hasError = true;
                  }

                  if (selectedBoyId == null || selectedBoyId!.isEmpty) {
                    setDlgState(() {
                      boyError = s.selectDeliveryBoyMandatory;
                    });
                    hasError = true;
                  }

                  if (hasError) return;

                  Navigator.pop(ctx);
                  await widget.provider.addCustomBlock(
                    name,
                    assignToBoyId: selectedBoyId,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF059669),
                        content: Text(s.blockSavedSuccess),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _openAssignHawkerSheet(String block, AppUser? currentBoy) {
    final s = widget.provider.strings;
    final deliveryBoys = widget.provider.deliveryBoys;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_ind,
                      color: Color(0xFF1E3A8A),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.tr('Assign Hawker to', 'हॉकर आवंटित करें:'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          block,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20),
              // Option 1: Unassigned
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_off, color: Colors.grey),
                ),
                title: Text(
                  s.unassignedOption,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  s.tr('No hawker assigned to this block', 'इस ब्लॉक में कोई हॉकर नहीं'),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: currentBoy == null
                    ? const Icon(Icons.check_circle, color: Color(0xFF059669))
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await widget.provider.unassignBlock(block);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF059669),
                        content: Text(s.blockAssignmentUpdated),
                      ),
                    );
                  }
                },
              ),
              const Divider(height: 12),
              // Option 2: Each Delivery Boy
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: deliveryBoys.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (context, index) {
                    final boy = deliveryBoys[index];
                    final isAssigned = currentBoy?.id == boy.id;
                    final otherBlocks = boy.assignedBlocks
                        .where((b) => b.toLowerCase() != block.toLowerCase())
                        .toList();

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isAssigned
                              ? const Color(0xFF059669).withOpacity(0.15)
                              : const Color(0xFF1E3A8A).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delivery_dining,
                          color: isAssigned
                              ? const Color(0xFF059669)
                              : const Color(0xFF1E3A8A),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              boy.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (boy.phone.isNotEmpty)
                            Text(
                              boy.phone,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                      subtitle: otherBlocks.isNotEmpty
                          ? Text(
                              '${s.tr("Other Blocks", "अन्य ब्लॉक")}: ${otherBlocks.join(", ")}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.indigo.shade700,
                              ),
                            )
                          : Text(
                              s.tr('No other blocks', 'कोई अन्य ब्लॉक नहीं'),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                      trailing: isAssigned
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF059669),
                            )
                          : const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await widget.provider.assignBlockToDeliveryBoy(
                          block,
                          boy.id,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF059669),
                              content: Text(
                                s.isHindi
                                    ? '"$block" अब "${boy.name}" को आवंटित है'
                                    : '"$block" is now assigned to "${boy.name}"',
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final p = widget.provider;
        final s = p.strings;
        final allBlocks = p.allManagedBlocks;
        final adminCustomers = p.adminAllCustomers;

        int assignedCount = 0;
        int totalCopies = 0;

        for (final blk in allBlocks) {
          final boy = p.getDeliveryBoyForBlock(blk);
          if (boy != null) assignedCount++;
        }

        final unassignedCount = allBlocks.length - assignedCount;

        for (final c in adminCustomers) {
          if (c.isStartedOnDate(p.selectedDate)) {
            totalCopies += c.totalCopiesOnDate(p.selectedDate);
          }
        }

        final filteredBlocks = allBlocks.where((blk) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          if (blk.toLowerCase().contains(q)) return true;
          final boy = p.getDeliveryBoyForBlock(blk);
          if (boy != null && boy.name.toLowerCase().contains(q)) return true;
          return false;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            title: Text(
              s.manageBlocksTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              IconButton(
                tooltip: s.addNewBlockBtn,
                icon: const Icon(Icons.add_box),
                onPressed: _openAddBlockDialog,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.translate, size: 14),
                  label: Text(
                    s.languageToggleLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: p.toggleLanguage,
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(s.addNewBlockBtn),
            onPressed: _openAddBlockDialog,
          ),
          body: Column(
            children: [
              // Metric Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _BlockMetricTile(
                          label: s.totalBlocksCount,
                          value: '${allBlocks.length}',
                          icon: Icons.domain,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        _BlockMetricTile(
                          label: s.assignedBlocksCount,
                          value: '$assignedCount',
                          icon: Icons.assignment_turned_in,
                          color: const Color(0xFF34D399),
                        ),
                        const SizedBox(width: 8),
                        _BlockMetricTile(
                          label: s.unassignedBlocksCount,
                          value: '$unassignedCount',
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFFBBF24),
                        ),
                        const SizedBox(width: 8),
                        _BlockMetricTile(
                          label: s.tr('Total Copies', 'कुल प्रतियां'),
                          value: '$totalCopies',
                          icon: Icons.newspaper,
                          color: const Color(0xFF60A5FA),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: s.tr(
                      'Search block name or hawker...',
                      'ब्लॉक या हॉकर का नाम खोजें...',
                    ),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                ),
              ),

              // Block List
              Expanded(
                child: filteredBlocks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.apartment_outlined,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.tr(
                                'No blocks match your search',
                                'कोई ब्लॉक नहीं मिला',
                              ),
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.add),
                              label: Text(s.addNewBlockBtn),
                              onPressed: _openAddBlockDialog,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 84),
                        itemCount: filteredBlocks.length,
                        itemBuilder: (context, index) {
                          final blk = filteredBlocks[index];
                          final assignedBoy = p.getDeliveryBoyForBlock(blk);
                          final blockCusts = adminCustomers
                              .where(
                                (c) =>
                                    c.block.trim().toLowerCase() ==
                                    blk.toLowerCase(),
                              )
                              .toList();
                          final housesCount = blockCusts.length;
                          int blockCopies = 0;
                          final societiesSet = <String>{};

                          for (final c in blockCusts) {
                            if (c.area.trim().isNotEmpty) {
                              societiesSet.add(c.area.trim());
                            }
                            if (c.isStartedOnDate(p.selectedDate)) {
                              blockCopies +=
                                  c.totalCopiesOnDate(p.selectedDate);
                            }
                          }

                          final isCustom = p.customBlocks.any(
                            (b) => b.toLowerCase() == blk.toLowerCase(),
                          );
                          final canDelete = isCustom && housesCount == 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: assignedBoy != null
                                    ? Colors.green.shade200
                                    : Colors.amber.shade300,
                                width: 1.2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row: Block Title, Societies, Delete if empty
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.domain,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              blk,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (societiesSet.isNotEmpty)
                                              Text(
                                                societiesSet.join(', '),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blueGrey.shade800,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            Row(
                                              children: [
                                                Text(
                                                  '$housesCount ${s.tr("Houses", "घर")}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                                const Text(' • '),
                                                Text(
                                                  '$blockCopies ${s.tr("Copies/day", "प्रतियां/दिन")}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF059669),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (canDelete)
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            await p.removeCustomBlock(blk);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    s.tr(
                                                      'Block removed',
                                                      'ब्लॉक हटा दिया गया',
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  // Hawker Assignment Status Row
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: assignedBoy != null
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: assignedBoy != null
                                          ? const Color(0xFFA7F3D0)
                                          : const Color(0xFFFDE68A),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          assignedBoy != null
                                              ? Icons.delivery_dining
                                              : Icons.warning_amber_rounded,
                                          size: 20,
                                          color: assignedBoy != null
                                              ? const Color(0xFF059669)
                                              : const Color(0xFFD97706),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                assignedBoy != null
                                                    ? assignedBoy.name
                                                    : s.unassignedOption,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: assignedBoy != null
                                                      ? const Color(0xFF065F46)
                                                      : const Color(0xFF92400E),
                                                ),
                                              ),
                                              if (assignedBoy != null &&
                                                  assignedBoy.phone.isNotEmpty)
                                                Text(
                                                  '📞 ${assignedBoy.phone}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: assignedBoy != null
                                                ? const Color(0xFF059669)
                                                : const Color(0xFF1E3A8A),
                                            foregroundColor: Colors.white,
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          icon: Icon(
                                            assignedBoy != null
                                                ? Icons.swap_horiz
                                                : Icons.person_add_alt_1,
                                            size: 14,
                                          ),
                                          label: Text(
                                            assignedBoy != null
                                                ? s.tr('Change', 'बदलें')
                                                : s.tr('Assign', 'हॉकर चुनें'),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          onPressed: () => _openAssignHawkerSheet(
                                            blk,
                                            assignedBoy,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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

class _BlockMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _BlockMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
