// core/services/database_seeder.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../repositories/usuarios_repository.dart';

/// Pobla Firestore con datos de demostración reales de Huancayo.
/// Todos los IDs son fijos para que las referencias cruzadas
/// (reservas.canchaId, flashSlots.canchaId) apunten a documentos reales.
class DatabaseSeeder {
  DatabaseSeeder._();

  static final _db = FirebaseFirestore.instance;

  // ── IDs fijos — Complejos ─────────────────────────────────────────────────
  static const _c1 = 'complejo_tambo_sport';
  static const _c2 = 'complejo_sport_center_chilca';
  static const _c3 = 'complejo_los_andes';
  static const _c4 = 'complejo_shullcas_fc';
  static const _c5 = 'complejo_indoor_huancayo';

  // ── IDs fijos — Canchas (kComplejoDeporteletra) ──────────────────────────
  // Complejo 1 — El Tambo Sport
  static const kTamboF5a = 'k_tambo_f5a';
  static const kTamboF5b = 'k_tambo_f5b';
  static const kTamboF7  = 'k_tambo_f7';
  static const kTamboBas = 'k_tambo_bas';

  // Complejo 2 — Sport Center Chilca
  static const kChilcaF5a = 'k_chilca_f5a';
  static const kChilcaF5b = 'k_chilca_f5b';
  static const kChilcaF7  = 'k_chilca_f7';

  // Complejo 3 — Los Andes FC
  static const kAndesF5a = 'k_andes_f5a';
  static const kAndesF5b = 'k_andes_f5b';
  static const kAndesVol = 'k_andes_vol';

  // Complejo 4 — Shullcas FC
  static const kShullcasF7 = 'k_shullcas_f7';
  static const kShullcasF5 = 'k_shullcas_f5';

  // Complejo 5 — Indoor Sport Huancayo
  static const kIndoorF5a = 'k_indoor_f5a';
  static const kIndoorF5b = 'k_indoor_f5b';
  static const kIndoorBas = 'k_indoor_bas';
  static const kIndoorVol = 'k_indoor_vol';

  // ── Entry point ───────────────────────────────────────────────────────────

  static Future<void> ejecutar({String? duenoUid}) async {
    debugPrint('[Seeder] Iniciando seed… (duenoUid: $duenoUid)');
    await _seedComplejos(duenoUid: duenoUid);
    await _seedCanchas();
    await _seedReservas();
    await _seedPartidos();
    await _seedFlashSlots();
    await _seedPrediccionesIA();
    await _seedResenas();
    // Si hay un dueño autenticado, asócialo al primer complejo
    if (duenoUid != null && duenoUid.isNotEmpty) {
      await UsuariosRepository().actualizarComplejoId(duenoUid, _c1);
      debugPrint('[Seeder] ✓ Dueño $duenoUid asociado a $_c1');
    }
    debugPrint('[Seeder] ✅ Seed completado.');
  }

  // ── 1. Complejos ──────────────────────────────────────────────────────────

