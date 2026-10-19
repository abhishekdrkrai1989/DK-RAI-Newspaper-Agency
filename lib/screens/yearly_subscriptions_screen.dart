import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/yearly_booking_scheme.dart';
import '../models/yearly_subscription.dart';
import '../providers/delivery_provider.dart';

class YearlySubscriptionsScreen extends StatefulWidget {
  final DeliveryProvider provider;
  final int initialTabIndex;

  const YearlySubscriptionsScreen({
    super.key,
    required this.provider,
    this.initialTabIndex = 0,
  });

  @override
  State<YearlySubscriptionsScreen> createState() =>
      _YearlySubscriptionsScreenState();
}

class _YearlySubscriptionsScreenState extends State<YearlySubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _filterType = 'all'; // all, active, expiring, expired, gift_pending, m_coupon, physical_coupon

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<YearlySubscription> _filterSubscriptions(
      List<YearlySubscription> subs) {
    final query = _searchCtrl.text.trim().toLowerCase();
    return subs.where((s) {
      if (query.isNotEmpty) {
        final matchesQuery = s.customerName.toLowerCase().contains(query) ||
            s.address.toLowerCase().contains(query) ||
            s.phone.toLowerCase().contains(query) ||
            s.newspaperScheme.toLowerCase().contains(query) ||
            s.couponCode.toLowerCase().contains(query) ||
            s.giftItem.toLowerCase().contains(query);
        if (!matchesQuery) return false;
      }

      switch (_filterType) {
        case 'active':
          return s.isActive;
        case 'expiring':
          return s.isExpiringSoon;
        case 'expired':
          return s.isExpired;
        case 'gift_pending':
          return s.isGiftPending;
        case 'm_coupon':
          return s.couponType == CouponType.mCoupon;
        case 'physical_coupon':
          return s.couponType == CouponType.physicalCoupon;
        case 'all':
        default:
          return true;
      }
    }).toList();
  }

  void _showAddEditSubscriptionDialog({YearlySubscription? existing}) {
    final isEditing = existing != null;
    final p = widget.provider;
    final strings = p.strings;

    Customer? selectedCustomer;
    final nameCtrl =
        TextEditingController(text: existing?.customerName ?? '');
    final addressCtrl =
        TextEditingController(text: existing?.address ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final couponCodeCtrl =
        TextEditingController(text: existing?.couponCode ?? '');
    final giftItemCtrl =
        TextEditingController(text: existing?.giftItem ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    final availableSchemes = p.yearlySchemes.isNotEmpty
        ? p.yearlySchemes
        : YearlyBookingScheme.defaultSchemes();

    String selectedScheme = existing?.newspaperScheme ??
        (availableSchemes.isNotEmpty ? availableSchemes.first.name : 'Hindustan Times');

    DateTime startDate = existing?.startDate ?? DateTime.now();
    DateTime endDate = existing?.endDate ??
        startDate.add(const Duration(days: 365));

    CouponType couponType = existing?.couponType ?? CouponType.physicalCoupon;
    bool isGiftApplicable = existing?.isGiftApplicable ?? false;
    bool isGiftDelivered = existing?.isGiftDelivered ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottomPadding = MediaQuery.of(ctx).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.only(
              bottom: bottomPadding,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing
                            ? strings.tr(
                                'Edit Yearly Subscription',
                                'à¤µà¤¾à¤°à¥à¤·à¤¿à¤• à¤¸à¤¦à¤¸à¥à¤¯à¤¤à¤¾ à¤¸à¤‚à¤ªà¤¾à¤¦à¤¿à¤¤ à¤•à¤°à¥‡à¤‚',
                              )
                            : strings.tr(
                                'New Yearly Booking / Scheme',
                                'à¤¨à¤ˆ à¤µà¤¾à¤°à¥à¤·à¤¿à¤• à¤¬à¥à¤•à¤¿à¤‚à¤— / à¤¯à¥‹à¤œà¤¨à¤¾',
                              ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 6),

                  // Quick Select from Existing Customers
                  if (!isEditing && p.allCustomers.isNotEmpty) ...[
                    Text(
                      strings.tr(
                        'Autofill from Existing Customer (Optional):',
                        'à¤®à¥Œà¤œà¥‚à¤¦à¤¾ à¤—à¥à¤°à¤¾à¤¹à¤• à¤¸à¥‡ à¤šà¥à¤¨à¥‡à¤‚ (à¤µà¥ˆà¤•à¤²à¥à¤ªà¤¿à¤•):',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<Customer>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: strings.tr(
                          '-- Select Customer to Autofill --',
                          '-- à¤—à¥à¤°à¤¾à¤¹à¤• à¤šà¥à¤¨à¥‡à¤‚ --',
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: selectedCustomer,
                      items: p.allCustomers
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                '${c.name} (${c.houseNumber}, ${c.block})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (cust) {
                        if (cust != null) {
                          setModalState(() {
                            selectedCustomer = cust;
                            nameCtrl.text = cust.name;
                            addressCtrl.text =
                                '${cust.houseNumber}, ${cust.block}, ${cust.area}';
                            phoneCtrl.text = cust.phone;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Customer Name
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: strings.tr(
                        'Name of Customer *',
                        'à¤—à¥à¤°à¤¾à¤¹à¤• à¤•à¤¾ à¤¨à¤¾à¤® *',
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Address
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: strings.tr('Address *', 'à¤ªà¤¤à¤¾ / à¤®à¤•à¤¾à¤¨ à¤¨à¤‚. *'),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: strings.tr(
                        'Phone / Mobile Number',
                        'à¤®à¥‹à¤¬à¤¾à¤‡à¤² à¤¨à¤‚à¤¬à¤°',
                      ),
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Newspaper Booking Scheme with Add/Edit Scheme Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.tr(
                          'Yearly Newspaper Scheme *',
                          'वार्षिक अखबार योजना *',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        icon: const Icon(Icons.add_circle_outline,
                            size: 15, color: Color(0xFF0F766E)),
                        label: Text(
                          strings.tr(
                            '+ Add / Edit Schemes',
                            '+ योजना जोड़ें / बदलें',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        onPressed: () async {
                          final newScheme = await _showAddEditSchemeDialog();
                          if (newScheme != null) {
                            setModalState(() {
                              selectedScheme = newScheme.name;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (ctx) {
                      final currentSchemes =
                          widget.provider.yearlySchemes.isNotEmpty
                              ? widget.provider.yearlySchemes
                              : YearlyBookingScheme.defaultSchemes();
                      final effectiveValue =
                          currentSchemes.any((s) => s.name == selectedScheme)
                              ? selectedScheme
                              : currentSchemes.first.name;

                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: effectiveValue,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: currentSchemes
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.name,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.newspaper,
                                      size: 18,
                                      color: Color(0xFF0D9488),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        s.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedScheme = val;
                            });
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // Dates: Start Date & Ending Date
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setModalState(() {
                                startDate = picked;
                                // Auto calculate 1 year later
                                endDate = DateTime(
                                  picked.year + 1,
                                  picked.month,
                                  picked.day,
                                );
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: strings.tr(
                                'Start Date',
                                'à¤¶à¥à¤°à¥‚ à¤•à¥€ à¤¤à¤¾à¤°à¥€à¤–',
                              ),
                              prefixIcon:
                                  const Icon(Icons.calendar_today, size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setModalState(() {
                                endDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: strings.tr(
                                'Ending Date',
                                'à¤¸à¤®à¤¾à¤ªà¥à¤¤à¤¿ à¤¤à¤¾à¤°à¥€à¤–',
                              ),
                              prefixIcon:
                                  const Icon(Icons.event_available, size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              '${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Coupon Type (M-Coupon / Physical Coupon)
                  Text(
                    strings.tr('Coupon Type', 'à¤•à¥‚à¤ªà¤¨ à¤ªà¥à¤°à¤•à¤¾à¤°'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.phone_android, size: 16),
                              SizedBox(width: 4),
                              Text('M-Coupon'),
                            ],
                          ),
                          selected: couponType == CouponType.mCoupon,
                          selectedColor: const Color(0xFFBFDBFE),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                couponType = CouponType.mCoupon;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.confirmation_number_outlined,
                                  size: 16),
                              SizedBox(width: 4),
                              Text('Physical Coupon'),
                            ],
                          ),
                          selected: couponType == CouponType.physicalCoupon,
                          selectedColor: const Color(0xFFE9D5FF),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                couponType = CouponType.physicalCoupon;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Coupon Code / Booklet number
                  TextField(
                    controller: couponCodeCtrl,
                    decoration: InputDecoration(
                      labelText: strings.tr(
                        'Coupon Code / Booklet No. (Optional)',
                        'à¤•à¥‚à¤ªà¤¨ à¤•à¥‹à¤¡ / à¤¬à¥à¤•à¤²à¥‡à¤Ÿ à¤¨à¤‚. (à¤µà¥ˆà¤•à¤²à¥à¤ªà¤¿à¤•)',
                      ),
                      prefixIcon: const Icon(Icons.qr_code_2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Gift Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.card_giftcard,
                                  color: Color(0xFFD97706),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  strings.tr(
                                    'Is Gift Applicable?',
                                    'à¤•à¥à¤¯à¤¾ à¤‰à¤ªà¤¹à¤¾à¤° à¤²à¤¾à¤—à¥‚ à¤¹à¥ˆ?',
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: isGiftApplicable,
                              activeColor: const Color(0xFF059669),
                              onChanged: (val) {
                                setModalState(() {
                                  isGiftApplicable = val;
                                  if (!val) isGiftDelivered = false;
                                });
                              },
                            ),
                          ],
                        ),
                        if (isGiftApplicable) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: giftItemCtrl,
                            decoration: InputDecoration(
                              labelText: strings.tr(
                                'Gift Item Name (e.g. Iron, Cooker, Blanket)',
                                'à¤‰à¤ªà¤¹à¤¾à¤° à¤•à¤¾ à¤¨à¤¾à¤® (à¤œà¥ˆà¤¸à¥‡ à¤ªà¥à¤°à¥‡à¤¸, à¤•à¥à¤•à¤°, à¤•à¤‚à¤¬à¤²)',
                              ),
                              prefixIcon:
                                  const Icon(Icons.redeem_outlined, size: 20),
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                strings.tr(
                                  'Is Gift Delivered?',
                                  'à¤•à¥à¤¯à¤¾ à¤‰à¤ªà¤¹à¤¾à¤° à¤¦à¥‡ à¤¦à¤¿à¤¯à¤¾ à¤—à¤¯à¤¾?',
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isGiftDelivered
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                              Switch(
                                value: isGiftDelivered,
                                activeColor: const Color(0xFF059669),
                                onChanged: (val) {
                                  setModalState(() {
                                    isGiftDelivered = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: strings.tr(
                        'Additional Notes / Remarks',
                        'à¤…à¤¤à¤¿à¤°à¤¿à¤•à¥à¤¤ à¤Ÿà¤¿à¤ªà¥à¤ªà¤£à¥€ / à¤µà¤¿à¤µà¤°à¤£',
                      ),
                      prefixIcon: const Icon(Icons.note_alt_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.save),
                      label: Text(
                        isEditing
                            ? strings.tr(
                                'Update Subscription',
                                'à¤¸à¤¦à¤¸à¥à¤¯à¤¤à¤¾ à¤…à¤ªà¤¡à¥‡à¤Ÿ à¤•à¤°à¥‡à¤‚',
                              )
                            : strings.tr(
                                'Save Subscription',
                                'à¤¸à¤¦à¤¸à¥à¤¯à¤¤à¤¾ à¤¸à¥à¤°à¤•à¥à¤·à¤¿à¤¤ à¤•à¤°à¥‡à¤‚',
                              ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final address = addressCtrl.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                strings.tr(
                                  'Please enter customer name',
                                  'à¤•à¥ƒà¤ªà¤¯à¤¾ à¤—à¥à¤°à¤¾à¤¹à¤• à¤•à¤¾ à¤¨à¤¾à¤® à¤¦à¤°à¥à¤œ à¤•à¤°à¥‡à¤‚',
                                ),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (address.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                strings.tr(
                                  'Please enter customer address',
                                  'à¤•à¥ƒà¤ªà¤¯à¤¾ à¤—à¥à¤°à¤¾à¤¹à¤• à¤•à¤¾ à¤ªà¤¤à¤¾ à¤¦à¤°à¥à¤œ à¤•à¤°à¥‡à¤‚',
                                ),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final now = DateTime.now();
                        final sub = YearlySubscription(
                          id: existing?.id ??
                              'sub_${now.millisecondsSinceEpoch}',
                          customerName: name,
                          customerId: selectedCustomer?.id ??
                              existing?.customerId ??
                              '',
                          address: address,
                          phone: phoneCtrl.text.trim(),
                          newspaperScheme: selectedScheme,
                          startDate: startDate,
                          endDate: endDate,
                          couponType: couponType,
                          couponCode: couponCodeCtrl.text.trim(),
                          isGiftApplicable: isGiftApplicable,
                          isGiftDelivered: isGiftDelivered,
                          giftItem: giftItemCtrl.text.trim(),
                          giftDeliveredDate: isGiftDelivered
                              ? (existing?.giftDeliveredDate ?? now)
                              : null,
                          notes: notesCtrl.text.trim(),
                          updatedAt: now,
                        );

                        await widget.provider.saveYearlySubscription(sub);
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              strings.tr(
                                'Yearly subscription saved successfully!',
                                'à¤µà¤¾à¤°à¥à¤·à¤¿à¤• à¤¸à¤¦à¤¸à¥à¤¯à¤¤à¤¾ à¤¸à¤«à¤²à¤¤à¤¾à¤ªà¥‚à¤°à¥à¤µà¤• à¤¸à¥à¤°à¤•à¥à¤·à¤¿à¤¤ à¤¹à¥‹ à¤—à¤ˆ!',
                              ),
                            ),
                            backgroundColor: const Color(0xFF059669),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<YearlyBookingScheme?> _showAddEditSchemeDialog(
      {YearlyBookingScheme? existing}) async {
    final isEditing = existing != null;
    final strings = widget.provider.strings;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null && existing.price > 0
          ? existing.price.toStringAsFixed(0)
          : '',
    );
    final descCtrl =
        TextEditingController(text: existing?.description ?? '');

    return showDialog<YearlyBookingScheme>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isEditing
              ? strings.tr('Edit Booking Scheme', 'à¤¯à¥‹à¤œà¤¨à¤¾ à¤¸à¤‚à¤ªà¤¾à¤¦à¤¿à¤¤ à¤•à¤°à¥‡à¤‚')
              : strings.tr('Add New Yearly Scheme', 'à¤¨à¤ˆ à¤µà¤¾à¤°à¥à¤·à¤¿à¤• à¤¯à¥‹à¤œà¤¨à¤¾ à¤œà¥‹à¤¡à¤¼à¥‡à¤‚'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: strings.tr(
                  'Scheme / Newspaper Name *',
                  'à¤¯à¥‹à¤œà¤¨à¤¾ / à¤…à¤–à¤¬à¤¾à¤° à¤•à¤¾ à¤¨à¤¾à¤® *',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: strings.tr(
                  'Yearly Price (â‚¹, Optional)',
                  'à¤µà¤¾à¤°à¥à¤·à¤¿à¤• à¤®à¥‚à¤²à¥à¤¯ (â‚¹, à¤µà¥ˆà¤•à¤²à¥à¤ªà¤¿à¤•)',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: strings.tr('Description', 'à¤µà¤¿à¤µà¤°à¤£ / à¤¨à¥‹à¤Ÿ'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
              final now = DateTime.now();

              final scheme = YearlyBookingScheme(
                id: existing?.id ?? 'scheme_${now.millisecondsSinceEpoch}',
                name: name,
                price: price,
                description: descCtrl.text.trim(),
                isActive: true,
                updatedAt: now,
              );

              await widget.provider.saveYearlyBookingScheme(scheme);
              if (!mounted) return;
              Navigator.pop(ctx, scheme);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    strings.tr(
                      'Scheme saved successfully!',
                      'à¤¯à¥‹à¤œà¤¨à¤¾ à¤¸à¥à¤°à¤•à¥à¤·à¤¿à¤¤ à¤¹à¥‹ à¤—à¤ˆ!',
                    ),
                  ),
                  backgroundColor: const Color(0xFF059669),
                ),
              );
            },
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteScheme(YearlyBookingScheme sc) async {
    final s = widget.provider.strings;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Text(
              s.tr('Delete Scheme?', 'योजना हटाएं?'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          s.tr(
            'Are you sure you want to delete "${sc.name}" from Annual Subscription Schemes?',
            'क्या आप "${sc.name}" को वार्षिक सदस्यता योजनाओं से हटाना चाहते हैं?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.delete, size: 16),
            label: Text(s.tr('Delete Scheme', 'योजना हटाएं')),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.provider.deleteYearlyBookingScheme(sc.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.tr(
              '"${sc.name}" deleted successfully.',
              '"${sc.name}" योजना हटा दी गई।',
            ),
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Widget _buildSubscriptionCard(YearlySubscription sub) {
    final s = widget.provider.strings;
    final isExpired = sub.isExpired;
    final isExpiring = sub.isExpiringSoon;

    Color statusColor;
    String statusText;
    if (isExpired) {
      statusColor = const Color(0xFFDC2626);
      statusText = s.tr('Expired', 'à¤¸à¤®à¤¾à¤ªà¥à¤¤');
    } else if (isExpiring) {
      statusColor = const Color(0xFFD97706);
      statusText = s.tr(
        'Expiring in ${sub.daysRemaining} days',
        '${sub.daysRemaining} à¤¦à¤¿à¤¨ à¤®à¥‡à¤‚ à¤¸à¤®à¤¾à¤ªà¥à¤¤',
      );
    } else {
      statusColor = const Color(0xFF059669);
      statusText = s.tr(
        'Active â€¢ ${sub.daysRemaining} days left',
        'à¤šà¤¾à¤²à¥‚ â€¢ ${sub.daysRemaining} à¤¦à¤¿à¤¨ à¤¶à¥‡à¤·',
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isExpiring ? Colors.amber.shade400 : Colors.grey.shade200,
          width: isExpiring ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Newspaper Scheme badge + Expiry Status pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.newspaper,
                          size: 15,
                          color: Color(0xFF0D9488),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            sub.newspaperScheme,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F766E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Customer Name & Phone
            Row(
              children: [
                const Icon(
                  Icons.person,
                  size: 18,
                  color: Color(0xFF1E3A8A),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sub.customerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (sub.phone.isNotEmpty) ...[
                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    sub.phone,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),

            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sub.address,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Subscription Dates
            Row(
              children: [
                const Icon(
                  Icons.date_range,
                  size: 15,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  '${s.formatDate(sub.startDate)}  âž  ${s.formatDate(sub.endDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Badges Row: Coupon Type badge & Gift Status badge
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // Coupon Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: sub.couponType == CouponType.mCoupon
                        ? const Color(0xFFDBEAFE)
                        : const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sub.couponType == CouponType.mCoupon
                            ? Icons.phone_android
                            : Icons.confirmation_number_outlined,
                        size: 13,
                        color: sub.couponType == CouponType.mCoupon
                            ? const Color(0xFF1D4ED8)
                            : const Color(0xFF7E22CE),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sub.couponCode.isNotEmpty
                            ? '${sub.couponType.displayName} (#${sub.couponCode})'
                            : sub.couponType.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: sub.couponType == CouponType.mCoupon
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFF7E22CE),
                        ),
                      ),
                    ],
                  ),
                ),

                // Gift Status Badge
                if (sub.isGiftApplicable) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: sub.isGiftDelivered
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: sub.isGiftDelivered
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          size: 13,
                          color: sub.isGiftDelivered
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sub.isGiftDelivered
                              ? (sub.giftItem.isNotEmpty
                                  ? s.tr(
                                      'Gift Delivered: ${sub.giftItem}',
                                      'à¤‰à¤ªà¤¹à¤¾à¤° à¤¦à¤¿à¤¯à¤¾: ${sub.giftItem}',
                                    )
                                  : s.tr('Gift Delivered', 'à¤‰à¤ªà¤¹à¤¾à¤° à¤¦à¤¿à¤¯à¤¾ à¤—à¤¯à¤¾'))
                              : (sub.giftItem.isNotEmpty
                                  ? s.tr(
                                      'Gift Pending: ${sub.giftItem}',
                                      'à¤‰à¤ªà¤¹à¤¾à¤° à¤¬à¤¾à¤•à¥€: ${sub.giftItem}',
                                    )
                                  : s.tr('Gift Pending', 'à¤‰à¤ªà¤¹à¤¾à¤° à¤¬à¤¾à¤•à¥€')),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: sub.isGiftDelivered
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s.tr('No Gift', 'à¤‰à¤ªà¤¹à¤¾à¤° à¤¨à¤¹à¥€à¤‚'),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            if (sub.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Note: ${sub.notes}',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF64748B),
                ),
              ),
            ],

            const Divider(height: 18),

            // Card Bottom Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Quick Toggle Gift Delivered
                if (sub.isGiftApplicable) ...[
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: sub.isGiftDelivered
                          ? const Color(0xFFD97706)
                          : const Color(0xFF059669),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(
                      sub.isGiftDelivered
                          ? Icons.undo
                          : Icons.check_circle_outline,
                      size: 16,
                    ),
                    label: Text(
                      sub.isGiftDelivered
                          ? s.tr('Mark Pending', 'à¤¬à¤¾à¤•à¥€ à¤•à¤°à¥‡à¤‚')
                          : s.tr('Mark Delivered', 'à¤‰à¤ªà¤¹à¤¾à¤° à¤¦à¥‡ à¤¦à¤¿à¤¯à¤¾'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () =>
                        widget.provider.toggleGiftDelivered(sub.id),
                  ),
                  const Spacer(),
                ],

                // Edit Button
                IconButton(
                  tooltip: s.tr('Edit', 'à¤¸à¤‚à¤ªà¤¾à¤¦à¤¿à¤¤ à¤•à¤°à¥‡à¤‚'),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 19,
                    color: Color(0xFF2563EB),
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      _showAddEditSubscriptionDialog(existing: sub),
                ),

                // Delete Button
                IconButton(
                  tooltip: s.tr('Delete', 'à¤¹à¤Ÿà¤¾à¤à¤‚'),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 19,
                    color: Color(0xFFDC2626),
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                          s.tr(
                            'Delete Yearly Subscription?',
                            'à¤µà¤¾à¤°à¥à¤·à¤¿à¤• à¤¸à¤¦à¤¸à¥à¤¯à¤¤à¤¾ à¤¹à¤Ÿà¤¾à¤à¤‚?',
                          ),
                        ),
                        content: Text(
                          s.tr(
                            'Are you sure you want to delete yearly booking for ${sub.customerName}?',
                            'à¤•à¥à¤¯à¤¾ à¤†à¤ª ${sub.customerName} à¤•à¥€ à¤µà¤¾à¤°à¥à¤·à¤¿à¤• à¤¬à¥à¤•à¤¿à¤‚à¤— à¤¹à¤Ÿà¤¾à¤¨à¤¾ à¤šà¤¾à¤¹à¤¤à¥‡ à¤¹à¥ˆà¤‚?',
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
                            child: Text(s.tr('Delete', 'à¤¹à¤Ÿà¤¾à¤à¤‚')),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await widget.provider
                          .deleteYearlySubscription(sub.id);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.provider,
      builder: (context, _) {
        final p = widget.provider;
        final s = p.strings;
        final filteredSubs = _filterSubscriptions(p.yearlySubscriptions);
        final schemes = p.yearlySchemes.isNotEmpty
            ? p.yearlySchemes
            : YearlyBookingScheme.defaultSchemes();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            title: Text(
              s.tr(
                'Yearly Subscriptions & Schemes',
                'à¤µà¤¾à¤°à¥à¤·à¤¿à¤• à¤¸à¤¦à¤¸à¥à¤¯à¤¤à¤¾ à¤à¤µà¤‚ à¤¬à¥à¤•à¤¿à¤‚à¤—',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF38BDF8),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFFCBD5E1),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.book_online, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${s.tr("Bookings", "à¤¬à¥à¤•à¤¿à¤‚à¤—")} (${p.totalYearlySubscriptionsCount})',
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.newspaper, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${s.tr("Yearly Schemes", "à¤…à¤–à¤¬à¤¾à¤° à¤¯à¥‹à¤œà¤¨à¤¾à¤à¤‚")} (${schemes.length})',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.18),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline,
                      size: 16, color: Colors.white),
                  label: Text(
                    s.tr('+ Add Scheme', '+ नई योजना'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () => _showAddEditSchemeDialog(),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: s.tr('Refresh from Cloud', 'à¤•à¥à¤²à¤¾à¤‰à¤¡ à¤¸à¥‡ à¤°à¤¿à¤«à¥à¤°à¥‡à¤¶ à¤•à¤°à¥‡à¤‚'),
                icon: p.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: p.isSyncing
                    ? null
                    : () async {
                        final res =
                            await p.syncWithCloud(forceDownload: true);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.message),
                            backgroundColor: res.success
                                ? const Color(0xFF059669)
                                : const Color(0xFFDC2626),
                          ),
                        );
                      },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: _tabController.index == 0
                ? const Color(0xFF1E3A8A)
                : const Color(0xFF0F766E),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(
              _tabController.index == 0
                  ? s.tr('New Booking', 'नई बुकिंग')
                  : s.tr('+ Add Annual Scheme', '+ नई योजना'),
            ),
            onPressed: () {
              if (_tabController.index == 0) {
                _showAddEditSubscriptionDialog();
              } else {
                _showAddEditSchemeDialog();
              }
            },
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // ============================================
              // Tab 1: Yearly Subscriptions / Bookings List
              // ============================================
              RefreshIndicator(
                onRefresh: () => p.syncWithCloud(forceDownload: true),
                child: Column(
                  children: [
                    // Summary Metric Stats
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          _buildStatCard(
                            label: s.tr('Total', 'à¤•à¥à¤²'),
                            value: '${p.totalYearlySubscriptionsCount}',
                            icon: Icons.assignment,
                            color: const Color(0xFF1E3A8A),
                            isSelected: _filterType == 'all',
                            onTap: () => setState(() => _filterType = 'all'),
                          ),
                          const SizedBox(width: 6),
                          _buildStatCard(
                            label: s.tr('Active', 'à¤šà¤¾à¤²à¥‚'),
                            value: '${p.activeYearlySubscriptionsCount}',
                            icon: Icons.check_circle,
                            color: const Color(0xFF059669),
                            isSelected: _filterType == 'active',
                            onTap: () =>
                                setState(() => _filterType = 'active'),
                          ),
                          const SizedBox(width: 6),
                          _buildStatCard(
                            label: s.tr('â‰¤30 Days', 'à¤¸à¤®à¤¾à¤ªà¥à¤¤ à¤ªà¥à¤°à¤¾à¤¯'),
                            value:
                                '${p.expiringSoonYearlySubscriptionsCount}',
                            icon: Icons.timer,
                            color: const Color(0xFFD97706),
                            isSelected: _filterType == 'expiring',
                            onTap: () =>
                                setState(() => _filterType = 'expiring'),
                          ),
                          const SizedBox(width: 6),
                          _buildStatCard(
                            label: s.tr('Gifts Due', 'à¤‰à¤ªà¤¹à¤¾à¤° à¤¬à¤¾à¤•à¥€'),
                            value: '${p.pendingGiftsCount}',
                            icon: Icons.card_giftcard,
                            color: const Color(0xFFDC2626),
                            isSelected: _filterType == 'gift_pending',
                            onTap: () => setState(
                              () => _filterType = 'gift_pending',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick Shortcut Banner to Annual Subscription Schemes
                    InkWell(
                      onTap: () => _tabController.animateTo(1),
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.tune,
                                color: Color(0xFF16A34A), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.tr(
                                  '${schemes.length} Annual Schemes (Combos)',
                                  '${schemes.length} वार्षिक योजनाएं व कॉम्बो',
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                              ),
                              icon: const Icon(Icons.add_circle,
                                  size: 15, color: Color(0xFF0F766E)),
                              label: Text(
                                s.tr('+ Add Scheme', '+ नई योजना'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                              onPressed: () => _showAddEditSchemeDialog(),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              s.tr('Manage / Edit →', 'प्रबंधित / बदलें →'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Search & Filter Bar
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: s.tr(
                                'Search by customer, address, scheme, coupon...',
                                'à¤—à¥à¤°à¤¾à¤¹à¤•, à¤ªà¤¤à¤¾, à¤¯à¥‹à¤œà¤¨à¤¾, à¤•à¥‚à¤ªà¤¨ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤–à¥‹à¤œà¥‡à¤‚...',
                              ),
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              fillColor: const Color(0xFFF1F5F9),
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                FilterChip(
                                  label: Text(s.tr('All', 'à¤¸à¤­à¥€')),
                                  selected: _filterType == 'all',
                                  onSelected: (_) =>
                                      setState(() => _filterType = 'all'),
                                ),
                                const SizedBox(width: 6),
                                FilterChip(
                                  label: Text(s.tr('Active', 'à¤šà¤¾à¤²à¥‚')),
                                  selected: _filterType == 'active',
                                  onSelected: (_) =>
                                      setState(() => _filterType = 'active'),
                                ),
                                const SizedBox(width: 6),
                                FilterChip(
                                  label: Text(
                                    s.tr('Expiring Soon', 'à¤œà¤²à¥à¤¦ à¤¸à¤®à¤¾à¤ªà¥à¤¤'),
                                  ),
                                  selected: _filterType == 'expiring',
                                  onSelected: (_) =>
                                      setState(() => _filterType = 'expiring'),
                                ),
                                const SizedBox(width: 6),
                                FilterChip(
                                  label: Text(s.tr('Expired', 'à¤¸à¤®à¤¾à¤ªà¥à¤¤')),
                                  selected: _filterType == 'expired',
                                  onSelected: (_) =>
                                      setState(() => _filterType = 'expired'),
                                ),
                                const SizedBox(width: 6),
                                FilterChip(
                                  label: Text(
                                    s.tr('Gift Pending', 'à¤‰à¤ªà¤¹à¤¾à¤° à¤¬à¤¾à¤•à¥€'),
                                  ),
                                  selected: _filterType == 'gift_pending',
                                  onSelected: (_) => setState(
                                    () => _filterType = 'gift_pending',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                FilterChip(
                                  label: const Text('M-Coupon'),
                                  selected: _filterType == 'm_coupon',
                                  onSelected: (_) => setState(
                                    () => _filterType = 'm_coupon',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                FilterChip(
                                  label: const Text('Physical Coupon'),
                                  selected: _filterType == 'physical_coupon',
                                  onSelected: (_) => setState(
                                    () => _filterType = 'physical_coupon',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Subscriptions List
                    Expanded(
                      child: filteredSubs.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 80),
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.book_online_outlined,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        s.tr(
                                          'No yearly subscriptions found',
                                          'à¤•à¥‹à¤ˆ à¤µà¤¾à¤°à¥à¤·à¤¿à¤• à¤¸à¤¦à¤¸à¥à¤¯à¤¤à¤¾ à¤¨à¤¹à¥€à¤‚ à¤®à¤¿à¤²à¥€',
                                        ),
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF1E3A8A),
                                          foregroundColor: Colors.white,
                                        ),
                                        icon: const Icon(Icons.add),
                                        label: Text(
                                          s.tr(
                                            'Add First Yearly Booking',
                                            'à¤ªà¤¹à¤²à¥€ à¤µà¤¾à¤°à¥à¤·à¤¿à¤• à¤¬à¥à¤•à¤¿à¤‚à¤— à¤œà¥‹à¤¡à¤¼à¥‡à¤‚',
                                          ),
                                        ),
                                        onPressed:
                                            _showAddEditSubscriptionDialog,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filteredSubs.length,
                              itemBuilder: (ctx, i) =>
                                  _buildSubscriptionCard(filteredSubs[i]),
                            ),
                    ),
                  ],
                ),
              ),

              // ============================================
              // Tab 2: Newspaper Schemes Master Table
              // ============================================
              RefreshIndicator(
                onRefresh: () => p.syncWithCloud(forceDownload: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(14),
                  children: [
                    // Top Prominent Button to Add New Annual Scheme
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.add_circle, size: 22),
                        label: Text(
                          s.tr(
                            '+ Add New Annual Subscription Scheme',
                            '+ नई वार्षिक योजना जोड़ें',
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => _showAddEditSchemeDialog(),
                      ),
                    ),
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF1D4ED8),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.tr(
                                'Standard Yearly Subscription Schemes & Combos for Hindustan Times, Times of India, Mint, Amar Ujala, etc.',
                                'à¤¹à¤¿à¤‚à¤¦à¥à¤¸à¥à¤¤à¤¾à¤¨ à¤Ÿà¤¾à¤‡à¤®à¥à¤¸, à¤Ÿà¤¾à¤‡à¤®à¥à¤¸ à¤‘à¤« à¤‡à¤‚à¤¡à¤¿à¤¯à¤¾, à¤®à¤¿à¤‚à¤Ÿ, à¤…à¤®à¤° à¤‰à¤œà¤¾à¤²à¤¾ à¤‡à¤¤à¥à¤¯à¤¾à¤¦à¤¿ à¤•à¥‡ à¤µà¤¾à¤°à¥à¤·à¤¿à¤• à¤¸à¤¦à¤¸à¥à¤¯à¤¤à¤¾ à¤ªà¥à¤²à¤¾à¤¨ à¤µ à¤•à¥‰à¤®à¥à¤¬à¥‹ à¤¸à¥à¤•à¥€à¤®à¥¤',
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...schemes.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final sc = entry.value;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                const Color(0xFF0D9488).withOpacity(0.12),
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ),
                          title: Text(
                            sc.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: sc.price > 0
                              ? Text(
                                  'â‚¹${sc.price.toStringAsFixed(0)} / year  â€¢  ${sc.description}',
                                  style: const TextStyle(fontSize: 12),
                                )
                              : (sc.description.isNotEmpty
                                  ? Text(sc.description,
                                      style: const TextStyle(fontSize: 12))
                                  : null),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  foregroundColor: const Color(0xFF1D4ED8),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(
                                      color: Color(0xFFBFDBFE),
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.edit, size: 14),
                                label: Text(
                                  s.tr('Edit', 'बदलें'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                onPressed: () =>
                                    _showAddEditSchemeDialog(existing: sc),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFEF2F2),
                                  foregroundColor: const Color(0xFFDC2626),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(
                                      color: Color(0xFFFECACA),
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.delete_outline,
                                    size: 14),
                                label: Text(
                                  s.tr('Delete', 'हटाएं'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                onPressed: () => _confirmDeleteScheme(sc),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 80),
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


