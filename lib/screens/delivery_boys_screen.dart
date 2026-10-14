import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_user.dart';
import '../providers/delivery_provider.dart';

class DeliveryBoysScreen extends StatefulWidget {
  final DeliveryProvider provider;

  const DeliveryBoysScreen({super.key, required this.provider});

  @override
  State<DeliveryBoysScreen> createState() => _DeliveryBoysScreenState();
}

class _DeliveryBoysScreenState extends State<DeliveryBoysScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _revealedPins = <String>{};
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openDeliveryBoyForm([AppUser? existingBoy]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DeliveryBoyFormSheet(
        provider: widget.provider,
        deliveryBoy: existingBoy,
      ),
    );
  }

  Future<void> _confirmDelete(AppUser boy) async {
    final s = widget.provider.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Text(s.tr('Delete Delivery Boy?', 'डिलीवरी बॉय हटाएं?')),
          ],
        ),
        content: Text(
          s.isHindi
              ? 'क्या आप वाकई "${boy.name}" को हटाना चाहते हैं? यह हॉकर फिर ऐप में लॉगिन नहीं कर पाएगा।'
              : 'Are you sure you want to remove "${boy.name}"? They will no longer be able to log in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.tr('Cancel', 'रद्द करें')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.tr('Delete', 'हटाएं')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await widget.provider.deleteDeliveryBoy(boy.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor:
                success ? const Color(0xFF059669) : const Color(0xFFDC2626),
            content: Text(
              success ? s.deliveryBoyDeletedSuccess : s.cannotDeleteOwner,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final p = widget.provider;
        final s = p.strings;
        final deliveryBoys = p.deliveryBoys;
        final activeCount = deliveryBoys.where((b) => b.isActive).length;
        final inactiveCount = deliveryBoys.length - activeCount;

        final filteredBoys = deliveryBoys.where((b) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return b.name.toLowerCase().contains(q) ||
              b.phone.toLowerCase().contains(q) ||
              b.assignedArea.toLowerCase().contains(q) ||
              b.vehicleNumber.toLowerCase().contains(q);
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            title: Text(
              s.manageDeliveryBoysTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                tooltip: s.addDeliveryBoy,
                icon: const Icon(Icons.person_add_alt_1),
                onPressed: () => _openDeliveryBoyForm(),
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
            label: Text(s.addDeliveryBoy),
            onPressed: () => _openDeliveryBoyForm(),
          ),
          body: Column(
            children: [
              // Top Metric Banner
              Container(
                color: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    _MetricCard(
                      label: s.totalDeliveryBoys,
                      count: deliveryBoys.length.toString(),
                      icon: Icons.two_wheeler,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    const SizedBox(width: 8),
                    _MetricCard(
                      label: s.activeHawkers,
                      count: activeCount.toString(),
                      icon: Icons.check_circle_outline,
                      color: Colors.greenAccent.withValues(alpha: 0.22),
                      textColor: Colors.greenAccent,
                    ),
                    const SizedBox(width: 8),
                    _MetricCard(
                      label: s.inactiveHawkers,
                      count: inactiveCount.toString(),
                      icon: Icons.block,
                      color: Colors.amberAccent.withValues(alpha: 0.2),
                      textColor: Colors.amberAccent,
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: s.tr(
                      'Search by name, phone, area, or vehicle...',
                      'नाम, मोबाइल, क्षेत्र या वाहन से खोजें...',
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
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),

              // Delivery Boys List
              Expanded(
                child: filteredBoys.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.two_wheeler,
                                  size: 42,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                s.noDeliveryBoysFound,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.add),
                                label: Text(s.addDeliveryBoy),
                                onPressed: () => _openDeliveryBoyForm(),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: filteredBoys.length,
                        itemBuilder: (context, index) {
                          final boy = filteredBoys[index];
                          final isPinRevealed = _revealedPins.contains(boy.id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: boy.isActive
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFFFCA5A5),
                                width: 1.2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row: Avatar, Name & Phone, Active Switch
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: boy.isActive
                                            ? const Color(0xFF059669)
                                                .withValues(alpha: 0.12)
                                            : Colors.grey.shade200,
                                        child: Icon(
                                          Icons.two_wheeler,
                                          color: boy.isActive
                                              ? const Color(0xFF059669)
                                              : Colors.grey.shade600,
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    boy.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: boy.isActive
                                                        ? const Color(0xFFECFDF5)
                                                        : const Color(0xFFFEF2F2),
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: boy.isActive
                                                          ? const Color(
                                                              0xFF6EE7B7)
                                                          : const Color(
                                                              0xFFFCA5A5),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    boy.isActive
                                                        ? s.statusActive
                                                        : s.statusInactive,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: boy.isActive
                                                          ? const Color(
                                                              0xFF065F46)
                                                          : const Color(
                                                              0xFF991B1B),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            if (boy.phone.isNotEmpty)
                                              InkWell(
                                                onTap: () {
                                                  Clipboard.setData(
                                                    ClipboardData(
                                                        text: boy.phone),
                                                  );
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        s.tr(
                                                          'Phone number copied: ${boy.phone}',
                                                          'मोबाइल नंबर कॉपी किया गया: ${boy.phone}',
                                                        ),
                                                      ),
                                                      duration: const Duration(
                                                          seconds: 2),
                                                    ),
                                                  );
                                                },
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.phone,
                                                      size: 13,
                                                      color: Color(0xFF2563EB),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      boy.phone,
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF2563EB),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      Icons.copy,
                                                      size: 11,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Active/Inactive Quick Switch
                                      Column(
                                        children: [
                                          Switch(
                                            value: boy.isActive,
                                            activeColor:
                                                const Color(0xFF059669),
                                            onChanged: (val) {
                                              p.toggleDeliveryBoyActive(boy.id);
                                            },
                                          ),
                                          Text(
                                            boy.isActive
                                                ? s.statusActive
                                                : s.statusInactive,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: boy.isActive
                                                  ? const Color(0xFF059669)
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),
                                  const Divider(height: 1),
                                  const SizedBox(height: 10),

                                  // Details Badges Row: PIN, Assigned Area, Vehicle
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      // PIN Badge with Eye toggle
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (isPinRevealed) {
                                              _revealedPins.remove(boy.id);
                                            } else {
                                              _revealedPins.add(boy.id);
                                            }
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF2FF),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: const Color(0xFFC7D2FE),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.lock_outline,
                                                size: 13,
                                                color: Color(0xFF4338CA),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'PIN: ${isPinRevealed ? boy.pin : "••••"}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Color(0xFF3730A3),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                isPinRevealed
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                size: 13,
                                                color: const Color(0xFF6366F1),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Assigned Area
                                      if (boy.assignedArea.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0FDF4),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: const Color(0xFFBBF7D0),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.place,
                                                size: 13,
                                                color: Color(0xFF15803D),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                boy.assignedArea,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF166534),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      // Vehicle Number
                                      if (boy.vehicleNumber.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFFBEB),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: const Color(0xFFFDE68A),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.pedal_bike,
                                                size: 13,
                                                color: Color(0xFFB45309),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                boy.vehicleNumber,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF92400E),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),

                                  // Shift / Route Notes if present
                                  if (boy.notes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '📝 ${boy.notes}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 10),

                                  // Action Buttons: Edit & Delete
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xFFCBD5E1),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 14,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                        label: Text(
                                          s.tr('Edit', 'बदलें'),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF1E3A8A),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _openDeliveryBoyForm(boy),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFFDC2626),
                                          side: const BorderSide(
                                            color: Color(0xFFFCA5A5),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 14,
                                        ),
                                        label: Text(
                                          s.tr('Delete', 'हटाएं'),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        onPressed: () => _confirmDelete(boy),
                                      ),
                                    ],
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

class _MetricCard extends StatelessWidget {
  final String label;
  final String count;
  final IconData icon;
  final Color color;
  final Color textColor;

  const _MetricCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: textColor),
                const SizedBox(width: 4),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: textColor.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryBoyFormSheet extends StatefulWidget {
  final DeliveryProvider provider;
  final AppUser? deliveryBoy;

  const _DeliveryBoyFormSheet({
    required this.provider,
    this.deliveryBoy,
  });

  @override
  State<_DeliveryBoyFormSheet> createState() => _DeliveryBoyFormSheetState();
}

class _DeliveryBoyFormSheetState extends State<_DeliveryBoyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _pinCtrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _vehicleCtrl;
  late final TextEditingController _notesCtrl;
  late bool _isActive;
  bool _obscurePin = false;

  @override
  void initState() {
    super.initState();
    final boy = widget.deliveryBoy;
    _nameCtrl = TextEditingController(text: boy?.name ?? '');
    _phoneCtrl = TextEditingController(text: boy?.phone ?? '');
    _pinCtrl = TextEditingController(
      text: boy?.pin ?? _generateRandomPin(),
    );
    _areaCtrl = TextEditingController(text: boy?.assignedArea ?? '');
    _vehicleCtrl = TextEditingController(text: boy?.vehicleNumber ?? '');
    _notesCtrl = TextEditingController(text: boy?.notes ?? '');
    _isActive = boy?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    _areaCtrl.dispose();
    _vehicleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _generateRandomPin() {
    final rnd = Random();
    final code = 1000 + rnd.nextInt(9000);
    return code.toString();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final isNew = widget.deliveryBoy == null;
    final boyId = isNew
        ? 'user_delivery_${DateTime.now().millisecondsSinceEpoch}'
        : widget.deliveryBoy!.id;

    final updatedBoy = AppUser(
      id: boyId,
      name: _nameCtrl.text.trim(),
      role: UserRole.deliveryBoy,
      pin: _pinCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      assignedArea: _areaCtrl.text.trim(),
      isActive: _isActive,
      vehicleNumber: _vehicleCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );

    await widget.provider.saveDeliveryBoy(updatedBoy);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF059669),
          content: Text(widget.provider.strings.deliveryBoySavedSuccess),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.provider.strings;
    final isEdit = widget.deliveryBoy != null;
    final societies = widget.provider.availableAreas;
    final blocks = widget.provider.allUniqueBlocks;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.two_wheeler,
                      color: Color(0xFF1E3A8A),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? s.editDeliveryBoy : s.addDeliveryBoy,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Full Name
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: s.deliveryBoyName,
                  hintText: s.deliveryBoyNameHint,
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return s.isHindi
                        ? 'कृपया हॉकर का नाम दर्ज करें'
                        : 'Please enter delivery boy name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Phone Number & PIN Row
              Row(
                children: [
                  // Phone Number
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: s.deliveryBoyPhone,
                        hintText: s.deliveryBoyPhoneHint,
                        prefixIcon: const Icon(Icons.phone_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return s.isHindi
                              ? 'मोबाइल नंबर दर्ज करें'
                              : 'Enter phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 4-Digit PIN
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _pinCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: _obscurePin,
                      maxLength: 6,
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: s.tr('PIN', 'पिन'),
                        hintText: '4-digits',
                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePin
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 16,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePin = !_obscurePin;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length < 4) {
                          return s.isHindi ? 'कम से कम 4 अंक' : 'Min 4 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // PIN Generator helper button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF1E3A8A),
                  ),
                  icon: const Icon(Icons.shuffle, size: 14),
                  label: Text(
                    s.generatePinBtn,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    setState(() {
                      _pinCtrl.text = _generateRandomPin();
                    });
                  },
                ),
              ),

              // Assigned Area / Route
              TextFormField(
                controller: _areaCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: s.assignedAreaRoute,
                  hintText: s.assignedAreaHint,
                  prefixIcon: const Icon(Icons.place_outlined),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // Quick suggestions chips for Societies / Blocks
              if (societies.isNotEmpty || blocks.isNotEmpty) ...[
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...societies.take(4).map((soc) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              visualDensity: VisualDensity.compact,
                              label: Text(
                                soc,
                                style: const TextStyle(fontSize: 11),
                              ),
                              onPressed: () {
                                if (_areaCtrl.text.isEmpty) {
                                  _areaCtrl.text = soc;
                                } else if (!_areaCtrl.text.contains(soc)) {
                                  _areaCtrl.text = '${_areaCtrl.text}, $soc';
                                }
                              },
                            ),
                          )),
                      ...blocks.take(4).map((blk) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              visualDensity: VisualDensity.compact,
                              label: Text(
                                blk,
                                style: const TextStyle(fontSize: 11),
                              ),
                              onPressed: () {
                                if (_areaCtrl.text.isEmpty) {
                                  _areaCtrl.text = blk;
                                } else if (!_areaCtrl.text.contains(blk)) {
                                  _areaCtrl.text = '${_areaCtrl.text}, $blk';
                                }
                              },
                            ),
                          )),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Vehicle Details (Optional)
              TextFormField(
                controller: _vehicleCtrl,
                decoration: InputDecoration(
                  labelText: s.vehicleNumber,
                  hintText: s.vehicleNumberHint,
                  prefixIcon: const Icon(Icons.pedal_bike),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Notes / Shift timings
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: s.deliveryBoyNotes,
                  hintText: s.deliveryBoyNotesHint,
                  prefixIcon: const Icon(Icons.notes),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Active / Inactive Switch
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isActive ? Icons.check_circle : Icons.block,
                      color: _isActive
                          ? const Color(0xFF059669)
                          : const Color(0xFFDC2626),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.activeStatusToggle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      activeColor: const Color(0xFF059669),
                      onChanged: (val) {
                        setState(() {
                          _isActive = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons: Save & Cancel
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: _handleSave,
                child: Text(
                  isEdit
                      ? s.tr('Save Changes', 'बदलाव सहेजें')
                      : s.addDeliveryBoy,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