  static Future<void> _seedComplejos({String? duenoUid}) async {
    final datos = [
      _complejo(
        id: _c1,
        duenoUid: duenoUid ?? '',
        nombre: 'El Tambo Sport',
        descripcion: 'El complejo más grande de El Tambo con 4 canchas de alta calidad. Canchas sintéticas de última generación con iluminación LED para partidos nocturnos.',
        direccion: 'Av. Mariscal Castilla 2150, El Tambo',
        lat: -12.0478, lng: -75.2107,
        apertura: '07:00', cierre: '23:00',
        rating: 4.8, resenias: 124,
        imagenes: [
          'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
          'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800',
        ],
        servicios: ['vestuarios', 'duchas', 'estacionamiento', 'iluminacion'],
        modoReserva: 'instantanea',
        reglas: 'Presentarse 10 min antes. Traer tacos adecuados. Prohibido fumar dentro del complejo.',
      ),
      _complejo(
        id: _c2,
        nombre: 'Sport Center Chilca',
        descripcion: 'Complejo premium con canchas de grass natural y sintético. Contamos con cafetería, vestuarios modernos y estacionamiento propio.',
        direccion: 'Jr. Los Ángeles 340, Chilca',
        lat: -12.0890, lng: -75.1978,
        apertura: '06:00', cierre: '22:00',
        rating: 4.9, resenias: 87,
        imagenes: [
          'https://images.unsplash.com/photo-1459865264687-595d652de67e?w=800',
          'https://images.unsplash.com/photo-1518604666860-9ed391f76460?w=800',
        ],
        servicios: ['vestuarios', 'duchas', 'cafeteria', 'estacionamiento', 'tribuna'],
        modoReserva: 'instantanea',
        reglas: 'Respetar el horario reservado. No se admiten más de 2 equipos por cancha.',
      ),
      _complejo(
        id: _c3,
        nombre: 'Los Andes Fútbol Club',
        descripcion: 'Complejo familiar en el corazón de Huancayo. Canchas accesibles para todos los niveles con tarifas competitivas.',
        direccion: 'Av. Ferrocarril 890, Huancayo Centro',
        lat: -12.0651, lng: -75.2049,
        apertura: '08:00', cierre: '22:00',
        rating: 4.6, resenias: 56,
        imagenes: [
          'https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?w=800',
        ],
        servicios: ['vestuarios', 'estacionamiento'],
        modoReserva: 'solicitud',
        reglas: 'Pago anticipado requerido. Cancelaciones con 2 horas de anticipación.',
      ),
      _complejo(
        id: _c4,
        nombre: 'Shullcas FC',
        descripcion: 'Canchas de grass natural en zona tranquila de San Carlos. Ideal para partidos de fútbol 7 en entorno natural.',
        direccion: 'Av. Shullcas 450, San Carlos',
        lat: -12.0520, lng: -75.1890,
        apertura: '07:00', cierre: '21:00',
        rating: 4.4, resenias: 33,
        imagenes: [
          'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=800',
        ],
        servicios: ['estacionamiento'],
        modoReserva: 'instantanea',
        reglas: 'Solo calzado de grass. No se permiten tacos de metal.',
      ),
      _complejo(
        id: _c5,
        nombre: 'Indoor Sport Huancayo',
        descripcion: 'El único complejo indoor de Huancayo. Canchas cubiertas para jugar sin importar el clima. WiFi gratuito y cafetería.',
        direccion: 'Jr. Ancash 120, Huancayo Centro',
        lat: -12.0700, lng: -75.2100,
        apertura: '08:00', cierre: '23:00',
        rating: 4.7, resenias: 61,
        imagenes: [
          'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800',
          'https://images.unsplash.com/photo-1515523110800-9415d13b84a8?w=800',
        ],
        servicios: ['vestuarios', 'duchas', 'cafeteria', 'wifi', 'tribuna'],
        modoReserva: 'instantanea',
        reglas: 'Solo zapatillas de deporte indoor. Prohibido ingresar con comida del exterior.',
      ),
    ];

    final batch = _db.batch();
    for (final doc in datos) {
      final id = doc['id'] as String;
      final ref = _db.collection('complejos').doc(id);
      final data = Map<String, dynamic>.from(doc)..remove('id');
      batch.set(ref, {...data, 'creadoEn': FieldValue.serverTimestamp()});
    }
    await batch.commit();
    debugPrint('[Seeder] ✓ ${datos.length} complejos');
  }

  static Map<String, dynamic> _complejo({
    required String id,
    required String nombre,
    required String descripcion,
    required String direccion,
    required double lat,
    required double lng,
    required String apertura,
    required String cierre,
    required double rating,
    required int resenias,
    required List<String> imagenes,
    List<String> servicios = const [],
    String modoReserva = 'instantanea',
    String reglas = '',
    String duenoUid = '',
  }) =>
      {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'direccion': direccion,
        'ciudad': 'Huancayo',
        'lat': lat,
        'lng': lng,
        'rating': rating,
        'totalReseñas': resenias,
        'horarioApertura': apertura,
        'horarioCierre': cierre,
        'imagenes': imagenes,
        'servicios': servicios,
        'modoReserva': modoReserva,
        'reglas': reglas,
        'duenoUid': duenoUid,
        'activo': true,
        'configIA': {
          'preciosDinamicosActivo': false,
          'flashAutomaticoActivo': false,
          'precioTechoMax': 200.0,
          'notificarJugadores': true,
        },
      };

