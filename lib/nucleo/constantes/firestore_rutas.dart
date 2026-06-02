// nucleo/constantes/firestore_rutas.dart
class FirestorePaths {
  FirestorePaths._();

  // ── Colecciones raíz ──────────────────────────────────────────
  static const String complejos      = 'complejos';
  static const String reservas       = 'reservas';
  static const String flashSlots     = 'flashSlots';
  static const String partidos       = 'partidos';
  static const String usuarios       = 'usuarios';
  static const String prediccionesIA = 'prediccionesIA';
  static const String resenas        = 'resenas';
  static const String pagos          = 'pagos';
  static const String notificaciones = 'notificaciones';
  static const String chats          = 'chats';
  static const String reportes       = 'reportes';
  static const String admins         = 'admins';

  // ── Documentos raíz ──────────────────────────────────────────
  static String complejoDoc(String complejoId)     => '$complejos/$complejoId';
  static String reservaDoc(String reservaId)       => '$reservas/$reservaId';
  static String flashSlotDoc(String slotId)        => '$flashSlots/$slotId';
  static String partidoDoc(String partidoId)       => '$partidos/$partidoId';
  static String usuarioDoc(String uid)             => '$usuarios/$uid';
  static String prediccionDoc(String predId)       => '$prediccionesIA/$predId';
  static String resenaDoc(String resenaId)         => '$resenas/$resenaId';
  static String pagoDoc(String pagoId)             => '$pagos/$pagoId';
  static String notificacionDoc(String notifId)    => '$notificaciones/$notifId';
  static String chatDoc(String chatId)             => '$chats/$chatId';
  static String reporteDoc(String reporteId)       => '$reportes/$reporteId';
  static String adminDoc(String adminId)           => '$admins/$adminId';

  // ── Sub-colecciones ───────────────────────────────────────────
  static String canchas(String complejoId) =>
      '$complejos/$complejoId/canchas';

  static String canchaDoc(String complejoId, String canchaId) =>
      '$complejos/$complejoId/canchas/$canchaId';

  static String mensajes(String chatId) =>
      '$chats/$chatId/mensajes';
}
