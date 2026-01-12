import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../shared/constants/app_constants.dart';
import '../../core/services/update_service.dart';
import '../../core/providers/update_provider.dart';
import '../auth/auth_provider.dart';
import '../../core/models/user.dart';
import '../../l10n/generated/app_localizations.dart';
import 'printer_settings_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final hasSettingsPermission = user?.hasPermission(PosPermissions.posSettings) ??
                                   user?.isSuperUser ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.settings ?? 'Settings',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Two column layout: Printer Settings | Receipt Preview
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Printer Settings
                Expanded(
                  flex: 3,
                  child: _buildSection(
                    title: l10n?.printerSettings ?? 'Printer Settings',
                    icon: Icons.print,
                    child: const PrinterSettingsCard(),
                  ),
                ),
                const SizedBox(width: 24),
                // Right column - Receipt Preview
                Expanded(
                  flex: 2,
                  child: _buildSection(
                    title: l10n?.receiptPreview ?? 'Receipt Preview',
                    icon: Icons.receipt_long,
                    child: const ReceiptPreviewCard(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Updates & About section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Updates
                Expanded(
                  child: _buildUpdateSection(),
                ),
                const SizedBox(width: 24),
                // About
                Expanded(
                  child: _buildSection(
                    title: l10n?.about ?? 'About',
                    icon: Icons.info_outline,
                    child: _buildAboutCard(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildUpdateSection() {
    final l10n = AppLocalizations.of(context);
    return Consumer<UpdateProvider>(
      builder: (context, updateProvider, child) {
        final hasUpdate = updateProvider.hasUpdate;
        final updateInfo = updateProvider.updateInfo;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.system_update, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n?.softwareUpdate ?? 'Software Update',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Show NEW badge only on desktop when update available
                if (hasUpdate && !kIsWeb) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n?.newBadge ?? 'NEW',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current version info
                    Row(
                      children: [
                        Icon(
                          kIsWeb ? Icons.info_outline : (hasUpdate ? Icons.update : Icons.check_circle),
                          color: kIsWeb ? AppColors.primary : (hasUpdate ? AppColors.warning : AppColors.success),
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                kIsWeb
                                    ? (l10n?.version ?? 'Version')
                                    : (hasUpdate ? (l10n?.updateAvailable ?? 'Update Available') : (l10n?.appUpToDate ?? 'App is up to date')),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                kIsWeb
                                    ? 'v${UpdateService.appVersion}'
                                    : '${l10n?.currentVersionLabel ?? 'Current:'} v${UpdateService.appVersion}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              // Show latest version only on desktop
                              if (!kIsWeb && hasUpdate && updateInfo != null)
                                Text(
                                  '${l10n?.latestVersionLabel ?? 'Latest:'} v${updateInfo.latestVersion}',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Check/Download button (desktop only)
                        if (!kIsWeb) ...[
                          if (updateProvider.isChecking)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (updateProvider.isDownloading)
                            Column(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: LinearProgressIndicator(
                                    value: updateProvider.downloadProgress,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(updateProvider.downloadProgress * 100).toInt()}%',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            )
                          else if (hasUpdate)
                            ElevatedButton.icon(
                              onPressed: () => _downloadAndInstallUpdate(updateProvider),
                              icon: const Icon(Icons.download, size: 18),
                              label: Text(l10n?.update ?? 'Update'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                              ),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: () => updateProvider.checkForUpdate(),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: Text(l10n?.check ?? 'Check'),
                            ),
                        ],
                      ],
                    ),

                    // Release notes (desktop only)
                    if (!kIsWeb && hasUpdate && updateInfo != null && updateInfo.releaseNotes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        l10n?.whatsNew ?? 'What\'s New:',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...updateInfo.releaseNotes.map((note) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ', style: TextStyle(color: AppColors.textSecondary)),
                                Expanded(
                                  child: Text(
                                    note,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      if (updateInfo.fileSize != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${l10n?.downloadSize ?? 'Download size:'} ${updateInfo.fileSize}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadAndInstallUpdate(UpdateProvider updateProvider) async {
    final l10n = AppLocalizations.of(context);
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(l10n?.installUpdateTitle ?? 'Install Update'),
          ],
        ),
        content: Text(
          l10n?.downloadAndInstallConfirm(updateProvider.updateInfo?.latestVersion ?? '') ??
          'Download and install version ${updateProvider.updateInfo?.latestVersion}?\n\n'
          'The app will restart after installation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text(l10n?.updateNow ?? 'Update Now'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Download update
    final success = await updateProvider.downloadUpdate();

    if (success && mounted) {
      // Install update
      await updateProvider.installUpdate();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updateProvider.error ?? 'Download failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildAboutCard() {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(l10n?.appTitle ?? 'App Name', AppConstants.appName),
            const Divider(),
            _buildInfoRow(l10n?.version ?? 'Version', UpdateService.appVersion),
            const Divider(),
            _buildInfoRow(l10n?.currency ?? 'Currency', AppConstants.currencyCode),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

}

// PrinterSettingsCard is now loaded conditionally from printer_settings_widget.dart
// Desktop: Uses flutter_thermal_printer
// Web: Uses Web Serial API

/// Receipt Preview Card - Shows thermal receipt with demo data
class ReceiptPreviewCard extends StatefulWidget {
  const ReceiptPreviewCard({super.key});

  @override
  State<ReceiptPreviewCard> createState() => _ReceiptPreviewCardState();
}

class _ReceiptPreviewCardState extends State<ReceiptPreviewCard> {
  String _paymentType = 'cash'; // 'cash' or 'card'

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment type toggle
            Row(
              children: [
                Text('${l10n?.demoPayment ?? 'Demo Payment'}: ', style: const TextStyle(fontSize: 12)),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'cash', label: Text(l10n?.cash ?? 'Cash')),
                    ButtonSegment(value: 'card', label: Text(l10n?.card ?? 'Card')),
                  ],
                  selected: {_paymentType},
                  onSelectionChanged: (types) {
                    setState(() => _paymentType = types.first);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Receipt preview (thermal paper style)
            Center(
              child: Container(
                width: 280, // 58mm paper width at ~screen DPI
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildReceiptContent(),
              ),
            ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                l10n?.thermalPaperPreview ?? '58mm Thermal Paper Preview',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptContent() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final now = DateTime.now();
    final isCash = _paymentType == 'cash';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'Courier',
          fontSize: 11,
          color: Colors.black,
          height: 1.3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            Text(
              AppConstants.appName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Text('POS Receipt'),
            const SizedBox(height: 8),

            // Order info
            _receiptLine('Order: #ORD-00123'),
            _receiptLine('Date: ${dateFormat.format(now)}'),
            _receiptLine('Customer: John Doe'),
            _receiptLine(isCash ? 'Payment: Cash' : 'Payment: Card (*4242)'),

            const SizedBox(height: 4),
            _divider(),
            const SizedBox(height: 4),

            // Column headers
            _itemRow('Item', 'Qty', 'Amount', bold: true),
            _divider(),
            const SizedBox(height: 2),

            // Demo items
            _itemRow('Organic Coffee Beans', '2', '${AppConstants.currencyCode} 45.00'),
            _itemRow('Fresh Milk 1L', '1', '${AppConstants.currencyCode} 12.50'),
            _itemRow('Whole Wheat Bread', '1', '${AppConstants.currencyCode} 8.00'),

            const SizedBox(height: 4),
            _divider(),
            const SizedBox(height: 4),

            // Totals
            _totalRow('Subtotal:', '${AppConstants.currencyCode} 65.50'),
            _totalRow('Tax (15%):', '${AppConstants.currencyCode} 9.83'),
            _totalRow('Discount:', '-${AppConstants.currencyCode} 5.00'),

            _divider(),

            // Grand total
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    '${AppConstants.currencyCode} 70.33',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Cash payment details
            if (isCash) ...[
              const SizedBox(height: 2),
              _totalRow('Cash:', '${AppConstants.currencyCode} 100.00'),
              _totalRow('Change:', '${AppConstants.currencyCode} 29.67'),
            ],

            const SizedBox(height: 8),
            _divider(),
            const SizedBox(height: 8),

            // Footer
            const Text(
              'Thank you for your purchase!',
              textAlign: TextAlign.center,
            ),
            const Text(
              'Please come again',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _receiptLine(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text),
    );
  }

  Widget _divider() {
    return const Text(
      '--------------------------------',
      style: TextStyle(letterSpacing: -1),
    );
  }

  Widget _itemRow(String name, String qty, String amount, {bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    // Truncate long names
    final displayName = name.length > 18 ? '${name.substring(0, 18)}' : name;

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(displayName, style: style),
        ),
        SizedBox(
          width: 30,
          child: Text(qty, textAlign: TextAlign.center, style: style),
        ),
        Expanded(
          flex: 3,
          child: Text(amount, textAlign: TextAlign.right, style: style),
        ),
      ],
    );
  }

  Widget _totalRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(amount),
        ],
      ),
    );
  }
}