  // ── 2. Canchas — IDs fijos para referencias cruzadas ─────────────────────

  static Future<void> _seedCanchas() async {
    final canchasPorComplejo = <String, List<Map<String, dynamic>>>{
      _c1: [
        _cancha(_c1, kTamboF5a, 'Cancha 1',  'futbol5', 'sintetico', 10, 50.0, techada: false, iluminacion: true),
        _cancha(_c1, kTamboF5b, 'Cancha 2',  'futbol5', 'sintetico', 10, 50.0, techada: false, iluminacion: true),
        _cancha(_c1, kTamboF7,  'Cancha 3',  'futbol7', 'sintetico', 14, 70.0, techada: false, iluminacion: true),
        _cancha(_c1, kTamboBas, 'Básquet A', 'basquet', 'cemento',   10, 40.0, techada: false, iluminacion: true),
      ],
      _c2: [
        _cancha(_c2, kChilcaF5a, 'Cancha 1',      'futbol5', 'sintetico', 10, 45.0, techada: false, iluminacion: true),
        _cancha(_c2, kChilcaF5b, 'Cancha 2',      'futbol5', 'sintetico', 10, 45.0, techada: false, iluminacion: false),
        _cancha(_c2, kChilcaF7,  'Cancha Grande', 'futbol7', 'grass',     14, 80.0, techada: false, iluminacion: true),
      ],
      _c3: [
        _cancha(_c3, kAndesF5a, 'Cancha Principal', 'futbol5', 'sintetico', 10, 40.0, techada: false, iluminacion: false),
        _cancha(_c3, kAndesF5b, 'Cancha 2',         'futbol5', 'cemento',   10, 30.0, techada: false, iluminacion: false),
        _cancha(_c3, kAndesVol, 'Voley Indoor',     'voley',   'cemento',   12, 35.0, techada: true,  iluminacion: true),
      ],
      _c4: [
        _cancha(_c4, kShullcasF7, 'Cancha Grass', 'futbol7', 'grass',     14, 60.0, techada: false, iluminacion: false),
        _cancha(_c4, kShullcasF5, 'Fútbol 5',     'futbol5', 'sintetico', 10, 38.0, techada: false, iluminacion: false),
      ],
      _c5: [
        _cancha(_c5, kIndoorF5a, 'Pista Indoor A', 'futbol5', 'sintetico', 10, 55.0, techada: true, iluminacion: true),
        _cancha(_c5, kIndoorF5b, 'Pista Indoor B', 'futbol5', 'sintetico', 10, 55.0, techada: true, iluminacion: true),
        _cancha(_c5, kIndoorBas, 'Básquet Indoor', 'basquet', 'cemento',   10, 45.0, techada: true, iluminacion: true),
        _cancha(_c5, kIndoorVol, 'Voley Indoor',   'voley',   'cemento',   12, 40.0, techada: true, iluminacion: true),
      ],
    };

    for (final entry in canchasPorComplejo.entries) {
      final batch = _db.batch();
      for (final cancha in entry.value) {
        final canchaId = cancha['_id'] as String;
        final ref = _db
            .collection('complejos/${entry.key}/canchas')
            .doc(canchaId);
        final data = Map<String, dynamic>.from(cancha)..remove('_id');
        batch.set(ref, {...data, 'creadoEn': FieldValue.serverTimestamp()});
      }
      await batch.commit();
    }

    final total = canchasPorComplejo.values.fold(0, (s, l) => s + l.length);
    debugPrint('[Seeder] ✓ $total canchas');
  }

  static Map<String, dynamic> _cancha(
    String complejoId,
    String canchaId,
    String nombre,
    String deporte,
    String superficie,
    int capacidad,
    double precioBase, {
    bool techada = false,
    bool iluminacion = false,
  }) =>
      {
        '_id': canchaId,
        'complejoId': complejoId,
        'nombre': nombre,
        'deporte': deporte,
        'superficie': superficie,
        'capacidad': capacidad,
        'precioBase': precioBase,
        'activa': true,
        'techada': techada,
        'iluminacion': iluminacion,
        'descripcion': '',
      };

