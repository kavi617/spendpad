import 'package:flutter/material.dart';

import '../utils/app_format.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [scheme.primary, scheme.primary.withValues(alpha: 0.7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.savings_rounded,
                size: 42,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'SpendPad',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why SpendPad exists',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Most people don\'t overspend on purpose — they overspend '
                    'because they can\'t see where the money goes. SpendPad is a '
                    'simple, quiet place to record what you spend, and it turns '
                    'those small entries into clear charts, patterns and '
                    'suggestions.\n\nNo accounts, no ads, no clutter. Just a '
                    'faster way from “where did my money go?” to “now I know”.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _feature(
            scheme,
            Icons.add_circle_rounded,
            'Effortless tracking',
            'Add an expense in seconds — amount, category, done.',
          ),
          _feature(
            scheme,
            Icons.insights_rounded,
            'Insights, not spreadsheets',
            'Auto-generated summaries show what changed and what to watch.',
          ),
          _feature(
            scheme,
            Icons.category_rounded,
            'Smart categories',
            'Categories pick their own icons and colors — easy to scan.',
          ),
          _feature(
            scheme,
            Icons.ios_share_rounded,
            'Own your data',
            'Export to CSV, Excel or JSON anytime. No lock-in.',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_rounded, size: 20, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Private by design — every expense lives only on this '
                    'device. Nothing is uploaded, ever.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: scheme.onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              'Made by Kavinayan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Made for calm, conscious spending.',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ),
          Center(
            child: Text(
              'Currency: ${AppFormat.symbol} · Change it in Settings',
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feature(
    ColorScheme scheme,
    IconData icon,
    String title,
    String body,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
