import 'dart:math';
import 'package:flutter/material.dart';
import '../providers/delivery_provider.dart';

Future<void> showEditAdminPinDialog({
  required BuildContext context,
  required DeliveryProvider provider,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _EditAdminPinSheet(provider: provider),
  );
}

class _EditAdminPinSheet extends StatefulWidget {
  final DeliveryProvider provider;

  const _EditAdminPinSheet({required this.provider});

  @override
  State<_EditAdminPinSheet> createState() => _EditAdminPinSheetState();
}

class _EditAdminPinSheetState extends State<_EditAdminPinSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _pinCtrl;
  late final TextEditingController _confirmPinCtrl;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

  @override
  void initState() {
    super.initState();
    final owner = widget.provider.ownerUser;
    _nameCtrl = TextEditingController(text: owner.name);
    _phoneCtrl = TextEditingController(text: owner.phone);
    _pinCtrl = TextEditingController(text: owner.pin);
    _confirmPinCtrl = TextEditingController(text: owner.pin);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  String _generateRandomPin() {
    final rnd = Random();
    final code = 1000 + rnd.nextInt(9000);
    return code.toString();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final newPin = _pinCtrl.text.trim();
    final s = widget.provider.strings;

    await widget.provider.updateOwnerProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      newPin: newPin,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF059669),
          content: Text(s.ownerProfileSavedSuccess),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.provider.strings;

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
              // Drag handle
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
                      Icons.admin_panel_settings,
                      color: Color(0xFF1E3A8A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.editAdminProfile,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          s.changeAdminPinSubtitle,
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
              const SizedBox(height: 20),

              // Owner Full Name
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: s.tr('Admin Name', 'मालिक / एडमिन का नाम'),
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return s.tr('Enter admin name', 'एडमिन का नाम दर्ज करें');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Owner Phone
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  counterText: '',
                  labelText: s.tr('Admin Mobile Number', 'एडमिन मोबाइल नंबर'),
                  prefixIcon: const Icon(Icons.phone_outlined),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // New 4-Digit Login PIN
              TextFormField(
                controller: _pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: _obscurePin,
                maxLength: 6,
                decoration: InputDecoration(
                  counterText: '',
                  labelText: s.tr('New 4-Digit Login PIN', 'नया 4 अंकों का लॉगिन पिन'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePin ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
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
                    return s.isHindi ? 'पिन कम से कम 4 अंकों का होना चाहिए' : 'PIN must be at least 4 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),

              // Auto Generate PIN helper
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
                    final newCode = _generateRandomPin();
                    setState(() {
                      _pinCtrl.text = newCode;
                      _confirmPinCtrl.text = newCode;
                    });
                  },
                ),
              ),

              // Confirm New PIN
              TextFormField(
                controller: _confirmPinCtrl,
                keyboardType: TextInputType.number,
                obscureText: _obscureConfirmPin,
                maxLength: 6,
                decoration: InputDecoration(
                  counterText: '',
                  labelText: s.tr('Confirm Login PIN', 'लॉगिन पिन की पुष्टि करें'),
                  prefixIcon: const Icon(Icons.check_circle_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPin ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPin = !_obscureConfirmPin;
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
                  if (val == null || val.trim() != _pinCtrl.text.trim()) {
                    return s.isHindi ? 'पिन मेल नहीं खाता' : 'PINs do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Save Button
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
                  s.tr('Save New Admin PIN', 'नया एडमिन पिन सहेजें'),
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