  // ── 3. Reservas — referencias a canchas reales ────────────────────────────

  static Future<void> _seedReservas() async {
    final hoy = DateTime.now();
    final ayer  = hoy.subtract(const Duration(days: 1));
    final hace7 = hoy.subtract(const Duration(days: 7));
    final manana = hoy.add(const Duration(days: 1));

    final reservas = [
      // Reserva confirmada — hoy
      _reserva(
        userId: 'demo_user_1',
        complejoId: _c1, canchaId: kTamboF5a,
        fecha: hoy, horaInicio: '18:00', horaFin: '19:00',
        duracionHoras: 1.0, precioTotal: 50.0,
        estado: 'confirmada', tipo: 'normal', metodoPago: 'yape',
      ),
      // Reserva confirmada — ayer
      _reserva(
        userId: 'demo_user_2',
        complejoId: _c2, canchaId: kChilcaF5a,
        fecha: ayer, horaInicio: '20:00', horaFin: '21:00',
        duracionHoras: 1.0, precioTotal: 45.0,
        estado: 'confirmada', tipo: 'normal', metodoPago: 'plin',
      ),
      // Reserva flash — hace 7 días
      _reserva(
        userId: 'demo_user_3',
        complejoId: _c3, canchaId: kAndesF5a,
        fecha: hace7, horaInicio: '16:00', horaFin: '17:00',
        duracionHoras: 1.0, precioTotal: 25.0,
        estado: 'confirmada', tipo: 'flash', metodoPago: 'yape',
      ),
      // Reserva de partido — mañana (pendiente de pago)
      _reserva(
        userId: 'demo_user_4',
        complejoId: _c5, canchaId: kIndoorF5a,
        fecha: manana, horaInicio: '19:00', horaFin: '20:00',
        duracionHoras: 1.0, precioTotal: 55.0,
        estado: 'pendiente', tipo: 'partido', metodoPago: 'efectivo',
      ),
      // Reserva cancelada — hace 7 días
      _reserva(
        userId: 'demo_user_1',
        complejoId: _c4, canchaId: kShullcasF7,
        fecha: hace7, horaInicio: '10:00', horaFin: '11:00',
        duracionHoras: 1.0, precioTotal: 60.0,
        estado: 'cancelada', tipo: 'normal', metodoPago: 'tarjeta',
      ),
    ];

    final batch = _db.batch();
    for (final r in reservas) {
      final ref = _db.collection('reservas').doc();
      batch.set(ref, {...r, 'creadoEn': FieldValue.serverTimestamp()});
    }
    await batch.commit();
    debugPrint('[Seeder] ✓ ${reservas.length} reservas');
  }

  static Map<String, dynamic> _reserva({
    required String userId,
    required String complejoId,
    required String canchaId,
    required DateTime fecha,
    required String horaInicio,
    required String horaFin,
    required double duracionHoras,
    required double precioTotal,
    required String estado,
    required String tipo,
    required String metodoPago,
    String? flashSlotId,
    String? partidoId,
  }) =>
      {
        'userId': userId,
        'complejoId': complejoId,
        'canchaId': canchaId,
        'fecha': Timestamp.fromDate(
            DateTime(fecha.year, fecha.month, fecha.day)),
        'horaInicio': horaInicio,
        'horaFin': horaFin,
        'duracionHoras': duracionHoras,
        'precioTotal': precioTotal,
        'estado': estado,
        'tipo': tipo,
        'metodoPago': metodoPago,
        'codigoAcceso': _uuid(),
        'modoReserva': 'instantanea',
        'estadoPago': estado == 'confirmada' ? 'liberado' : 'retenido',
        // ignore: use_null_aware_elements
        if (flashSlotId != null) 'flashSlotId': flashSlotId,
        // ignore: use_null_aware_elements
        if (partidoId != null) 'partidoId': partidoId,
      };

  // ── 4. Partidos abiertos ──────────────────────────────────────────────────
  // Los partidos en estado "abierto" aún no tienen cancha asignada —
  // se auto-asigna cuando se llena el cupo. Eso es correcto por diseño.

