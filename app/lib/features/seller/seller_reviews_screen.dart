import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';

class SellerReviewsScreen extends StatelessWidget {
  const SellerReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    '4.8',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (index) => HugeIcon(
                              icon: HugeIcons.strokeRoundedStar,
                              size: 16,
                              color: index < 4 ? AppColors.warning : AppColors.border,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Based on 128 reviews',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Reviews from Hotel Owners',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildReviewCard(
              hotelName: 'Taj West End',
              ownerName: 'Vikram Singh',
              rating: 5,
              date: '2 days ago',
              review: 'Excellent quality tomatoes! Fresh Harvest Farms never disappoints. The grade A produce is perfect for our salads.',
            ),
            const SizedBox(height: 16),
            _buildReviewCard(
              hotelName: 'ITC Gardenia',
              ownerName: 'Priya Sharma',
              rating: 4,
              date: '1 week ago',
              review: 'Good quality and prompt delivery. We have been sourcing onions and potatoes from Ramesh for a few months now.',
            ),
            const SizedBox(height: 16),
            _buildReviewCard(
              hotelName: 'The Leela Palace',
              ownerName: 'Chef Rahul',
              rating: 5,
              date: '2 weeks ago',
              review: 'The best organic carrots we have received this season. Highly recommend this seller for premium quality produce.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard({
    required String hotelName,
    required String ownerName,
    required int rating,
    required String date,
    required String review,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    hotelName[0],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF27AE60),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotelName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ownerName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              5,
              (index) => HugeIcon(
                icon: HugeIcons.strokeRoundedStar,
                size: 14,
                color: index < rating ? AppColors.warning : AppColors.border,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            review,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
