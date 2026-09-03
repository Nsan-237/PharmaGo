import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton / Shimmer Loading Widget
// Used on Home pharmacy cards and Search Results while mock data "loads"
// ─────────────────────────────────────────────────────────────────────────────

/// A single skeleton block that pulses (opacity animation) to indicate loading.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

/// A skeleton card shaped like a pharmacy list item on the Home/Search screens.
class SkeletonPharmacyCard extends StatelessWidget {
  const SkeletonPharmacyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          // Icon placeholder
          SkeletonBox(width: 48, height: 48, borderRadius: 12),
          SizedBox(width: 14),

          // Text placeholders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 14, borderRadius: 6),
                SizedBox(height: 8),
                SkeletonBox(width: 100, height: 10, borderRadius: 6),
                SizedBox(height: 6),
                SkeletonBox(width: 80, height: 10, borderRadius: 6),
              ],
            ),
          ),

          SizedBox(width: 12),
          // Button placeholder
          SkeletonBox(width: 72, height: 32, borderRadius: 10),
        ],
      ),
    );
  }
}

/// A full skeleton list of N pharmacy cards.
class SkeletonPharmacyList extends StatelessWidget {
  final int count;

  const SkeletonPharmacyList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const SkeletonPharmacyCard(),
    );
  }
}
