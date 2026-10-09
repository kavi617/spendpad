import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../services/backup_service.dart';
import '../services/settings_service.dart';
import '../utils/app_format.dart';
import 'category_screen.dart';
import 'about_screen.dart';
import '../widgets/export_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------------------
  // Export / import
  // ---------------------------------------------------------------------------

  Future<void> _openExportSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ExportSheet(),
    );
  }

  Future<void> _exportJsonBackup() async {
    try {
      final expenses = await DatabaseService.getExpenses();
      await BackupService.exportExpensesBackup(expenses);
      if (!mounted) return;
      _showMessage('Backup exported successfully');
    } catch (e) {
      _showMessage('Export failed: $e');
    }
  }

  Future<void> _restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
          'Expenses from the backup file will be added to your data. '
          'Existing entries with the same ID are kept as they are.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final imported = await BackupService.pickBackupFile();
      if (imported == null) return;

      final box = await DatabaseService.openExpenseBox();
      var added = 0;
      var skipped = 0;
      for (final expense in imported) {
        if (box.containsKey(expense.id)) {
          skipped++;
          continue;
        }
        await DatabaseService.addExpense(expense);
        added++;
      }

      if (!mounted) return;
      _showMessage(
        skipped == 0
            ? 'Restored $added expenses'
            : 'Restored $added expenses, skipped $skipped duplicates',
      );
    } catch (e) {
      _showMessage('Restore failed: $e');
    }
  }

  Future<void> _clearAllExpenses() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all expenses?'),
        content: const Text(
          'This permanently removes every expense on this device. '
          'This cannot be undone — consider exporting a backup first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE5533C),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final box = await DatabaseService.openExpenseBox();
      await box.clear();
      if (!mounted) return;
      _showMessage('All expenses deleted');
    } catch (e) {
      _showMessage('Clear failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Currency
  // ---------------------------------------------------------------------------

  static const _currencies = ['₹', '\$', '€', '£', '¥', '₩', '﷼', '₦'];

  Future<void> _pickCurrency() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Currency symbol',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in _currencies)
                    ChoiceChip(
                      label: Text(c, style: const TextStyle(fontSize: 16)),
                      selected: AppFormat.symbol == c,
                      onSelected: (_) => Navigator.pop(context, c),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null || selected == AppFormat.symbol) return;

    await SettingsService.setValue('currency', selected);
    setState(() => AppFormat.symbol = selected);
    if (!mounted) return;
    _showMessage('Currency set to $selected');
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
        children: [
          _sectionLabel('Data & backup'),
          const SizedBox(height: 8),
          _groupCard(
            scheme,
            tiles: [
              _tile(
                icon: Icons.ios_share_rounded,
                title: 'Export expenses',
                subtitle: 'CSV with a period filter — month, year or custom',
                onTap: _openExportSheet,
              ),
              _divider(scheme),
              _tile(
                icon: Icons.backup_rounded,
                title: 'Export backup',
                subtitle: 'Full JSON backup of all your data',
                onTap: _exportJsonBackup,
              ),
              _divider(scheme),
              _tile(
                icon: Icons.restore_rounded,
                title: 'Restore backup',
                subtitle: 'Import expenses from a JSON backup file',
                onTap: _restoreBackup,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionLabel('Preferences'),
          const SizedBox(height: 8),
          _groupCard(
            scheme,
            tiles: [
              _tile(
                icon: Icons.currency_exchange_rounded,
                title: 'Currency',
                subtitle: 'Currently ${AppFormat.symbol}',
                trailing: Text(
                  AppFormat.symbol,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                onTap: _pickCurrency,
              ),
              _divider(scheme),
              _tile(
                icon: Icons.category_rounded,
                title: 'Manage categories',
                subtitle: 'Add, rename or remove spending categories',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoryScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionLabel('Danger zone'),
          const SizedBox(height: 8),
          _groupCard(
            scheme,
            tiles: [
              _tile(
                icon: Icons.delete_forever_rounded,
                title: 'Delete all expenses',
                subtitle: 'Permanently erase everything on this device',
                titleColor: const Color(0xFFE5533C),
                onTap: _clearAllExpenses,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionLabel('About'),
          const SizedBox(height: 8),
          _groupCard(
            scheme,
            tiles: [
              _tile(
                icon: Icons.savings_rounded,
                title: 'About SpendPad',
                subtitle: 'Why this app exists, and how it works',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _groupCard(ColorScheme scheme, {required List<Widget> tiles}) {
    return Card(child: Column(children: tiles));
  }

  Widget _divider(ColorScheme scheme) =>
      Divider(indent: 56, color: scheme.outlineVariant.withValues(alpha: 0.5));

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: scheme.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: titleColor ?? scheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 22),
    );
  }
}
