import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_user.dart';
import '../models/customer.dart';
import '../models/newspaper_event.dart';
import '../models/publication.dart';
import '../providers/delivery_provider.dart';

class NewspaperReportScreen extends StatefulWidget {
  final DeliveryProvider provider;

  const NewspaperReportScreen({super.key, required this.provider});

  @override
  State<NewspaperReportScreen> createState() => _NewspaperReportScreenState();
}

class _NewspaperReportScreenState extends State<NewspaperReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _selectedDeliveryBoyId;
  String? _selectedArea;
  String? _selectedBlock;
  NewspaperEventType? _selectedEventFilter;
  final TextEditingController _eventSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _eventSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final p = widget.provider;
        final s = p.strings;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6FB),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F3B66),
            foregroundColor: Colors.white,
            elevation: 2,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.tr('Newspaper Distribution & Logs', 'अखबार वितरण एवं रिपोर्ट'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  s.tr(
                    'Delivery Boy & Area Wise (Start / Pause / Delete)',
                    'हॉकर एवं क्षेत्र अनुसार (चालू / बंद / नए / हटाए गए)',
                  ),
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: s.tr('Sync to Cloud DB', 'क्लाउड में सिंक करें'),
                icon: p.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_sync_outlined),
                onPressed: p.isSyncing
                    ? null
                    : () async {
                        final res = await p.syncWithCloud(forceUpload: true);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.message),
                            backgroundColor:
                                res.success ? Colors.green.shade700 : Colors.red,
                          ),
                        );
                      },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFFFA000),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: [
                Tab(
                  icon: const Icon(Icons.two_wheeler, size: 20),
                  text: s.tr('Hawker Wise', 'हॉकर अनुसार'),
                ),
                Tab(
                  icon: const Icon(Icons.location_city, size: 20),
                  text: s.tr('Area Wise', 'क्षेत्र अनुसार'),
                ),
                Tab(
                  icon: const Icon(Icons.history, size: 20),
                  text: s.tr('Activity Logs', 'गतिविधि लॉग'),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildDeliveryBoyTab(p),
              _buildAreaTab(p),
              _buildActivityLogsTab(p),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 1: DELIVERY BOY WISE
  // ==========================================

  Widget _buildDeliveryBoyTab(DeliveryProvider p) {
    final s = p.strings;
    final boys = p.allUsers.where((u) => u.isDeliveryBoy).toList();
    final breakdown = p.getDeliveryBoyBreakdown(_selectedDeliveryBoyId);

    final totalCusts = breakdown['totalCustomers'] as int;
    final activeCopies = breakdown['activeCopies'] as int;
    final pausedCopies = breakdown['pausedCopies'] as int;
    final pubCopies = breakdown['pubCopies'] as Map<String, int>;
    final newStartCount = breakdown['newStartCount'] as int;
    final startedCount = breakdown['startedCount'] as int;
    final pausedCount = breakdown['pausedCount'] as int;
    final deletedCount = breakdown['deletedCount'] as int;

    AppUser? currentBoy;
    if (_selectedDeliveryBoyId != null) {
      currentBoy = boys.firstWhere(
        (b) => b.id == _selectedDeliveryBoyId,
        orElse: () => const AppUser(
          id: '',
          name: '',
          role: UserRole.deliveryBoy,
          pin: '',
        ),
      );
    }

    final matchedCustomers = _selectedDeliveryBoyId == null
        ? p.allCustomers
        : p.getCustomersForDeliveryBoy(_selectedDeliveryBoyId!);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Hawker Selector Card
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_pin_circle, color: Color(0xFF0F3B66)),
                    const SizedBox(width: 8),
                    Text(
                      s.tr('Select Delivery Boy / Hawker', 'डिलीवरी बॉय / हॉकर चुनें'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  value: _selectedDeliveryBoyId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(s.tr('All Hawkers (Overall Agency)', 'सभी हॉकर (पूरी एजेंसी)')),
                    ),
                    ...boys.map((boy) {
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
                if (currentBoy != null && currentBoy.id.isNotEmpty) ...[
                  const Divider(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      if (currentBoy.phone.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone, size: 14, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(currentBoy.phone, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      if (currentBoy.assignedArea.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(currentBoy.assignedArea, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      if (currentBoy.vehicleNumber.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.two_wheeler, size: 14, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(currentBoy.vehicleNumber, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 4 KPI Status Cards: New Start, Started, Paused, Deleted
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: s.tr('New Start', 'नए चालू'),
                subtitle: s.tr('Recently Added', 'हाल ही में जुड़े'),
                count: newStartCount,
                color: const Color(0xFF2E7D32),
                icon: Icons.fiber_new,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: s.tr('Started', 'चालू'),
                subtitle: s.tr('Active Copies', 'सक्रिय प्रतियां'),
                count: activeCopies,
                color: const Color(0xFF1976D2),
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: s.tr('Paused', 'बंद (पॉज)'),
                subtitle: s.tr('Paused Copies', 'रुकी प्रतियां'),
                count: pausedCopies,
                color: const Color(0xFFE65100),
                icon: Icons.pause_circle_outline,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: s.tr('Deleted', 'हटाए गए'),
                subtitle: s.tr('Cancelled Subscriptions', 'रद्द अखबार'),
                count: deletedCount,
                color: const Color(0xFFC62828),
                icon: Icons.delete_outline,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Newspaper-wise Breakdown Table
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.tr('Newspaper-wise Copy Count', 'अखबार अनुसार प्रतियों की संख्या'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F3B66),
                      ),
                    ),
                    Text(
                      '${s.tr("Total Active", "कुल चालू")}: $activeCopies',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (pubCopies.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        s.tr('No active newspapers found for this hawker', 'इस हॉकर के लिए कोई सक्रिय अखबार नहीं मिले'),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...pubCopies.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.newspaper, size: 16, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF90CAF9)),
                            ),
                            child: Text(
                              '${entry.value} ${s.tr("copies", "प्रतियां")}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF1565C0),
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

        // Customer List Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${s.tr("Assigned Houses / Customers", "सौंपे गए मकान / ग्राहक")} (${matchedCustomers.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF0F3B66),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (matchedCustomers.isEmpty)
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  s.tr('No customers assigned to this delivery boy.', 'इस डिलीवरी बॉय को कोई ग्राहक नहीं सौंपा गया है।'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )
        else
          ...matchedCustomers.map((c) {
            final isStarted = c.isStartedOnDate(p.selectedDate);
            final subsText = c.subscriptions
                .map((sub) {
                  final pub = p.getPublicationById(sub.publicationId);
                  return '${pub?.nameEn ?? sub.publicationId} (×${sub.quantity})';
                })
                .join(', ');

            return Card(
              elevation: 0.8,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isStarted ? Colors.green.shade200 : Colors.orange.shade200,
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isStarted ? Colors.green.shade100 : Colors.orange.shade100,
                  child: Text(
                    c.sequenceNo.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isStarted ? Colors.green.shade900 : Colors.orange.shade900,
                    ),
                  ),
                ),
                title: Text(
                  '${c.houseNumber} - ${c.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.block.isNotEmpty ? "${c.block}, " : ""}${c.area}',
                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subsText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isStarted ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isStarted ? Colors.green.shade400 : Colors.orange.shade400,
                    ),
                  ),
                  child: Text(
                    isStarted ? s.tr('Started', 'चालू') : s.tr('Paused', 'बंद'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isStarted ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  // ==========================================
  // TAB 2: AREA WISE
  // ==========================================

  Widget _buildAreaTab(DeliveryProvider p) {
    final s = p.strings;
    final societies = p.availableAreas;
    final blocks = p.availableBlocks;
    final breakdown = p.getAreaBreakdown(_selectedArea, _selectedBlock);

    final totalCusts = breakdown['totalCustomers'] as int;
    final activeCopies = breakdown['activeCopies'] as int;
    final pausedCopies = breakdown['pausedCopies'] as int;
    final pubCopies = breakdown['pubCopies'] as Map<String, int>;
    final newStartCount = breakdown['newStartCount'] as int;
    final startedCount = breakdown['startedCount'] as int;
    final pausedCount = breakdown['pausedCount'] as int;
    final deletedCount = breakdown['deletedCount'] as int;

    final matchedCustomers = p.allCustomers.where((c) {
      if (_selectedArea != null &&
          _selectedArea!.isNotEmpty &&
          c.area.toLowerCase() != _selectedArea!.toLowerCase()) {
        return false;
      }
      if (_selectedBlock != null &&
          _selectedBlock!.isNotEmpty &&
          c.block.toLowerCase() != _selectedBlock!.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Area / Society Selector Card
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_city, color: Color(0xFF0F3B66)),
                    const SizedBox(width: 8),
                    Text(
                      s.tr('Select Area / Society / Colony', 'क्षेत्र / सोसाइटी / कॉलोनी चुनें'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  value: _selectedArea,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(s.tr('All Areas & Societies', 'सभी क्षेत्र एवं सोसायटियां')),
                    ),
                    ...societies.map((soc) {
                      return DropdownMenuItem<String?>(
                        value: soc,
                        child: Text(soc),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedArea = val;
                      _selectedBlock = null;
                    });
                  },
                ),

                // Block / Tower sub-filter chips
                if (_selectedArea != null && blocks.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    s.tr('Block / Tower (Optional Filter):', 'ब्लॉक / टॉवर (वैकल्पिक):'),
                    style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      FilterChip(
                        label: Text(s.tr('All Blocks', 'सभी ब्लॉक')),
                        selected: _selectedBlock == null,
                        onSelected: (val) {
                          setState(() {
                            _selectedBlock = null;
                          });
                        },
                      ),
                      ...blocks.map((b) {
                        return FilterChip(
                          label: Text(b),
                          selected: _selectedBlock == b,
                          onSelected: (val) {
                            setState(() {
                              _selectedBlock = val ? b : null;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 4 KPI Status Cards: New Start, Started, Paused, Deleted
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: s.tr('New Start', 'नए चालू'),
                subtitle: s.tr('Recently Added', 'हाल ही में जुड़े'),
                count: newStartCount,
                color: const Color(0xFF2E7D32),
                icon: Icons.fiber_new,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: s.tr('Started', 'चालू'),
                subtitle: s.tr('Active Copies', 'सक्रिय प्रतियां'),
                count: activeCopies,
                color: const Color(0xFF1976D2),
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: s.tr('Paused', 'बंद (पॉज)'),
                subtitle: s.tr('Paused Copies', 'रुकी प्रतियां'),
                count: pausedCopies,
                color: const Color(0xFFE65100),
                icon: Icons.pause_circle_outline,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: s.tr('Deleted', 'हटाए गए'),
                subtitle: s.tr('Cancelled Subscriptions', 'रद्द अखबार'),
                count: deletedCount,
                color: const Color(0xFFC62828),
                icon: Icons.delete_outline,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Newspaper-wise Breakdown Table for Area
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.tr('Area Copies by Publication', 'क्षेत्र अनुसार अखबार प्रतियों का विवरण'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F3B66),
                      ),
                    ),
                    Text(
                      '${s.tr("Active", "चालू")}: $activeCopies',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (pubCopies.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        s.tr('No newspapers active in this area', 'इस क्षेत्र में कोई अखबार सक्रिय नहीं है'),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...pubCopies.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.newspaper, size: 16, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFA5D6A7)),
                            ),
                            child: Text(
                              '${entry.value} ${s.tr("copies", "प्रतियां")}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF2E7D32),
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

        // Houses in this Area Header
        Text(
          '${s.tr("Houses in this Area", "इस क्षेत्र के मकान")} (${matchedCustomers.length})',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF0F3B66),
          ),
        ),
        const SizedBox(height: 8),

        if (matchedCustomers.isEmpty)
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  s.tr('No customers found in this area.', 'इस क्षेत्र में कोई ग्राहक नहीं मिले।'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )
        else
          ...matchedCustomers.map((c) {
            final isStarted = c.isStartedOnDate(p.selectedDate);
            final subsText = c.subscriptions
                .map((sub) {
                  final pub = p.getPublicationById(sub.publicationId);
                  return '${pub?.nameEn ?? sub.publicationId} (×${sub.quantity})';
                })
                .join(', ');
            final boyName = p.getAssignedDeliveryBoyNameForCustomer(c);

            return Card(
              elevation: 0.8,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isStarted ? Colors.green.shade200 : Colors.orange.shade200,
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isStarted ? Colors.green.shade100 : Colors.orange.shade100,
                  child: Text(
                    c.sequenceNo.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isStarted ? Colors.green.shade900 : Colors.orange.shade900,
                    ),
                  ),
                ),
                title: Text(
                  '${c.houseNumber} - ${c.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.tr("Hawker", "हॉकर")}: $boyName',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0F3B66),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subsText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isStarted ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isStarted ? Colors.green.shade400 : Colors.orange.shade400,
                    ),
                  ),
                  child: Text(
                    isStarted ? s.tr('Started', 'चालू') : s.tr('Paused', 'बंद'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isStarted ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  // ==========================================
  // TAB 3: ACTIVITY & CLOUD LOGS
  // ==========================================

  Widget _buildActivityLogsTab(DeliveryProvider p) {
    final s = p.strings;
    final allEvents = p.newspaperEvents;
    final query = _eventSearchCtrl.text.trim().toLowerCase();

    final filteredEvents = allEvents.where((e) {
      if (_selectedEventFilter != null && e.eventType != _selectedEventFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchCustomer = e.customerName.toLowerCase().contains(query);
        final matchHouse = e.houseNumber.toLowerCase().contains(query);
        final matchPaper = e.newspaperName.toLowerCase().contains(query);
        final matchBoy = e.deliveryBoyName.toLowerCase().contains(query);
        final matchArea = e.area.toLowerCase().contains(query);
        if (!matchCustomer &&
            !matchHouse &&
            !matchPaper &&
            !matchBoy &&
            !matchArea) {
          return false;
        }
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Filter bar & Search box
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: [
              TextField(
                controller: _eventSearchCtrl,
                decoration: InputDecoration(
                  hintText: s.tr(
                    'Search customer, house, paper, or hawker...',
                    'ग्राहक, मकान, अखबार या हॉकर खोजें...',
                  ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _eventSearchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _eventSearchCtrl.clear();
                            });
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(s.tr('All Events', 'सभी गतिविधियां')),
                      selected: _selectedEventFilter == null,
                      onSelected: (val) {
                        setState(() {
                          _selectedEventFilter = null;
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: Text(s.tr('New Start', 'नए चालू')),
                      avatar: const Icon(Icons.fiber_new, size: 16, color: Colors.green),
                      selected: _selectedEventFilter == NewspaperEventType.newStart,
                      onSelected: (val) {
                        setState(() {
                          _selectedEventFilter =
                              val ? NewspaperEventType.newStart : null;
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: Text(s.tr('Started', 'चालू')),
                      avatar: const Icon(Icons.play_arrow, size: 16, color: Colors.blue),
                      selected: _selectedEventFilter == NewspaperEventType.started,
                      onSelected: (val) {
                        setState(() {
                          _selectedEventFilter =
                              val ? NewspaperEventType.started : null;
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: Text(s.tr('Paused', 'बंद (पॉज)')),
                      avatar: const Icon(Icons.pause, size: 16, color: Colors.orange),
                      selected: _selectedEventFilter == NewspaperEventType.paused,
                      onSelected: (val) {
                        setState(() {
                          _selectedEventFilter =
                              val ? NewspaperEventType.paused : null;
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: Text(s.tr('Deleted', 'हटाए गए')),
                      avatar: const Icon(Icons.delete, size: 16, color: Colors.red),
                      selected: _selectedEventFilter == NewspaperEventType.deleted,
                      onSelected: (val) {
                        setState(() {
                          _selectedEventFilter =
                              val ? NewspaperEventType.deleted : null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Events Count info bar
        Container(
          color: const Color(0xFFECEFF1),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${s.tr("Showing", "दिखाए जा रहे")}: ${filteredEvents.length} / ${allEvents.length}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.cloud_done, size: 14, color: Colors.teal),
                  const SizedBox(width: 4),
                  Text(
                    s.tr('Auto-saved to Cloud DB', 'क्लाउड DB में सुरक्षित'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Event cards stream
        Expanded(
          child: filteredEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_note, size: 54, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        s.tr('No activity events match your filter', 'आपके फ़िल्टर से मेल खाती कोई गतिविधि नहीं मिली'),
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, idx) {
                    final e = filteredEvents[idx];
                    return _buildEventItemCard(e, s);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEventItemCard(NewspaperEvent e, dynamic s) {
    Color badgeColor;
    Color badgeBg;
    IconData eventIcon;
    String typeLabel = e.eventTypeLabel(s);

    switch (e.eventType) {
      case NewspaperEventType.newStart:
        badgeColor = const Color(0xFF2E7D32);
        badgeBg = const Color(0xFFE8F5E9);
        eventIcon = Icons.fiber_new;
        break;
      case NewspaperEventType.started:
        badgeColor = const Color(0xFF1976D2);
        badgeBg = const Color(0xFFE3F2FD);
        eventIcon = Icons.play_arrow;
        break;
      case NewspaperEventType.paused:
        badgeColor = const Color(0xFFE65100);
        badgeBg = const Color(0xFFFFF3E0);
        eventIcon = Icons.pause;
        break;
      case NewspaperEventType.deleted:
        badgeColor = const Color(0xFFC62828);
        badgeBg = const Color(0xFFFFEBEE);
        eventIcon = Icons.delete_outline;
        break;
    }

    final formattedDate =
        '${e.timestamp.day.toString().padLeft(2, '0')}/${e.timestamp.month.toString().padLeft(2, '0')}/${e.timestamp.year} ${e.timestamp.hour.toString().padLeft(2, '0')}:${e.timestamp.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 0.8,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: badgeColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Event badge + Timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(eventIcon, size: 14, color: badgeColor),
                      const SizedBox(width: 4),
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Customer Name & House
            Text(
              '${e.customerName} (${e.houseNumber.isNotEmpty ? "${e.houseNumber}, " : ""}${e.block.isNotEmpty ? "${e.block}, " : ""}${e.area})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF0F3B66),
              ),
            ),
            const SizedBox(height: 4),

            // Newspaper & Hawker
            Row(
              children: [
                const Icon(Icons.newspaper, size: 14, color: Colors.blueGrey),
                const SizedBox(width: 4),
                Text(
                  '${e.newspaperName} (×${e.quantity})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.two_wheeler, size: 14, color: Colors.blueGrey),
                const SizedBox(width: 4),
                Text(
                  e.deliveryBoyName.isNotEmpty
                      ? e.deliveryBoyName
                      : 'Unassigned Hawker',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),

            if (e.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Note: ${e.note}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Metric Card Builder
  Widget _buildMetricCard({
    required String title,
    required String subtitle,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          gradient: LinearGradient(
            colors: [Colors.white, color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                Icon(icon, size: 20, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
