import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_endpoints.dart';
import '../core/constants/app_colors.dart';
import '../data/local/database_helper.dart';
import '../widgets/government_header.dart';

// =====================================================================
// DRISHTI Mobile App: System & Network Settings Screen
// Configures API endpoints and runs health checks against FastAPI
// =====================================================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController(text: ApiEndpoints.baseUrl);
  String? _healthResult;
  bool _isTesting = false;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final count = await DatabaseHelper.instance.getPendingSyncCount();
    if (mounted) setState(() => _pendingCount = count);
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _healthResult = null;
    });

    final targetUrl = _urlController.text.trim();
    await ApiEndpoints.saveBaseUrl(targetUrl);

    try {
      final stopwatch = Stopwatch()..start();
      final res = await http.get(Uri.parse(ApiEndpoints.health)).timeout(const Duration(seconds: 6));
      stopwatch.stop();

      setState(() {
        _isTesting = false;
        if (res.statusCode == 200) {
          _healthResult = 'CONNECTED: HTTP 200 OK (${stopwatch.elapsedMilliseconds}ms)\n${res.body}';
        } else {
          _healthResult = 'SERVER ERROR: HTTP ${res.statusCode}\n${res.body}';
        }
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _healthResult = 'CONNECTION FAILED: $e\nEnsure FastAPI backend is running on the specified host & port.';
      });
    }
  }

  Future<void> _saveUrl() async {
    final targetUrl = _urlController.text.trim();
    await ApiEndpoints.saveBaseUrl(targetUrl);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved backend URL: ${ApiEndpoints.baseUrl}'),
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const GovernmentHeader(subtitle: 'Configuration & Network Diagnostics'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Backend Endpoint Configuration Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DRISHTI FastAPI Backend URL',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Set the base address of the DRISHTI REST service on port 8001.',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            labelText: 'Base URL',
                            hintText: 'http://10.244.88.171:8001 or http://10.0.2.2:8001',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.link, size: 20),
                          ),
                          onChanged: (val) {
                            ApiEndpoints.setBaseUrl(val);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Quick Presets
                        const Text(
                          'Quick Network Presets:',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.phone_android, size: 15, color: AppColors.primaryNavy),
                              label: const Text('Physical Phone (10.244.88.171:8001)', style: TextStyle(fontSize: 11)),
                              onPressed: () async {
                                _urlController.text = ApiEndpoints.defaultPhysicalLanUrl;
                                await ApiEndpoints.saveBaseUrl(ApiEndpoints.defaultPhysicalLanUrl);
                                setState(() {});
                              },
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.devices, size: 15, color: AppColors.primaryNavy),
                              label: const Text('Android Emulator (10.0.2.2:8001)', style: TextStyle(fontSize: 11)),
                              onPressed: () async {
                                _urlController.text = ApiEndpoints.defaultEmulatorUrl;
                                await ApiEndpoints.saveBaseUrl(ApiEndpoints.defaultEmulatorUrl);
                                setState(() {});
                              },
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.computer, size: 15, color: AppColors.primaryNavy),
                              label: const Text('Localhost PC (127.0.0.1:8001)', style: TextStyle(fontSize: 11)),
                              onPressed: () async {
                                _urlController.text = ApiEndpoints.defaultLocalhostUrl;
                                await ApiEndpoints.saveBaseUrl(ApiEndpoints.defaultLocalhostUrl);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: _isTesting ? null : _testConnection,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryNavy,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: _isTesting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.network_check, size: 18),
                                label: const Text('TEST CONNECTION', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: OutlinedButton.icon(
                                onPressed: _saveUrl,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  foregroundColor: AppColors.primaryNavy,
                                ),
                                icon: const Icon(Icons.save, size: 18),
                                label: const Text('SAVE', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),

                        if (_healthResult != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _healthResult!.startsWith('CONNECTED')
                                  ? AppColors.statusSuccessBg
                                  : AppColors.statusCriticalBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _healthResult!.startsWith('CONNECTED')
                                    ? AppColors.statusSuccess
                                    : AppColors.statusCritical,
                              ),
                            ),
                            child: Text(
                              _healthResult!,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: _healthResult!.startsWith('CONNECTED')
                                    ? AppColors.statusSuccess
                                    : AppColors.statusCritical,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Local SQLite Persistence Stats Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Local Offline SQLite Database',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        _buildStatRow('Database File', 'drishti_inspector_local.db'),
                        _buildStatRow('Schema Version', '2.0 (MoSJE Compliant)'),
                        _buildStatRow('Pending Outbox Syncs', '$_pendingCount items'),
                        _buildStatRow('Tamper-Resistant Algorithm', 'SHA-256 (64-char Hex)'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