  static Future<void> _seedPartidos() async {
    final manana = DateTime.now().add(const Duration(days: 1));
    final pasado = DateTime.now().add(const Duration(days: 2));

    final partidos = [
      _partido(
        organizadorId: 'demo_user_1',
        deporte: 'futbol5',
        fecha: manana, horaInicio: '18:00', horaFin: '19:00',
        jugadoresNecesarios: 10, precioMax: 15.0,
        jugadores: [
          _jugador('demo_user_1', 'Carlos Mamani', 'CM'),
          _jugador('demo_user_2', 'Luis Quispe', 'LQ'),
          _jugador('demo_user_3', 'Pedro Huanca', 'PH'),
        ],
      ),
      _partido(
        organizadorId: 'demo_user_4',
        deporte: 'futbol7',
        fecha: manana, horaInicio: '20:00', horaFin: '21:30',
        jugadoresNecesarios: 14, precioMax: 12.0,
        jugadores: [
          _jugador('demo_user_4', 'Miguel Torres', 'MT'),
          _jugador('demo_user_5', 'José Palomino', 'JP'),
        ],
      ),
      _partido(
        organizadorId: 'demo_user_6',
        deporte: 'basquet',
        fecha: pasado, horaInicio: '17:00', horaFin: '18:00',
        jugadoresNecesarios: 10, precioMax: 8.0,
        jugadores: [
          _jugador('demo_user_6', 'Ana Flores', 'AF'),
          _jugador('demo_user_7', 'Rosa Ccori', 'RC'),
          _jugador('demo_user_8', 'Jhon Poma', 'JP'),
          _jugador('demo_user_9', 'David Suarez', 'DS'),
        ],
      ),
    ];

    final batch = _db.batch();
    for (final p in partidos) {
      batch.set(_db.collection('partidos').doc(),
          {...p, 'creadoEn': FieldValue.serverTimestamp()});
    }
    await batch.commit();
    debugPrint('[Seeder] ✓ ${partidos.length} partidos');
  }

  static Map<String, dynamic> _partido({
    required String organizadorId,
    required String deporte,
    required DateTime fecha,
    required String horaInicio,
    required String horaFin,
    required int jugadoresNecesarios,
    required double precioMax,
    required List<Map<String, dynamic>> jugadores,
  }) =>
      {
        'organizadorId': organizadorId,
        // Sin complejoId/canchaId — se asignan cuando el partido se llena
        'deporte': deporte,
        'fecha': Timestamp.fromDate(
            DateTime(fecha.year, fecha.month, fecha.day)),
        'horaInicio': horaInicio,
        'horaFin': horaFin,
        'jugadoresNecesarios': jugadoresNecesarios,
        'precioMaxPorJugador': precioMax,
        'estado': 'abierto',
        'jugadores': jugadores,
      };

  static Map<String, dynamic> _jugador(
          String userId, String nombre, String iniciales) =>
      {
        'userId': userId,
        'nombre': nombre,
        'avatarUrl': '',
        'iniciales': iniciales,
        'pagado': false,
        'unidoEn': Timestamp.fromDate(DateTime.now()),
      };

  // ── 5. Flash Slots — referencias a canchas reales ─────────────────────────

  static Future<void> _seedFlashSlots() async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    final slots = [
      _flashSlot(
        complejoId: _c1, canchaId: kTamboF5a,
        fecha: hoy, horaInicio: '14:00', horaFin: '15:00',
        precioOriginal: 50.0, precioFlash: 30.0, descuentoPct: 40,
        expiraEn: ahora.add(const Duration(hours: 3)),
      ),
      _flashSlot(
        complejoId: _c3, canchaId: kAndesF5a,
        fecha: hoy, horaInicio: '16:00', horaFin: '17:00',
        precioOriginal: 40.0, precioFlash: 25.0, descuentoPct: 37,
        expiraEn: ahora.add(const Duration(hours: 5)),
      ),
      _flashSlot(
        complejoId: _c5, canchaId: kIndoorF5a,
        fecha: hoy, horaInicio: '21:00', horaFin: '22:00',
        precioOriginal: 55.0, precioFlash: 35.0, descuentoPct: 36,
        expiraEn: ahora.add(const Duration(hours: 8)),
      ),
    ];

