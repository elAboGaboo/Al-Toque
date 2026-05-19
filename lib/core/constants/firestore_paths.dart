// core/constants/firestore_paths.dart
class FirestorePaths {
  FirestorePaths._();

  // Colecciones raíz
  static const String complejos = 'complejos';
  static const String reservas = 'reservas';
  static const String flashSlots = 'flashSlots';
  static const String partidos = 'partidos';
  static const String usuarios = 'usuarios';
  static const String prediccionesIA = 'prediccionesIA';
  static const String resenas = 'resenas';

  // Sub-colecciones
  static String canchas(String complejoId) =>
      '$complejos/$complejoId/canchas';

  static String canchaDoc(String complejoId, String canchaId) =>
      '$complejos/$complejoId/canchas/$canchaId';

  static String complejoDoc(String complejoId) =>
      '$complejos/$complejoId';

  static String reservaDoc(String reservaId) =>
      '$reservas/$reservaId';

  static String flashSlotDoc(String slotId) =>
      '$flashSlots/$slotId';

  static String partidoDoc(String partidoId) =>
      '$partidos/$partidoId';

  static String usuarioDoc(String uid) =>
      '$usuarios/$uid';

  static String resenaDoc(String resenaId) =>
      '$resenas/$resenaId';
}
