// widgets/common/loading_skeleton.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';

/// Widget base del skeleton con shimmer.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.line,
      highlightColor: AppColors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.line,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Skeleton para la card horizontal de complejos en el mapa.
class CanchaCardSkeleton extends StatelessWidget {
  const CanchaCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(height: 110, radius: 12),
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14, width: 120),
                SizedBox(height: 6),
                SkeletonBox(height: 11, width: 80),
                SizedBox(height: 8),
                Row(
                  children: [
                    SkeletonBox(height: 24, width: 60, radius: 6),
                    SizedBox(width: 8),
                    SkeletonBox(height: 24, width: 50, radius: 6),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton para la lista de reservas.
class ReservaListSkeleton extends StatelessWidget {
  const ReservaListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkeletonBox(height: 14, width: 100),
                    Spacer(),
                    SkeletonBox(height: 22, width: 80, radius: 11),
                  ],
                ),
                SizedBox(height: 8),
                SkeletonBox(height: 16, width: 160),
                SizedBox(height: 6),
                SkeletonBox(height: 12, width: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton de lista de partidos.
class PartidoCardSkeleton extends StatelessWidget {
  const PartidoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(height: 40, width: 40, radius: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14, width: 140),
                    SizedBox(height: 5),
                    SkeletonBox(height: 11, width: 90),
                  ],
                ),
              ),
              SkeletonBox(height: 32, width: 80, radius: 10),
            ],
          ),
          SizedBox(height: 12),
          SkeletonBox(height: 8, radius: 4),
        ],
      ),
    );
  }
}

/// Skeleton de grid horarios (admin).
class HorarioGridSkeleton extends StatelessWidget {
  const HorarioGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (row) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            children: [
              const SkeletonBox(height: 12, width: 40),
              const SizedBox(width: 8),
              ...List.generate(
                4,
                (col) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: const SkeletonBox(height: 48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