    final batch = _db.batch();
    for (final s in slots) {
      batch.set(_db.collection('flashSlots').doc(),
          {...s, 'creadoEn': FieldValue.serverTimestamp()});
    }
    await batch.commit();
    debugPrint('[Seeder] ✓ ${slots.length} flash slots');
  }

  static Map<String, dynamic> _flashSlot({
    required String complejoId,
    required String canchaId,
    required DateTime fecha,
    required String horaInicio,
    required String horaFin,
    required double precioOriginal,
    required double precioFlash,
    required int descuentoPct,
    required DateTime expiraEn,
  }) =>
      {
        'complejoId': complejoId,
        'canchaId': canchaId,
        'fecha': Timestamp.fromDate(fecha),
        'horaInicio': horaInicio,
        'horaFin': horaFin,
        'precioOriginal': precioOriginal,
        'precioFlash': precioFlash,
        'descuentoPct': descuentoPct,
        'expiraEn': Timestamp.fromDate(expiraEn),
        'estado': 'activo',
        'vistasCount': 0,
        'creadoPor': 'seed',
      };

  // ── 6. Predicciones IA ────────────────────────────────────────────────────

  static Future<void> _seedPrediccionesIA() async {
    final semana = _semanaISO(DateTime.now());

    final predicciones = [
      _prediccion(complejoId: _c1, semana: semana, precision: 0.84),
      _prediccion(complejoId: _c2, semana: semana, precision: 0.79),
      _prediccion(complejoId: _c3, semana: semana, precision: 0.91),
      _prediccion(complejoId: _c4, semana: semana, precision: 0.72),
      _prediccion(complejoId: _c5, semana: semana, precision: 0.88),
    ];

    final batch = _db.batch();
    for (final p in predicciones) {
      final docId = '${p['complejoId']}_$semana';
      batch.set(_db.collection('prediccionesIA').doc(docId),
          {...p, 'generadoEn': FieldValue.serverTimestamp()});
    }
    await batch.commit();
    debugPrint('[Seeder] ✓ ${predicciones.length} predicciones IA');
  }

  static Map<String, dynamic> _prediccion({
    required String complejoId,
    required String semana,
    required double precision,
  }) =>
      {
        'complejoId': complejoId,
        'semana': semana,
        'precision': precision,
        'heatmap': {
          '07:00': 0.15, '08:00': 0.20, '09:00': 0.25,
          '10:00': 0.30, '11:00': 0.35, '12:00': 0.50,
          '13:00': 0.45, '14:00': 0.40, '15:00': 0.55,
          '16:00': 0.65, '17:00': 0.80, '18:00': 0.95,
          '19:00': 1.00, '20:00': 0.90, '21:00': 0.70,
          '22:00': 0.40,
        },
        'preciosDinamicos': [
          {'horaInicio': '07:00', 'multiplicador': 0.80, 'precioSugerido': 32.0},
          {'horaInicio': '09:00', 'multiplicador': 0.90, 'precioSugerido': 36.0},
          {'horaInicio': '12:00', 'multiplicador': 1.00, 'precioSugerido': 40.0},
          {'horaInicio': '15:00', 'multiplicador': 1.10, 'precioSugerido': 44.0},
          {'horaInicio': '17:00', 'multiplicador': 1.25, 'precioSugerido': 50.0},
          {'horaInicio': '19:00', 'multiplicador': 1.40, 'precioSugerido': 56.0},
          {'horaInicio': '21:00', 'multiplicador': 1.15, 'precioSugerido': 46.0},
        ],
      };

  // ── 7. Reseñas de ejemplo ─────────────────────────────────────────────────

  static Future<void> _seedResenas() async {
    final hace3 = DateTime.now().subtract(const Duration(days: 3));
    final hace7 = DateTime.now().subtract(const Duration(days: 7));
    final hace14 = DateTime.now().subtract(const Duration(days: 14));

    final resenas = [
      {
        'complejoId': _c1,
        'userId': 'demo_user_1',
        'userName': 'Carlos Mamani',
        'userAvatar': '',
        'reservaId': 'reserva_demo_1',
        'calificacion': 5.0,
        'comentario': 'Excelente cancha, muy bien mantenida. La iluminación es perfecta para jugar de noche.',
        'respuestaDueno': '¡Gracias Carlos! Te esperamos pronto.',
        'fecha': Timestamp.fromDate(hace3),
      },
      {
        'complejoId': _c1,
        'userId': 'demo_user_2',
        'userName': 'Luis Quispe',
        'userAvatar': '',
        'reservaId': 'reserva_demo_2',
        'calificacion': 4.0,
        'comentario': 'Muy buena cancha. Los vestuarios podrían estar un poco más limpios.',
        'fecha': Timestamp.fromDate(hace7),
      },
      {
        'complejoId': _c2,
        'userId': 'demo_user_3',
        'userName': 'Pedro Huanca',
        'userAvatar': '',
        'reservaId': 'reserva_demo_3',
        'calificacion': 5.0,
        'comentario': 'La mejor cancha de Huancayo sin duda. El grass natural es increíble.',
        'respuestaDueno': 'Muchas gracias Pedro, nos esforzamos cada día.',
        'fecha': Timestamp.fromDate(hace7),
      },
      {
        'complejoId': _c3,
        'userId': 'demo_user_4',
        'userName': 'Miguel Torres',
        'userAvatar': '',
        'reservaId': 'reserva_demo_4',
        'calificacion': 4.0,
        'comentario': 'Buena ubicación y precio accesible. Recomendado para partidos amistosos.',
        'fecha': Timestamp.fromDate(hace14),
      },
      {
        'complejoId': _c5,
        'userId': 'demo_user_5',
        'userName': 'José Palomino',
        'userAvatar': '',
        'reservaId': 'reserva_demo_5',
        'calificacion': 5.0,
        'comentario': 'Lo mejor es que es cubierto, puedes jugar aunque llueva. El personal muy amable.',
        'respuestaDueno': '¡Así es José! Disponibles los 365 días del año.',
        'fecha': Timestamp.fromDate(hace3),
      },
    ];

    final batch = _db.batch();
    for (final r in resenas) {
      batch.set(_db.collection('resenas').doc(),
          {...r, 'creadoEn': FieldValue.serverTimestamp()});
    }
    await batch.commit();
    debugPrint('[Seeder] ✓ ${resenas.length} reseñas');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _semanaISO(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(startOfYear).inDays;
    final week = (days / 7).ceil();
    return '${date.year}-W${week.toString().padLeft(2, '0')}';
  }

  static String _uuid() {
    final r = DateTime.now().microsecondsSinceEpoch;
    return [r, r ^ 0xDEAD, r ^ 0xBEEF, r ^ 0xCAFE]
        .map((n) => n.toRadixString(16).padLeft(8, '0'))
        .join('-');
  }

  // ── Verificar si ya existe data ───────────────────────────────────────────

  static Future<bool> yaEjecutado() async {
    final snap = await _db
        .collection('complejos')
        .where('activo', isEqualTo: true)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ── Limpiar todo el seed ──────────────────────────────────────────────────

  static Future<void> limpiar() async {
    // Borrar complejos + sus subcanchas
    for (final complejoId in [_c1, _c2, _c3, _c4, _c5]) {
      final canchas =
          await _db.collection('complejos/$complejoId/canchas').get();
      final batch = _db.batch();
      for (final d in canchas.docs) {
        batch.delete(d.reference);
      }
      batch.delete(_db.doc('complejos/$complejoId'));
      await batch.commit();
    }

    // Borrar colecciones raíz
    final colecciones = await Future.wait([
      _db.collection('partidos').get(),
      _db.collection('flashSlots').get(),
      _db.collection('reservas').get(),
      _db.collection('prediccionesIA').get(),
      _db.collection('resenas').get(),
    ]);

    final batch = _db.batch();
    for (final snap in colecciones) {
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
    debugPrint('[Seeder] ✓ Base de datos limpiada');
  }
}
