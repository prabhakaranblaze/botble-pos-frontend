import 'package:flutter/material.dart';
import '../../shared/constants/app_constants.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reports',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildReportCard(
                    'Daily Sales',
                    Icons.calendar_today_rounded,
                    AppColors.primary,
                    () {},
                  ),
                  _buildReportCard(
                    'Session History',
                    Icons.history_rounded,
                    AppColors.secondary,
                    () {},
                  ),
                  _buildReportCard(
                    'Product Sales',
                    Icons.inventory_rounded,
                    AppColors.warning,
                    () {},
                  ),
                  _buildReportCard(
                    'Payment Methods',
                    Icons.payment_rounded,
                    AppColors.success,
                    () {},
                  ),
                  _buildReportCard(
                    'Cash Flow',
                    Icons.account_balance_wallet_rounded,
                    AppColors.error,
                    () {},
                  ),
                  _buildReportCard(
                    'Short/Excess',
                    Icons.compare_arrows_rounded,
                    Colors.purple,
                    () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
