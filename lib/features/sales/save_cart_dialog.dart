import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../sales/sales_provider.dart';
import '../auth/auth_provider.dart';
import '../../shared/constants/app_constants.dart';
import '../../l10n/generated/app_localizations.dart';

class SaveCartDialog extends StatefulWidget {
  const SaveCartDialog({super.key});

  @override
  State<SaveCartDialog> createState() => _SaveCartDialogState();
}

class _SaveCartDialogState extends State<SaveCartDialog> {
  late final TextEditingController _nameController;
  bool _saveOnline = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Auto-generate cart name
    final salesProvider = context.read<SalesProvider>();
    _nameController =
        TextEditingController(text: salesProvider.getAutoCartName());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a cart name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();
    final salesProvider = context.read<SalesProvider>();

    final success = await salesProvider.saveCart(
      name: name,
      userId: authProvider.user!.id,
      userName: authProvider.user!.name,
      saveOnline: _saveOnline,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(salesProvider.error ?? 'Failed to save cart'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.save_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  l10n?.saveCart ?? 'Save Cart',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                ),
              ],
            ),

            const Divider(height: 32),

            // Cart Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n?.cartName ?? 'Cart Name',
                prefixIcon: const Icon(Icons.label_outline),
                hintText: l10n?.enterCartName ?? 'Enter cart name...',
              ),
              enabled: !_isSaving,
              autofocus: true,
            ),

            const SizedBox(height: 16),

            // Save Online Toggle (Phase 2)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.online ?? 'Save to online',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Coming soon - Phase 2',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _saveOnline,
                    onChanged: null, // Disabled for Phase 1
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text(l10n?.cancel ?? 'Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n?.saveCart ?? 'Save Cart',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
