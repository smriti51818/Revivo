import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';

class SellerDocumentsScreen extends StatelessWidget {
  const SellerDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Identity & Business Verification',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Upload your documents to become a verified seller.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _buildDocumentCard(
              title: 'Aadhaar Card',
              status: 'Verified',
              statusColor: const Color(0xFF27AE60),
              icon: HugeIcons.strokeRoundedCheckmarkBadge01,
            ),
            const SizedBox(height: 16),
            _buildDocumentCard(
              title: 'FSSAI License',
              status: 'Pending',
              statusColor: AppColors.warning,
              icon: HugeIcons.strokeRoundedTime01,
            ),
            const SizedBox(height: 16),
            _buildDocumentCard(
              title: 'GST Certificate (Optional)',
              status: 'Not Uploaded',
              statusColor: AppColors.textMuted,
              icon: HugeIcons.strokeRoundedInformationCircle,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: Color(0xFF27AE60)),
              ),
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedCloudUpload, size: 20, color: Color(0xFF27AE60)),
              label: const Text(
                'Upload New Document',
                style: TextStyle(color: Color(0xFF27AE60), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String status,
    required Color statusColor,
    required dynamic icon,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F7F5),
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(icon: HugeIcons.strokeRoundedNote01, size: 20, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    HugeIcon(icon: icon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedMoreVerticalCircle01, size: 20, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
