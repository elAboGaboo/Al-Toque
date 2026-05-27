import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/map_provider.dart';

class MapFilterBar extends ConsumerWidget {
  const MapFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(mapFilterProvider);

    final filters = [
      (MapFilter.todos, 'Todos', null),
      (MapFilter.flash, '⚡ Flash', AppColors.flash),
      (MapFilter.partidos, '👥 Partidos', AppColors.party),
      (MapFilter.disponibles, 'Disponibles', AppColors.green),
      (MapFilter.futbol5, 'Fútbol 5', null),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (filter, label, color) = filters[i];
          final isSelected = current == filter;
          return GestureDetector(
            onTap: () => ref.read(mapFilterProvider.notifier).setFilter(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? (color ?? AppColors.ink)
                    : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? (color ?? AppColors.ink)
                      : AppColors.line,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (color ?? AppColors.ink)
                              .withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.white : AppColors.ink,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
