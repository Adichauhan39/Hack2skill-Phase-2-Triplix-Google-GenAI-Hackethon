import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../widgets/user_progress_checkpoint.dart';
import '../providers/user_preferences_provider.dart';

class BudgetPreferencesScreen extends StatefulWidget {
  const BudgetPreferencesScreen({super.key});

  @override
  State<BudgetPreferencesScreen> createState() =>
      _BudgetPreferencesScreenState();
}

class _BudgetPreferencesScreenState extends State<BudgetPreferencesScreen> {
  String _selectedTier = '';
  bool _isTotalBudget = true; // true for Total Budget, false for Per Person
  final TextEditingController _budgetController = TextEditingController();

  final List<Map<String, dynamic>> _budgetTiers = [
    {
      'id': 'budget',
      'title': 'Budget',
      'subtitle': 'Thrift & Explore',
      'icon': Icons.backpack,
      'color': const Color(0xFF4CAF50),
      'description': 'Hostels, street food, local transport',
    },
    {
      'id': 'mid_range',
      'title': 'Mid-range',
      'subtitle': 'Comfort & Value',
      'icon': Icons.hotel,
      'color': const Color(0xFF2196F3),
      'description': '3-star hotels, restaurants, mix of transport',
    },
    {
      'id': 'premium',
      'title': 'Premium',
      'subtitle': 'Quality Experiences',
      'icon': Icons.star,
      'color': const Color(0xFFFF9800),
      'description': '4-star hotels, fine dining, comfortable transport',
    },
    {
      'id': 'luxury',
      'title': 'Luxury',
      'subtitle': 'Indulge & Relax',
      'icon': Icons.diamond,
      'color': const Color(0xFF9C27B0),
      'description': '5-star resorts, premium experiences, private transport',
    },
  ];

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppConfig.primaryGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header with Progress
                  Padding(
                    padding: const EdgeInsets.all(AppConfig.paddingMedium),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Get.back(),
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                            ),
                            const Expanded(
                              child: Text(
                                '2/6',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'What\'s your budget style?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: AppConfig.paddingMedium),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppConfig.paddingMedium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Budget Tier Cards
                            ..._budgetTiers
                                .map((tier) => _buildBudgetTierCard(tier)),
                            const SizedBox(height: 32),

                            // Budget Type Toggle
                            const Text(
                              'Budget Type',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _isTotalBudget = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _isTotalBudget
                                              ? AppConfig.primaryColor
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Total Budget',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _isTotalBudget
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => _isTotalBudget = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        decoration: BoxDecoration(
                                          color: !_isTotalBudget
                                              ? AppConfig.primaryColor
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Per Person',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: !_isTotalBudget
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Budget Input
                            const Text(
                              'Enter Amount',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'INR',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextField(
                                      controller: _budgetController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: '5,000',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Next Button
                  Padding(
                    padding: const EdgeInsets.all(AppConfig.paddingMedium),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppConfig.primaryGradient,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // Save budget to provider
                          final provider = Provider.of<UserPreferencesProvider>(context, listen: false);
                          final budgetValue = double.tryParse(_budgetController.text.replaceAll(',', ''));
                          if (budgetValue != null && budgetValue > 0) {
                            provider.updateBudget(budgetValue);
                          }
                          Get.toNamed('/activities-preferences');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // AI Travel Insights Checkpoint Overlay
          const UserProgressCheckpoint(),
        ],
      ),
    );
  }

  Widget _buildBudgetTierCard(Map<String, dynamic> tier) {
    final bool isSelected = _selectedTier == tier['id'];

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tier['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? tier['color'].withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? tier['color'] : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: tier['color'],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                tier['icon'],
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier['title'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? tier['color'] : Colors.black87,
                    ),
                  ),
                  Text(
                    tier['subtitle'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tier['description'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: tier['color'],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
