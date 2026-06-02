import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Filtro activo del mapa ─────────────────────────────────

enum MapFilter { todos, flash, partidos, disponibles, futbol5 }

class MapFilterNotifier extends Notifier<MapFilter> {
  @override
  MapFilter build() => MapFilter.todos;

  void setFilter(MapFilter filter) => state = filter;
}

final mapFilterProvider = NotifierProvider<MapFilterNotifier, MapFilter>(
  MapFilterNotifier.new,
);
