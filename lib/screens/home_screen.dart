import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/approval_request.dart';
import '../models/customer.dart';
import '../models/publication.dart';
import '../providers/delivery_provider.dart';
import '../widgets/edit_admin_pin_dialog.dart';
import '../widgets/pause_paper_dialog.dart';
import 'approvals_screen.dart';
import 'block_wise_consumption_screen.dart';
import 'cloud_sync_screen.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';
import 'delivery_boys_screen.dart';
import 'login_screen.dart';
import 'manage_blocks_screen.dart';
import 'monthly_billing_report_screen.dart';
import 'morning_delivery_list_screen.dart';
import 'newspaper_report_screen.dart';
import 'publications_screen.dart';
import 'yearly_subscriptions_screen.dart';

class HomeScreen extends StatefulWidget {
  final DeliveryProvider provider;

  const HomeScreen({super.key, required this.provider});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final p = widget.provider;
        final s = p.strings;
        final customers = p.filteredCustomers;
        final bundleMap = p.bundleCountByPublication;
        final societies = p.availableAreas;
        final blocks = p.availableBlocks;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6FB),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.appTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: p.isOwner
                                  ? Colors.amber.withOpacity(0.3)
                                  : Colors.greenAccent.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p.isOwner ? '👑 Owner' : '🛵 Delivery Boy',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: p.isOwner
                                    ? Colors.amberAccent
                                    : Colors.greenAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            p.isCloudConfigured
                                ? Icons.cloud_done
                                : Icons.offline_pin,
                            size: 11,
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              p.isCloudConfigured
                                  ? s.cloudStatusConnected
                                  : s.savedLocallyBadge,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // 1. Language Toggle Pill (English <-> Hindi)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.translate, size: 14),
                  label: Text(
                    s.languageToggleLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  onPressed: p.toggleLanguage,
                ),
              ),

              // 2. Approvals Button (Only for Admin/Owner, with live pending badge)
              if (p.isOwner)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: s.approvalsTitle,
                      icon: const Icon(Icons.approval, color: Colors.amberAccent),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ApprovalsScreen(provider: p),
                          ),
                        );
                      },
                    ),
                    if (p.pendingApprovalsCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${p.pendingApprovalsCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),

              // 3. More Menu (Popup menu containing all administrative & reporting screens for Owner)
              if (p.isOwner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  tooltip: s.tr('More Options', 'और विकल्प'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    switch (val) {
                      case 'blocks':
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ManageBlocksScreen(provider: p),
                        ));
                        break;
                      case 'hawkers':
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => DeliveryBoysScreen(provider: p),
                        ));
                        break;
                      case 'approvals':
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ApprovalsScreen(provider: p),
                        ));
                        break;
                      case 'cloud_sync':
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => CloudSyncScreen(provider: p),
                        ));
                        break;
                      case 'hawker_report':
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => NewspaperReportScreen(provider: p),
                        ));
                        break;
                      case 'block_consumption':
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => BlockWiseConsumptionScreen(provider: p),
                        ));
                        break;
                      case 'morning_list':
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => MorningDeliveryListScreen(provider: p),
                        ));
                        break;
                      case 'billing_report':
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => MonthlyBillingReportScreen(provider: p),
                        ));
                        break;
                      case 'publications':
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => PublicationsScreen(provider: p),
                        ));
                        break;
                      case 'yearly_subscriptions':
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => YearlySubscriptionsScreen(provider: p),
                        ));
                        break;
                      case 'switch_user':
                        _showUserSwitchDialog(context, p);
                        break;
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'blocks',
                      child: Row(
                        children: [
                          const Icon(Icons.domain_add, color: Color(0xFF1E3A8A), size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.manageBlocksTitle)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'hawkers',
                      child: Row(
                        children: [
                          const Icon(Icons.two_wheeler, color: Color(0xFF059669), size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.manageDeliveryBoysTitle)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'approvals',
                      child: Row(
                        children: [
                          const Icon(Icons.approval, color: Color(0xFFD97706), size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text('${s.approvalsTitle} (${p.pendingApprovalsCount})')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'cloud_sync',
                      child: Row(
                        children: [
                          Icon(
                            p.isCloudConfigured ? Icons.cloud_done : Icons.cloud_queue,
                            color: p.isCloudConfigured ? Colors.green : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.cloudSyncTooltip)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'hawker_report',
                      child: Row(
                        children: [
                          const Icon(Icons.assessment, color: Colors.indigo, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.tr('Hawker & Area Report', 'हॉकर व क्षेत्र रिपोर्ट'))),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'morning_list',
                      child: Row(
                        children: [
                          const Icon(Icons.list_alt, color: Color(0xFF1E3A8A), size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.generateMorningListBtn)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'billing_report',
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long, color: Colors.teal, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.monthlyBillingBtn)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'block_consumption',
                      child: Row(
                        children: [
                          const Icon(Icons.analytics_outlined, color: Colors.blue, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.blockConsumptionBtn)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'publications',
                      child: Row(
                        children: [
                          const Icon(Icons.newspaper, color: Colors.orange, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.managePublications)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'yearly_subscriptions',
                      child: Row(
                        children: [
                          const Icon(Icons.card_membership, color: Colors.purple, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.tr('Yearly Subscriptions & Schemes', 'वार्षिक सदस्यता व योजनाएं'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'switch_user',
                      child: Row(
                        children: [
                          const Icon(Icons.swap_horiz, color: Color(0xFF3B82F6), size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.tr('Switch User', 'उपयोगकर्ता बदलें'))),
                        ],
                      ),
                    ),
                  ],
                ),

              // 4. Dedicated LOGOUT BUTTON (Always visible at top-right, never hides!)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: s.tr('Logout', 'लॉगआउट'),
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFFCA5A5),
                ),
                onPressed: () => _confirmLogout(context, p),
              ),
              const SizedBox(width: 4),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(s.addCustomer),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CustomerFormScreen(provider: p),
                ),
              );
            },
          ),
          body: Column(
            children: [
              // Delivery Boy Notification Banner
              if (p.isDeliveryBoy)
                Container(
                  width: double.infinity,
                  color: const Color(0xFF065F46),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.two_wheeler, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  p.currentUser?.name ?? 'Delivery Boy',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amberAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    p.currentUser?.assignedBlocks.isNotEmpty == true
                                        ? '${s.assignedBlocksLabel}: ${p.currentUser!.assignedBlocks.join(", ")}'
                                        : s.noAssignedBlocksWarning,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.deliveryBoyBanner,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.amberAccent,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _showUserSwitchDialog(context, p),
                        child: Text(s.logoutBtn, style: const TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),

              // Owner Pending Approvals Alert Banner
              if (p.isOwner && p.pendingApprovalsCount > 0)
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ApprovalsScreen(provider: p),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFFEF3C7),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.pending_actions,
                            color: Color(0xFFD97706), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.isHindi
                                ? 'हॉकर द्वारा ${p.pendingApprovalsCount} बदलाव किए गए हैं जो आपकी मंज़ूरी के लिए बाकी हैं।'
                                : '${p.pendingApprovalsCount} delivery boy actions are waiting for your approval.',
                            style: const TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 12, color: Color(0xFF92400E)),
                      ],
                    ),
                  ),
                ),
              // Top Blue Header with Date Selector & Summary Stats
              Container(
                color: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(
                  children: [
                    // Date Navigation Strip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              p.setSelectedDate(
                                p.selectedDate.subtract(const Duration(days: 1)),
                              );
                            },
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: p.selectedDate,
                                  firstDate: DateTime(2024),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  p.setSelectedDate(picked);
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 15,
                                    color: Colors.amberAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${s.weekdayName(p.selectedDate.weekday)} • ${s.formatDate(p.selectedDate)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
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
                              color: Colors.white,
                            ),
                            onPressed: () {
                              p.setSelectedDate(
                                p.selectedDate.add(const Duration(days: 1)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 4 Summary Metric Boxes
                    Row(
                      children: [
                        _StatCard(
                          label: s.startedPapers,
                          value: '${p.startedCustomersCount}',
                          color: Colors.green.shade600,
                          icon: Icons.play_circle_fill,
                          isSelected: p.filter == DistributionFilter.started,
                          onTap: () => p.setFilter(DistributionFilter.started),
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          label: s.pausedPapers,
                          value: '${p.pausedCustomersCount}',
                          color: Colors.deepOrange,
                          icon: Icons.pause_circle_filled,
                          isSelected: p.filter == DistributionFilter.paused,
                          onTap: () => p.setFilter(DistributionFilter.paused),
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          label: s.todayCopies,
                          value: '${p.totalDeliverableCopiesForDate}',
                          color: Colors.indigo.shade600,
                          icon: Icons.newspaper,
                          isSelected: p.filter == DistributionFilter.all,
                          onTap: () => p.setFilter(DistributionFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          label: s.deliveredToday,
                          value:
                              '${p.deliveredCustomersCountForDate}/${p.startedCustomersCount}',
                          color: Colors.teal.shade600,
                          icon: Icons.task_alt,
                          isSelected:
                              p.filter == DistributionFilter.pendingToday,
                          onTap: () =>
                              p.setFilter(DistributionFilter.pendingToday),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Depot Bundle Count Horizontal Bar (Active Papers for Selected Day & Block/Society)
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 15,
                          color: Color(0xFF1E3A8A),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            p.hasLocationFilter
                                ? '${s.depotPickupTitle} (${[
                                    if (p.selectedArea != null) p.selectedArea,
                                    if (p.selectedBlock != null) p.selectedBlock,
                                  ].join(" • ")})'
                                : s.depotPickupTitle,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    NewspaperReportScreen(provider: p),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E7FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.assessment,
                                  size: 13,
                                  color: Color(0xFF1E3A8A),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  s.tr('Hawker/Area Report', 'हॉकर/क्षेत्र रिपोर्ट'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (bundleMap.isEmpty)
                      Text(
                        s.noActivePapersForDay,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: bundleMap.entries.map((entry) {
                            final pub = entry.key;
                            final count = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: pub.type == PublicationType.magazine
                                    ? Colors.purple.shade50
                                    : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: pub.type == PublicationType.magazine
                                      ? Colors.purple.shade200
                                      : Colors.blue.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    pub.displayName(s),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E3A8A),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Block / Society Filter Panel + Search + Status Tabs
              Container(
                color: const Color(0xFFEEF2FA),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Input Row
                    TextField(
                      controller: _searchCtrl,
                      onChanged: p.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: s.searchHint,
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: p.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  p.setSearchQuery('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Society / Colony Filter Row
                    if (societies.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.apartment,
                            size: 15,
                            color: Color(0xFF1E3A8A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            s.filterByBlockSociety,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const Spacer(),
                          if (p.hasLocationFilter)
                            InkWell(
                              onTap: p.clearLocationFilters,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.filter_alt_off,
                                      size: 13,
                                      color: Colors.redAccent,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      s.clearFilters,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _LocationFilterChip(
                              icon: Icons.apartment,
                              label:
                                  '${s.allSocieties} (${p.allCustomers.length})',
                              selected: p.selectedArea == null,
                              activeColor: const Color(0xFF1E3A8A),
                              onTap: () => p.setSelectedArea(null),
                            ),
                            ...societies.map((soc) {
                              final isSelected = p.selectedArea != null &&
                                  p.selectedArea!.toLowerCase() ==
                                      soc.toLowerCase();
                              final count = p.countForSociety(soc);
                              return Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: _LocationFilterChip(
                                  icon: Icons.location_city,
                                  label: '$soc ($count)',
                                  selected: isSelected,
                                  activeColor: const Color(0xFF1E3A8A),
                                  onTap: () => p.setSelectedArea(
                                    isSelected ? null : soc,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],

                    // Block / Wing Filter Row
                    if (blocks.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _LocationFilterChip(
                              icon: Icons.grid_view,
                              label: s.allBlocks,
                              selected: p.selectedBlock == null,
                              activeColor: Colors.indigo.shade700,
                              onTap: () => p.setSelectedBlock(null),
                            ),
                            ...blocks.map((blk) {
                              final isSelected = p.selectedBlock != null &&
                                  p.selectedBlock!.toLowerCase() ==
                                      blk.toLowerCase();
                              final count = p.countForBlock(blk);
                              return Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: _LocationFilterChip(
                                  icon: Icons.domain,
                                  label: '$blk ($count)',
                                  selected: isSelected,
                                  activeColor: Colors.indigo.shade700,
                                  onTap: () => p.setSelectedBlock(
                                    isSelected ? null : blk,
                                  ),
                                ),
                              );
                            }),
                            if (p.isOwner)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: ActionChip(
                                  avatar: const Icon(
                                    Icons.tune,
                                    size: 14,
                                    color: Color(0xFF4338CA),
                                  ),
                                  label: Text(
                                    s.manageBlocksBtn,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4338CA),
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFFEEF2FF),
                                  side: const BorderSide(
                                    color: Color(0xFFC7D2FE),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ManageBlocksScreen(provider: p),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    // Action Buttons: 1) Block-Wise Paper Count, 2) Morning List (Flat & Paper), 3) Month-End Billing
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade800,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.analytics_outlined,
                              size: 16,
                            ),
                            label: Text(
                              s.blockConsumptionBtn,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BlockWiseConsumptionScreen(provider: p),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.list_alt, size: 16),
                            label: Text(
                              s.generateMorningListBtn,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MorningDeliveryListScreen(provider: p),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade800,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.receipt_long, size: 16),
                            label: Text(
                              s.monthlyBillingBtn,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MonthlyBillingReportScreen(provider: p),
                                ),
                              );
                            },
                          ),

                          if (p.isOwner) ...[
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF065F46),
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.two_wheeler, size: 16),
                              label: Text(
                                '${s.tr("Hawkers", "हॉकर")} (${p.deliveryBoys.length})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DeliveryBoysScreen(provider: p),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4338CA),
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.domain_add, size: 16),
                              label: Text(
                                '${s.manageBlocksBtn} (${p.allManagedBlocks.length})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ManageBlocksScreen(provider: p),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: p.pendingApprovalsCount > 0
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFFD97706),
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.approval, size: 16),
                              label: Text(
                                '${s.approvalsTitle} (${p.pendingApprovalsCount})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ApprovalsScreen(provider: p),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),
                    // Status Filter Tabs (All / Started / Paused / Pending Today)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterTabChip(
                            label: '${s.filterAll} (${p.totalCustomersCount})',
                            selected: p.filter == DistributionFilter.all,
                            onSelected: () =>
                                p.setFilter(DistributionFilter.all),
                          ),
                          const SizedBox(width: 6),
                          _FilterTabChip(
                            label:
                                '${s.filterStarted} (${p.startedCustomersCount})',
                            selected: p.filter == DistributionFilter.started,
                            activeColor: Colors.green.shade700,
                            onSelected: () =>
                                p.setFilter(DistributionFilter.started),
                          ),
                          const SizedBox(width: 6),
                          _FilterTabChip(
                            label:
                                '${s.filterPaused} (${p.pausedCustomersCount})',
                            selected: p.filter == DistributionFilter.paused,
                            activeColor: Colors.deepOrange,
                            onSelected: () =>
                                p.setFilter(DistributionFilter.paused),
                          ),
                          const SizedBox(width: 6),
                          _FilterTabChip(
                            label: s.filterPendingToday,
                            selected:
                                p.filter == DistributionFilter.pendingToday,
                            activeColor: Colors.teal.shade700,
                            onSelected: () =>
                                p.setFilter(DistributionFilter.pendingToday),
                          ),
                          if (p.pendingApprovalCustomersCount > 0) ...[
                            const SizedBox(width: 6),
                            _FilterTabChip(
                              label:
                                  '${s.filterPendingApproval} (${p.pendingApprovalCustomersCount})',
                              selected:
                                  p.filter == DistributionFilter.pendingApproval,
                              activeColor: const Color(0xFFD97706),
                              onSelected: () =>
                                  p.setFilter(DistributionFilter.pendingApproval),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Distribution List View
              Expanded(
                child: customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 52,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.tr(
                                'No customers match the current filter',
                                'इस फ़िल्टर में कोई ग्राहक नहीं मिला',
                              ),
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            if (p.hasLocationFilter) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                icon: const Icon(Icons.filter_alt_off),
                                label: Text(s.clearFilters),
                                onPressed: p.clearLocationFilters,
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 84),
                        itemCount: customers.length,
                        itemBuilder: (context, index) {
                          final customer = customers[index];
                          return _CustomerDistributionCard(
                            customer: customer,
                            provider: p,
                            strings: s,
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

  void _showUserSwitchDialog(BuildContext context, DeliveryProvider p) {
    final s = p.strings;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: p.isOwner
                        ? const Color(0xFF1E3A8A)
                        : const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    child: Icon(
                      p.isOwner
                          ? Icons.admin_panel_settings
                          : Icons.delivery_dining,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.currentUser?.name ?? 'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          p.isOwner ? s.roleOwner : s.roleDeliveryBoy,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              if (p.isOwner) ...[
                ListTile(
                  leading: const Icon(Icons.approval, color: Color(0xFFD97706)),
                  title: Text(s.approvalsTitle),
                  trailing: p.pendingApprovalsCount > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${p.pendingApprovalsCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ApprovalsScreen(provider: p),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.two_wheeler, color: Color(0xFF059669)),
                  title: Text(s.manageDeliveryBoysTitle),
                  subtitle: Text(
                    '${p.deliveryBoys.length} ${s.tr("Delivery Boys", "हॉकर")}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DeliveryBoysScreen(provider: p),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.key, color: Color(0xFF1E3A8A)),
                  title: Text(s.editAdminProfile),
                  subtitle: Text(
                    '${s.tr("Current PIN", "वर्तमान पिन")}: ••••',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    showEditAdminPinDialog(context: context, provider: p);
                  },
                ),
                // Switch role buttons - Shown ONLY in Admin account!
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    s.isHindi
                        ? 'उपयोगकर्ता बदलें (केवल एडमिन)'
                        : 'Switch User (Admin Only)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                ...p.allUsers.map((user) {
                  final isCurrent = user.id == p.currentUser?.id;
                  if (isCurrent) return const SizedBox.shrink();
                  return ListTile(
                    leading: Icon(
                      user.isOwner
                          ? Icons.admin_panel_settings
                          : Icons.delivery_dining,
                      color: user.isOwner
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFF059669),
                    ),
                    title: Text(
                      user.isOwner
                          ? '${s.isHindi ? 'स्विच करें' : 'Switch to'}: ${s.roleOwner}'
                          : '${s.isHindi ? 'स्विच करें' : 'Switch to'}: ${s.roleDeliveryBoy}',
                    ),
                    subtitle: Text(user.name),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await p.switchUser(user);
                    },
                  );
                }),
              ],
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await p.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(provider: p),
                      ),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, size: 18),
                label: Text(
                  p.isOwner ? s.logoutBtn : s.tr('Logout', 'लॉगआउट'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, DeliveryProvider p) async {
    final s = p.strings;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Text(s.confirmLogoutTitle),
          ],
        ),
        content: Text(
          s.tr(
            'Are you sure you want to log out of ${p.currentUser?.name ?? "the app"}?',
            'क्या आप ${p.currentUser?.name ?? "ऐप"} से लॉगआउट करना चाहते हैं?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.tr('Logout', 'लॉगआउट')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await p.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginScreen(provider: p)),
          (route) => false,
        );
      }
    }
  }
}

class _LocationFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _LocationFilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? activeColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? Colors.white : activeColor,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 15),
                  const SizedBox(width: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterTabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onSelected;

  const _FilterTabChip({
    required this.label,
    required this.selected,
    this.activeColor = const Color(0xFF1E3A8A),
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      visualDensity: VisualDensity.compact,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : Colors.grey.shade800,
        ),
      ),
      selected: selected,
      selectedColor: activeColor,
      backgroundColor: Colors.white,
      onSelected: (_) => onSelected(),
    );
  }
}

class _CustomerDistributionCard extends StatelessWidget {
  final Customer customer;
  final DeliveryProvider provider;
  final AppStrings strings;

  const _CustomerDistributionCard({
    required this.customer,
    required this.provider,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final date = provider.selectedDate;
    final isStarted = customer.isStartedOnDate(date);
    final isDelivered = customer.isDeliveredOnDate(date);
    final pendingReq = provider.getPendingApprovalForCustomer(customer.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: pendingReq != null
              ? (pendingReq.actionType == ApprovalActionType.deleteCustomer
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFF59E0B))
              : (isStarted
                  ? (isDelivered ? Colors.teal.shade300 : Colors.green.shade200)
                  : Colors.orange.shade300),
          width: pendingReq != null ? 1.8 : 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(
                provider: provider,
                customerId: customer.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pending for Approval Flag Banner
              if (pendingReq != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: pendingReq.actionType == ApprovalActionType.deleteCustomer
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: pendingReq.actionType == ApprovalActionType.deleteCustomer
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF59E0B),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pendingReq.actionType == ApprovalActionType.deleteCustomer
                            ? Icons.warning_amber_rounded
                            : Icons.hourglass_top_rounded,
                        size: 18,
                        color: pendingReq.actionType == ApprovalActionType.deleteCustomer
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFB45309),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.pendingForApprovalFlag,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: pendingReq.actionType == ApprovalActionType.deleteCustomer
                                    ? const Color(0xFF991B1B)
                                    : const Color(0xFF92400E),
                              ),
                            ),
                            Text(
                              '${pendingReq.actionName(strings)} (${pendingReq.requestedBy})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: pendingReq.actionType == ApprovalActionType.deleteCustomer
                                    ? const Color(0xFFB91C1C)
                                    : const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (provider.isOwner)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ApprovalsScreen(provider: provider),
                              ),
                            );
                          },
                          child: Text(
                            strings.reviewApprovalBtn,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              // Top Row: Sequence #, House No + Block/Society Badges, Status Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${customer.sequenceNo}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              customer.houseNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            if (customer.block.trim().isNotEmpty)
                              InkWell(
                                onTap: () =>
                                    provider.setSelectedBlock(customer.block),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.indigo.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    customer.block,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.indigo.shade900,
                                    ),
                                  ),
                                ),
                              ),
                            if (customer.area.trim().isNotEmpty)
                              InkWell(
                                onTap: () =>
                                    provider.setSelectedArea(customer.area),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    customer.area,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Started / Paused Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isStarted
                          ? Colors.green.shade100
                          : Colors.deepOrange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isStarted
                              ? Icons.play_circle_fill
                              : Icons.pause_circle_filled,
                          size: 14,
                          color: isStarted
                              ? Colors.green.shade800
                              : Colors.deepOrange.shade800,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isStarted
                              ? strings.statusStarted
                              : strings.statusPaused,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isStarted
                                ? Colors.green.shade900
                                : Colors.deepOrange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Pause Reason / Date Range Banner if Paused
              if (!isStarted &&
                  (customer.pauseReason.isNotEmpty ||
                      customer.pauseStartDate != null ||
                      customer.pauseEndDate != null)) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_busy,
                        size: 15,
                        color: Colors.deepOrange,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          [
                            if (customer.pauseStartDate != null ||
                                customer.pauseEndDate != null)
                              '${customer.pauseStartDate != null ? strings.formatDate(customer.pauseStartDate!) : ""} → ${customer.pauseEndDate != null ? strings.formatDate(customer.pauseEndDate!) : ""}',
                            if (customer.pauseReason.isNotEmpty)
                              customer.pauseReason,
                          ].join(' • '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.deepOrange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Subscribed Newspapers & Magazines Chips (with Daily/Weekend Variant)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: customer.subscriptions.map((sub) {
                  final pub = provider.getPublicationById(sub.publicationId);
                  final pubName = pub?.displayName(strings) ?? sub.publicationId;
                  final deliverableToday =
                      isStarted && sub.isDeliverableOnDate(date);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: deliverableToday
                          ? Colors.blue.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: deliverableToday
                            ? Colors.blue.shade300
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          pub?.type == PublicationType.magazine
                              ? Icons.menu_book
                              : Icons.newspaper,
                          size: 13,
                          color: deliverableToday
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$pubName ×${sub.quantity}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: deliverableToday
                                ? Colors.black87
                                : Colors.grey.shade600,
                            decoration: sub.isPaused
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: deliverableToday
                                ? const Color(0xFF1E3A8A)
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            sub.frequency.shortLabel(strings),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              if (customer.notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '📌 ${customer.notes}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],

              const Divider(height: 16),

              // Quick Action Buttons Row: Pause/Start Toggle + Delivered Checkmark
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isStarted
                            ? Colors.deepOrange.shade800
                            : Colors.green.shade800,
                        side: BorderSide(
                          color: isStarted
                              ? Colors.deepOrange.shade300
                              : Colors.green.shade400,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: Icon(
                        isStarted ? Icons.pause : Icons.play_arrow,
                        size: 17,
                      ),
                      label: Text(
                        isStarted
                            ? strings.btnPausePaper
                            : strings.btnStartPaper,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
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
                  if (isStarted) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDelivered
                              ? Colors.teal.shade600
                              : Colors.grey.shade200,
                          foregroundColor:
                              isDelivered ? Colors.white : Colors.black87,
                          elevation: 0,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: Icon(
                          isDelivered
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 17,
                        ),
                        label: Text(
                          isDelivered
                              ? strings.deliveredDone
                              : strings.markDelivered,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () =>
                            provider.toggleDeliveredForSelectedDate(customer.id),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
