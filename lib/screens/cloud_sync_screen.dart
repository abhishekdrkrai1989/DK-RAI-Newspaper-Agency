import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../providers/delivery_provider.dart';
import '../services/cloud_sync_service.dart';

class CloudSyncScreen extends StatefulWidget {
  final DeliveryProvider provider;

  const CloudSyncScreen({super.key, required this.provider});

  @override
  State<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends State<CloudSyncScreen> {
  late final TextEditingController _urlController;
  late final TextEditingController _keyController;
  late bool _autoSync;
  bool _obscureKey = true;
  bool _testingConnection = false;
  String? _testResultText;
  bool? _testResultSuccess;

  @override
  void initState() {
    super.initState();
    final p = widget.provider;
    _urlController = TextEditingController(text: p.supabaseUrl);
    _keyController = TextEditingController(text: p.supabaseAnonKey);
    _autoSync = p.autoSync;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection(AppStrings s) async {
    setState(() {
      _testingConnection = true;
      _testResultText = null;
      _testResultSuccess = null;
    });

    final res = await widget.provider.testCloudConnection(
      _urlController.text.trim(),
      _keyController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _testingConnection = false;
        _testResultSuccess = res.success;
        _testResultText = res.message;
      });
    }
  }

  Future<void> _saveConfig(AppStrings s) async {
    await widget.provider.saveCloudConfig(
      url: _urlController.text.trim(),
      anonKey: _keyController.text.trim(),
      autoSync: _autoSync,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.saveConfigBtn),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  Future<void> _copySqlScript(AppStrings s) async {
    await Clipboard.setData(
      ClipboardData(text: CloudSyncService.sqlSetupScript),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.sqlCopiedMsg),
          backgroundColor: Colors.indigo.shade700,
          duration: const Duration(seconds: 4),
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
        final isConfigured = p.isCloudConfigured;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6FB),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.cloudSyncTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isConfigured ? s.cloudStatusConnected : s.cloudStatusOffline,
                  style: TextStyle(
                    fontSize: 11,
                    color: isConfigured ? Colors.greenAccent : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Connection Status Card
                _buildStatusCard(p, s),

                const SizedBox(height: 16),

                // 2. Sync Actions Card
                _buildSyncActionsCard(p, s),

                const SizedBox(height: 16),

                // 3. Supabase Credentials Configuration Card
                _buildCredentialsCard(p, s),

                const SizedBox(height: 16),

                // 4. Free Supabase 1-Minute Setup Guide & SQL Schema
                _buildSetupGuideCard(s),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(DeliveryProvider p, AppStrings s) {
    final isConfigured = p.isCloudConfigured;
    final isSyncing = p.isSyncing;
    final lastSync = p.lastSyncTime;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSyncing
                        ? Colors.amber.shade100
                        : (isConfigured
                            ? Colors.green.shade100
                            : Colors.grey.shade200),
                    shape: BoxShape.circle,
                  ),
                  child: isSyncing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Icon(
                          isConfigured ? Icons.cloud_done : Icons.cloud_off,
                          color: isConfigured
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSyncing
                            ? s.cloudStatusSyncing
                            : (isConfigured
                                ? s.cloudStatusConnected
                                : s.cloudStatusOffline),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastSync != null
                            ? '${s.lastSyncedLabel}: ${s.formatDate(lastSync)} ${lastSync.hour.toString().padLeft(2, '0')}:${lastSync.minute.toString().padLeft(2, '0')}'
                            : '${s.lastSyncedLabel}: ${s.neverSynced}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (p.lastSyncMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: p.lastSyncSuccess
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: p.lastSyncSuccess
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                ),
                child: Text(
                  p.lastSyncMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: p.lastSyncSuccess
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.isHindi
                          ? 'ऑटो-सिंक सक्रिय: हर बदलाव (डिलीवरी, चालू/बंद, ग्राहक, हॉकर) अपने आप तुरंत बैकएंड (Supabase) में सहेजा जाता है।'
                          : 'Real-Time Auto-Sync: Every action (deliveries, pauses, customers, hawkers) is automatically saved to Supabase in the background.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1E40AF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncActionsCard(DeliveryProvider p, AppStrings s) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sync & Backup Operations',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Homes: ${p.allCustomers.length} | Publications: ${p.publications.length}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            // Primary Two-Way Sync
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: p.isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.sync),
                label: Text(
                  s.syncNowBtn,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: p.isSyncing || !p.isCloudConfigured
                    ? null
                    : () => p.syncWithCloud(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo.shade800,
                      side: BorderSide(color: Colors.indigo.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: Text(
                      s.uploadToCloudBtn,
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                    onPressed: p.isSyncing || !p.isCloudConfigured
                        ? null
                        : () => p.syncWithCloud(forceUpload: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal.shade800,
                      side: BorderSide(color: Colors.teal.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.cloud_download_outlined, size: 18),
                    label: Text(
                      s.downloadFromCloudBtn,
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                    onPressed: p.isSyncing || !p.isCloudConfigured
                        ? null
                        : () => p.syncWithCloud(forceDownload: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsCard(DeliveryProvider p, AppStrings s) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                const Text(
                  'Supabase Project Credentials',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: s.supabaseProjectUrl,
                hintText: s.supabaseProjectUrlHint,
                prefixIcon: const Icon(Icons.link),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _keyController,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                labelText: s.supabaseAnonKey,
                hintText: s.supabaseAnonKeyHint,
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKey ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                s.autoSyncLabel,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Automatically pushes delivery updates and pauses to cloud',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              value: _autoSync,
              onChanged: (val) => setState(() => _autoSync = val),
            ),
            if (_testResultText != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _testResultSuccess == true
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testResultSuccess == true
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                ),
                child: Text(
                  _testResultText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _testResultSuccess == true
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: _testingConnection
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.electrical_services, size: 16),
                    label: Text(s.testConnectionBtn),
                    onPressed: _testingConnection ? null : () => _testConnection(s),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.save, size: 16),
                    label: Text(s.saveConfigBtn),
                    onPressed: () => _saveConfig(s),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupGuideCard(AppStrings s) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.sqlSetupTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _guideStep(
              '1',
              'Create a Free Project',
              'Go to https://supabase.com and create a project. Supabase is 100% free with 500MB PostgreSQL storage and requires no credit card.',
            ),
            const SizedBox(height: 8),
            _guideStep(
              '2',
              'Run the SQL Script',
              'Open Supabase SQL Editor on the left sidebar, paste the table schema below, and click Run. It creates the "customers" & "publications" tables with RLS policies.',
            ),
            const SizedBox(height: 8),
            _guideStep(
              '3',
              'Copy URL & Anon Key',
              'Go to Project Settings > API, copy the "Project URL" and "anon public" key, and paste them in the fields above.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.copy, size: 16),
                label: Text(s.copySqlSchemaBtn),
                onPressed: () => _copySqlScript(s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideStep(String num, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: Colors.indigo.shade100,
          child: Text(
            num,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: const TextStyle(fontSize: 11, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
