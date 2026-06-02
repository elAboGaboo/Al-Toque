// nucleo/servicios/datos_sembrador.dart
//
// Siembra Firestore con datos de demostraciÃ³n para Al Toque.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// â€¢ NO crea cuentas en Firebase Auth.
// â€¢ Todos los documentos llevan esDemo:true â†’ las reglas de Firestore
//   permiten estos writes sin auth (ver firestore.rules).
// â€¢ Los IDs de complejos y canchas son fijos para que las referencias
//   cruzadas (reservas.canchaId, flashSlots.canchaId, etc.) apunten a
//   documentos reales.
// â€¢ Las reservas estÃ¡n distribuidas en la SEMANA ACTUAL para que el
//   dashboard del dueÃ±o muestre grÃ¡ficos con datos reales.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseSeeder {
  DatabaseSeeder._();

  static final _db = FirebaseFirestore.instance;

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  IDs FIJOS â€” Complejos
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  static const _c1 = 'complejo_tambo_sport';
  static const _c2 = 'complejo_sport_chilca';
  static const _c3 = 'complejo_los_andes';
  static const _c4 = 'complejo_shullcas';
  static const _c5 = 'complejo_indoor_hyo';

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  IDs FIJOS â€” Canchas (subcolecciÃ³n de cada complejo)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // Tambo Sport
  static const _kTF5a = 'cancha_tambo_f5a';
  static const _kTF5b = 'cancha_tambo_f5b';
  static const _kTF7  = 'cancha_tambo_f7';
  static const _kTBas = 'cancha_tambo_bas';
  // Sport Chilca
  static const _kCF5a = 'cancha_chilca_f5a';
  static const _kCF5b = 'cancha_chilca_f5b';
  static const _kCF7  = 'cancha_chilca_f7';
  // Los Andes
  static const _kAF5  = 'cancha_andes_f5';
  static const _kAF7  = 'cancha_andes_f7';
  static const _kAVol = 'cancha_andes_vol';
  // Shullcas
  static const _kSF5  = 'cancha_shullcas_f5';
  static const _kSF7  = 'cancha_shullcas_f7';
  // Indoor
  static const _kIF5a = 'cancha_indoor_f5a';
  static const _kIF5b = 'cancha_indoor_f5b';
  static const _kIBas = 'cancha_indoor_bas';
  static const _kIVol = 'cancha_indoor_vol';

  // UID ficticio para el jugador demo (sin cuenta Auth real)
  static const kUidJugador = 'uid_jugador_demo';

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  ENTRY POINT
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  /// Siembra la base de datos completa.
  /// [duenoUid] â€” UID del dueÃ±o autenticado; si se provee, se vincula a _c1.
  static Future<void> ejecutar({String? duenoUid}) async {
    debugPrint('[Seeder] â–¶ Iniciandoâ€¦');

    // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    // IMPORTANTE: Actualizar el perfil del dueÃ±o PRIMERO.
    // La regla isDuenoDeComplejo() verifica que el campo complejoId
    // del usuario sea igual al complejoId del documento.
    // Si actualizamos al final, las escrituras de canchas fallan
    // con permission-denied porque el dueÃ±o aÃºn no tiene complejoId.
    // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (duenoUid != null && duenoUid.isNotEmpty) {
      await _db.collection('usuarios').doc(duenoUid).set({
        'complejoId': _c1,
        'nombreComplejo': 'El Tambo Sport',
        'rol': 'dueno',
      }, SetOptions(merge: true));
      debugPrint('[Seeder] âœ“ DueÃ±o $duenoUid â†’ $_c1 (pre-vinculado)');
    }

    await _seedComplejos(duenoUid: duenoUid);
    await _seedCanchas();
    await _seedReservas(duenoUid: duenoUid);
    await _seedPartidos();
    await _seedFlashSlots();
    await _seedPrediccionesIA();
    await _seedResenas();

    debugPrint('[Seeder] âœ… Seed completado');
  }

  /// VersiÃ³n sin auth â€” siembra sin necesitar usuario logueado.
  static Future<void> ejecutarSinAuth() => ejecutar(duenoUid: null);

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  1. COMPLEJOS
  //  ColecciÃ³n: complejos/{complejoId}
  //  Modelo: ComplejoModel
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //
  //  Campos:
  //    nombre          String  â€” nombre del complejo
  //    descripcion     String  â€” descripciÃ³n larga
  //    direccion       String  â€” direcciÃ³n completa
  //    ciudad          String  â€” siempre 'Huancayo'
  //    lat             double  â€” latitud GPS
  //    lng             double  â€” longitud GPS
  //    horarioApertura String  â€” 'HH:MM'
  //    horarioCierre   String  â€” 'HH:MM'
  //    imagenes        List    â€” URLs de imÃ¡genes (al menos 1)
  //    duenoUid        String  â€” UID del dueÃ±o (vacÃ­o si no asignado)
  //    activo          bool    â€” si aparece en el listado
  //    esDemo          bool    â€” marca de dato semilla
  //    creadoEn        TS      â€” serverTimestamp
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<void> _seedComplejos({String? duenoUid}) async {
    final batch = _db.batch();

    final complejos = [
      _complejo(
        id: _c1,
        duenoUid: duenoUid ?? '',
        nombre: 'El Tambo Sport',
        descripcion:
            'El complejo mÃ¡s grande de El Tambo con 4 canchas de alta calidad. '
            'Grass sintÃ©tico de Ãºltima generaciÃ³n con iluminaciÃ³n LED para '
            'partidos nocturnos. Vestuarios, duchas y estacionamiento gratuito.',
        direccion: 'Av. Mariscal Castilla 2150, El Tambo, Huancayo',
        lat: -12.0478,
        lng: -75.2107,
        apertura: '07:00',
        cierre: '23:00',
        imagenes: [
          'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
          'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800',
        ],
      ),
      _complejo(
        id: _c2,
        nombre: 'Sport Center Chilca',
        descripcion:
            'Complejo premium con canchas de grass natural y sintÃ©tico. '
            'CafeterÃ­a, vestuarios modernos, estacionamiento propio y tribuna '
            'para espectadores. Ideal para campeonatos y torneos.',
        direccion: 'Jr. Los Ãngeles 340, Chilca, Huancayo',
        lat: -12.0890,
        lng: -75.1978,
        apertura: '06:00',
        cierre: '22:00',
        imagenes: [
          'https://images.unsplash.com/photo-1459865264687-595d652de67e?w=800',
          'https://images.unsplash.com/photo-1518604666860-9ed391f76460?w=800',
        ],
      ),
      _complejo(
        id: _c3,
        nombre: 'Los Andes FC',
        descripcion:
            'Complejo familiar en el corazÃ³n de Huancayo. Canchas accesibles '
            'para todos los niveles con tarifas competitivas. Vestuarios y '
            'estacionamiento disponible. Ambiente familiar y seguro.',
        direccion: 'Av. Ferrocarril 890, Huancayo Centro',
        lat: -12.0651,
        lng: -75.2049,
        apertura: '08:00',
        cierre: '22:00',
        imagenes: [
          'https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?w=800',
        ],
      ),
      _complejo(
        id: _c4,
        nombre: 'Shullcas FC',
        descripcion:
            'Canchas de grass natural en zona tranquila de San Carlos. '
            'Ideal para partidos de fÃºtbol 7 en un entorno natural con vista '
            'al rÃ­o Shullcas. Ambiente relajado y precios accesibles.',
        direccion: 'Av. Shullcas 450, San Carlos, Huancayo',
        lat: -12.0520,
        lng: -75.1890,
        apertura: '07:00',
        cierre: '21:00',
        imagenes: [
          'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=800',
        ],
      ),
      _complejo(
        id: _c5,
        nombre: 'Indoor Sport Huancayo',
        descripcion:
            'El Ãºnico complejo indoor de Huancayo. Canchas cubiertas para '
            'jugar sin importar el clima. WiFi gratuito, cafeterÃ­a y '
            'vestuarios modernos. Abierto los 365 dÃ­as del aÃ±o.',
        direccion: 'Jr. Ancash 120, Huancayo Centro',
        lat: -12.0700,
        lng: -75.2100,
        apertura: '08:00',
        cierre: '23:00',
        imagenes: [
          'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800',
          'https://images.unsplash.com/photo-1515523110800-9415d13b84a8?w=800',
        ],
      ),
    ];

    for (final c in complejos) {
      final id = c['id'] as String;
      final data = Map<String, dynamic>.from(c)..remove('id');
      batch.set(
        _db.collection('complejos').doc(id),
        {...data, 'creadoEn': FieldValue.serverTimestamp()},
      );
    }
    await batch.commit();
    debugPrint('[Seeder] âœ“ ${complejos.length} complejos');
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
    required List<String> imagenes,
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
        'horarioApertura': apertura,
        'horarioCierre': cierre,
        'imagenes': imagenes,
        'duenoUid': duenoUid,
        'activo': true,
        'esDemo': true,
      };

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  2. CANCHAS
  //  ColecciÃ³n: complejos/{complejoId}/canchas/{canchaId}
  //  Modelo: CanchaModel
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //
  //  Campos:
  //    complejoId   String  â€” ID del complejo padre
  //    nombre       String  â€” nombre de la cancha
  //    deporte      String  â€” 'futbol5' | 'futbol7' | 'basquet' | 'voley'
  //    superficie   String  â€” 'sintetico' | 'cemento' | 'grass'
  //    capacidad    int     â€” nÃºmero de jugadores (10 / 14 / 12)
  //    precioBase   double  â€” precio por hora en S/
  //    activa       bool    â€” si estÃ¡ disponible para reservas
  //    techada      bool    â€” cubierta / indoor
  //    iluminacion  bool    â€” tiene luz para jugar de noche
  //    descripcion  String  â€” descripciÃ³n opcional
  //    esDemo       bool    â€” marca de dato semilla
  //    creadoEn     TS      â€” serverTimestamp
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<void> _seedCanchas() async {
    // Mapa: complejoId â†’ lista de canchas
    final mapa = <String, List<Map<String, dynamic>>>{
      _c1: [
        _cancha(_c1, _kTF5a, 'Cancha 1 â€“ FÃºtbol 5',  'futbol5', 'sintetico', 10, 50.0, iluminacion: true),
        _cancha(_c1, _kTF5b, 'Cancha 2 â€“ FÃºtbol 5',  'futbol5', 'sintetico', 10, 50.0, iluminacion: true),
        _cancha(_c1, _kTF7,  'Cancha 3 â€“ FÃºtbol 7',  'futbol7', 'sintetico', 14, 70.0, iluminacion: true),
        _cancha(_c1, _kTBas, 'Cancha 4 â€“ BÃ¡squet',   'basquet', 'cemento',   10, 40.0, iluminacion: true),
      ],
      _c2: [
        _cancha(_c2, _kCF5a, 'Cancha A â€“ FÃºtbol 5',  'futbol5', 'sintetico', 10, 45.0, iluminacion: true),
        _cancha(_c2, _kCF5b, 'Cancha B â€“ FÃºtbol 5',  'futbol5', 'sintetico', 10, 45.0, iluminacion: false),
        _cancha(_c2, _kCF7,  'Cancha Grande â€“ F7',   'futbol7', 'grass',     14, 80.0, iluminacion: true),
      ],
      _c3: [
        _cancha(_c3, _kAF5,  'Cancha Principal â€“ F5', 'futbol5', 'sintetico', 10, 40.0, iluminacion: false),
        _cancha(_c3, _kAF7,  'Cancha Grande â€“ F7',    'futbol7', 'grass',     14, 55.0, iluminacion: false),
        _cancha(_c3, _kAVol, 'Cancha Voley',          'voley',   'cemento',   12, 30.0, techada: true, iluminacion: true),
      ],
      _c4: [
        _cancha(_c4, _kSF5,  'FÃºtbol 5 â€“ Grass',     'futbol5', 'grass',     10, 38.0, iluminacion: false),
        _cancha(_c4, _kSF7,  'FÃºtbol 7 â€“ Grass',     'futbol7', 'grass',     14, 55.0, iluminacion: false),
      ],
      _c5: [
        _cancha(_c5, _kIF5a, 'Pista Indoor A â€“ F5',  'futbol5', 'sintetico', 10, 55.0, techada: true, iluminacion: true),
        _cancha(_c5, _kIF5b, 'Pista Indoor B â€“ F5',  'futbol5', 'sintetico', 10, 55.0, techada: true, iluminacion: true),
        _cancha(_c5, _kIBas, 'Pista BÃ¡squet Indoor', 'basquet', 'cemento',   10, 45.0, techada: true, iluminacion: true),
        _cancha(_c5, _kIVol, 'Pista Voley Indoor',   'voley',   'cemento',   12, 40.0, techada: true, iluminacion: true),
      ],
    };

    int total = 0;
    for (final entry in mapa.entries) {
      final batch = _db.batch();
      for (final cancha in entry.value) {
        final canchaId = cancha['_id'] as String;
        final data = Map<String, dynamic>.from(cancha)..remove('_id');
        batch.set(
          _db.collection('complejos/${entry.key}/canchas').doc(canchaId),
          {...data, 'creadoEn': FieldValue.serverTimestamp()},
        );
        total++;
      }
      await batch.commit();
    }
    debugPrint('[Seeder] âœ“ $total canchas');
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
        'deporte': deporte,       // futbol5 | futbol7 | basquet | voley
        'superficie': superficie, // sintetico | cemento | grass
        'capacidad': capacidad,
        'precioBase': precioBase,
        'activa': true,
        'techada': techada,
        'iluminacion': iluminacion,
        'descripcion': '',
        'esDemo': true,
      };

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  3. RESERVAS
  //  ColecciÃ³n: reservas/{reservaId}
  //  Modelo: ReservaModel
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //
  //  Campos:
  //    userId        String  â€” UID del jugador que reservÃ³
  //    userName      String  â€” nombre del jugador (desnormalizado)
  //    complejoId    String  â€” ID del complejo
  //    canchaId      String  â€” ID de la cancha
  //    fecha         TS      â€” fecha de la reserva (sin hora)
  //    horaInicio    String  â€” 'HH:MM'
  //    horaFin       String  â€” 'HH:MM'
  //    duracionHoras double  â€” duraciÃ³n en horas (1.0, 1.5, 2.0)
  //    precioTotal   double  â€” precio total en S/
  //    estado        String  â€” 'confirmada' | 'pendiente' | 'cancelada'
  //    metodoPago    String  â€” 'yape' | 'plin' | 'tarjeta' | 'transferencia'
  //    codigoAcceso  String  â€” cÃ³digo QR de acceso
  //    partidoId     String? â€” solo si es de un partido
  //    esDemo        bool    â€” marca de dato semilla
  //    creadoEn      TS      â€” serverTimestamp
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //
  //  DISTRIBUCIÃ“N:
  //  Las reservas del complejo _c1 (dueÃ±o) estÃ¡n distribuidas en la
  //  semana actual para que el dashboard muestre barras reales.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<void> _seedReservas({String? duenoUid}) async {
    final now    = DateTime.now();
    final hoy    = DateTime(now.year, now.month, now.day);
    final ayer   = hoy.subtract(const Duration(days: 1));
    final hace2  = hoy.subtract(const Duration(days: 2));
    final hace3  = hoy.subtract(const Duration(days: 3));
    final hace4  = hoy.subtract(const Duration(days: 4));
    final hace5  = hoy.subtract(const Duration(days: 5));
    final manana = hoy.add(const Duration(days: 1));

    // userId del dueÃ±o o el demo
    final uid = (duenoUid != null && duenoUid.isNotEmpty)
        ? duenoUid
        : kUidJugador;

    final reservas = [
      // â”€â”€ Complejo _c1 (Tambo Sport) â€” semana actual â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      // Hoy: 2 confirmadas + 1 cancelada
      _reserva('res_t_001', uid, 'Jugador Demo',
          _c1, _kTF5a, hoy, '18:00', '19:00', 1.0, 50.0,
          'confirmada', 'yape'),
      _reserva('res_t_002', uid, 'Jugador Demo',
          _c1, _kTF5b, hoy, '20:00', '21:00', 1.0, 50.0,
          'confirmada', 'plin'),
      _reserva('res_t_003', uid, 'Jugador Demo',
          _c1, _kTF7, hoy, '16:00', '17:00', 1.0, 70.0,
          'cancelada', 'efectivo'),
      // Ayer: 2 confirmadas
      _reserva('res_t_004', uid, 'Jugador Demo',
          _c1, _kTF5a, ayer, '19:00', '20:00', 1.0, 50.0,
          'confirmada', 'yape'),
      _reserva('res_t_005', uid, 'Jugador Demo',
          _c1, _kTBas, ayer, '10:00', '11:00', 1.0, 40.0,
          'confirmada', 'transferencia'),
      // Hace 2 dÃ­as: 3 confirmadas
      _reserva('res_t_006', uid, 'Jugador Demo',
          _c1, _kTF5b, hace2, '17:00', '18:00', 1.0, 50.0,
          'confirmada', 'plin'),
      _reserva('res_t_007', uid, 'Jugador Demo',
          _c1, _kTF7, hace2, '20:00', '22:00', 2.0, 140.0,
          'confirmada', 'yape'),
      _reserva('res_t_008', uid, 'Jugador Demo',
          _c1, _kTF5a, hace2, '08:00', '09:00', 1.0, 50.0,
          'confirmada', 'tarjeta'),
      // Hace 3 dÃ­as: 2 confirmadas
      _reserva('res_t_009', uid, 'Jugador Demo',
          _c1, _kTF5a, hace3, '18:00', '19:00', 1.0, 50.0,
          'confirmada', 'yape'),
      _reserva('res_t_010', uid, 'Jugador Demo',
          _c1, _kTF5b, hace3, '21:00', '22:00', 1.0, 50.0,
          'confirmada', 'plin'),
      // Hace 4 dÃ­as: 2 confirmadas
      _reserva('res_t_011', uid, 'Jugador Demo',
          _c1, _kTBas, hace4, '14:00', '15:00', 1.0, 40.0,
          'confirmada', 'transferencia'),
      _reserva('res_t_012', uid, 'Jugador Demo',
          _c1, _kTF7, hace4, '19:00', '21:00', 2.0, 140.0,
          'confirmada', 'yape'),
      // Hace 5 dÃ­as: 2 confirmadas
      _reserva('res_t_013', uid, 'Jugador Demo',
          _c1, _kTF5a, hace5, '14:00', '15:00', 1.0, 50.0,
          'confirmada', 'yape'),
      _reserva('res_t_014', uid, 'Jugador Demo',
          _c1, _kTF5b, hace5, '16:00', '17:00', 1.0, 50.0,
          'confirmada', 'plin'),
      // MaÃ±ana: pendiente (visible en horarios)
      _reserva('res_t_015', uid, 'Jugador Demo',
          _c1, _kTF5a, manana, '19:00', '20:00', 1.0, 50.0,
          'pendiente', 'yape'),
      // â”€â”€ Otros complejos (datos mÃ­nimos para la app usuario) â”€
      _reserva('res_c_001', uid, 'Jugador Demo',
          _c2, _kCF5a, ayer, '20:00', '21:00', 1.0, 45.0,
          'confirmada', 'plin'),
      _reserva('res_a_001', uid, 'Jugador Demo',
          _c3, _kAF5, hace3, '16:00', '17:00', 1.0, 40.0,
          'confirmada', 'yape'),
      _reserva('res_i_001', uid, 'Jugador Demo',
          _c5, _kIF5a, hace2, '21:00', '22:00', 1.0, 55.0,
          'confirmada', 'tarjeta'),
    ];

    final batch = _db.batch();
    for (final r in reservas) {
      final id = r['_id'] as String;
      final data = Map<String, dynamic>.from(r)..remove('_id');
      batch.set(
        _db.collection('reservas').doc(id),
        {...data, 'creadoEn': FieldValue.serverTimestamp()},
      );
    }
    await batch.commit();
    debugPrint('[Seeder] âœ“ ${reservas.length} reservas');
  }

  static Map<String, dynamic> _reserva(
    String id,
    String userId,
    String userName,
    String complejoId,
    String canchaId,
    DateTime fecha,
    String horaInicio,
    String horaFin,
    double duracionHoras,
    double precioTotal,
    String estado,
    String metodoPago, {
    String? partidoId,
  }) {
    final data = <String, dynamic>{
      '_id': id,
      'userId': userId,
      'userName': userName,
      'complejoId': complejoId,
      'canchaId': canchaId,
      'fecha': Timestamp.fromDate(DateTime(fecha.year, fecha.month, fecha.day)),
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'duracionHoras': duracionHoras,
      'precioTotal': precioTotal,
      'estado': estado,             // confirmada | pendiente | cancelada
      'metodoPago': metodoPago,     // yape | plin | tarjeta | transferencia
      'codigoAcceso': _codigoAcceso(id),
      'esDemo': true,
    };
    if (partidoId != null) data['partidoId'] = partidoId;
    return data;
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  4. PARTIDOS
  //  ColecciÃ³n: partidos/{partidoId}
  //  Modelo: PartidoModel + JugadorPartido
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //
  //  Campos PartidoModel:
  //    organizadorId          String  â€” UID del organizador
  //    complejoId             String? â€” null hasta que se complete
  //    canchaId               String? â€” null hasta que se complete
  //    deporte                String  â€” futbol5 | futbol7 | basquet | voley
  //    fecha                  TS      â€” fecha del partido
  //    horaInicio             String  â€” 'HH:MM'
  //    horaFin                String  â€” 'HH:MM'
  //    jugadoresNecesarios    int     â€” cupo total (10, 14, 12)
  //    precioMaxPorJugador    double  â€” precio mÃ¡ximo por cabeza
  //    precioFinalPorJugador  double? â€” precio final (null si no completo)
  //    estado                 String  â€” abierto | completo | cancelado
  //    jugadores              List    â€” lista de JugadorPartido
  //    reservaId              String? â€” null hasta que se complete
  //    completadoEn           TS?     â€” null hasta completarse
  //    esDemo                 bool
  //    creadoEn               TS
  //
  //  Campos JugadorPartido:
  //    userId    String
  //    nombre    String
  //    avatarUrl String
  //    iniciales String â€” dos letras mayÃºsculas
  //    pagado    bool
  //    unidoEn   TS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<void> _seedPartidos() async {
    final now    = DateTime.now();
    final hoy    = DateTime(now.year, now.month, now.day);
    final manana = hoy.add(const Duration(days: 1));
    final pasado = hoy.add(const Duration(days: 2));

    final partidos = [
      {
        '_id': 'partido_demo_001',
        'organizadorId': kUidJugador,
        // sin complejoId/canchaId â€” se asignan cuando el partido se llena
        'deporte': 'futbol5',
        'fecha': Timestamp.fromDate(manana),
        'horaInicio': '18:00',
        'horaFin': '19:00',
        'jugadoresNecesarios': 10,
        'precioMaxPorJugador': 15.0,
        'estado': 'abierto',
        'jugadores': [
          _jugador(kUidJugador, 'Carlos Demo', 'CD'),
          _jugador('uid_jug_2', 'Luis Quispe', 'LQ'),
          _jugador('uid_jug_3', 'Pedro Huanca', 'PH'),
        ],
        'esDemo': true,
      },
      {
        '_id': 'partido_demo_002',
        'organizadorId': kUidJugador,
        'deporte': 'futbol7',
        'fecha': Timestamp.fromDate(manana),
        'horaInicio': '20:00',
        'horaFin': '21:30',
        'jugadoresNecesarios': 14,
        'precioMaxPorJugador': 12.0,
        'estado': 'abierto',
        'jugadores': [
          _jugador(kUidJugador, 'Carlos Demo', 'CD'),
          _jugador('uid_jug_4', 'Miguel Torres', 'MT'),
        ],
        'esDemo': true,
      },
      {
        '_id': 'partido_demo_003',
        'organizadorId': 'uid_jug_5',
        'deporte': 'basquet',
        'fecha': Timestamp.fromDate(pasado),
        'horaInicio': '17:00',
        'horaFin': '18:00',
        'jugadoresNecesarios': 10,
        'precioMaxPorJugador': 8.0,
        'estado': 'abierto',
        'jugadores': [
          _jugador('uid_jug_5', 'Ana Flores', 'AF'),
          _jugador('uid_jug_6', 'Rosa Ccori', 'RC'),
          _jugador(kUidJugador, 'Carlos Demo', 'CD'),
        ],
        'esDemo': true,
      },
    ];

    final batch = _db.batch();
    for (final p in partidos) {
      final id = p['_id'] as String;
      final data = Map<String, dynamic>.from(p)..remove('_id');
      batch.set(
        _db.collection('partidos').doc(id),
        {...data, 'creadoEn': FieldValue.serverTimestamp()},
      );
    }
    await batch.commit();
    debugPrint('[Seeder] âœ“ ${partidos.length} partidos');
  }

  static Map<String, dynamic> _jugador(
          String uid, String nombre, String iniciales) =>
      {
        'userId': uid,
        'nombre': nombre,
        'avatarUrl': '',
        'iniciales': iniciales,
        'pagado': false,
        'unidoEn': Timestamp.fromDate(DateTime.now()),
      };

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  5. FLASH SLOTS
  //  ColecciÃ³n: flashSlots/{flashSlotId}
  //  Modelo: FlashSlotModel
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //
  //  Campos:
  //    complejoId     String  â€” complejo al que pertenece
  //    canchaId       String  â€” cancha en oferta
  //    fecha          TS      â€” fecha de la oferta (hoy o maÃ±ana)
  //    horaInicio     String  â€” 'HH:MM'
  //    horaFin        String  â€” 'HH:MM'
  //    precioOriginal double  â€” precio normal sin descuento
  //    precioFlash    double  â€” precio con descuento
  //    descuentoPct   int     â€” porcentaje de descuento (ej: 40 = 40%)
  //    expiraEn       TS      â€” cuÃ¡ndo expira la oferta
  //    estado         String  â€” 'activo' | 'reservado' | 'expirado'
  //    vistasCount    int     â€” cuÃ¡ntos usuarios vieron la oferta
  //    creadoPor      String  â€” 'admin' | 'ia_automatico'
  //    esDemo         bool
  //    creadoEn       TS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<void> _seedFlashSlots() async {
    final ahora = DateTime.now();
    final hoy   = DateTime(ahora.year, ahora.month, ahora.day);

    final slots = [
      _flashSlot('flash_001', _c1, _kTF5a, hoy,
          '14:00', '15:00', 50.0, 30.0, 40,
          ahora.add(const Duration(hours: 4))),
      _flashSlot('flash_002', _c2, _kCF5a, hoy,
          '16:00', '17:00', 45.0, 27.0, 40,
          ahora.add(const Duration(hours: 6))),
      _flashSlot('flash_003', _c5, _kIF5a, hoy,
          '21:00', '22:00', 55.0, 33.0, 40,
          ahora.add(const Duration(hours: 9))),
    ];

    final batch = _db.batch();
    for (final s in slots) {
      final id = s['_id'] as String;
      final data = Map<String, dynamic>.from(s)..remove('_id');
      batch.set(
        _db.collection('flashSlots').doc(id),
        {...data, 'creadoEn': FieldValue.serverTimestamp()},
      );
    }
    await batch.commit();
    debugPrint('[Seeder] âœ“ ${slots.length} flash slots');
  }

  static Map<String, dynamic> _flashSlot(
    String id,
    String complejoId,
    String canchaId,
    DateTime fecha,
    String horaInicio,
    String horaFin,
    double precioOriginal,
    double precioFlash,
    int descuentoPct,
    DateTime expiraEn,
  ) =>
      {
        '_id': id,
        'complejoId': complejoId,
        'canchaId': canchaId,
        'fecha': Timestamp.fromDate(fecha),
        'horaInicio': horaInicio,
        'horaFin': horaFin,
        'precioOriginal': precioOriginal,
        'precioFlash': precioFlash,
        'descuentoPct': descuentoPct,
        'expiraEn': Timestamp.fromDate(expiraEn),
        'estado': 'activo',    // activo | reservado | expirado
        'vistasCount': 0,
        'creadoPor': 'admin',  // admin | ia_automatico
        'esDemo': true,
      };

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  6. PREDICCIONES IA
  //  ColecciÃ³n: prediccionesIA/{complejoId}_{semana}
  //  Modelo: PrediccionIAModel
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //
  //  Campos:
  //    complejoId      String            â€” ID del complejo
  //    semana          String            â€” 'YYYY-Wnn' (ej: '2026-W22')
  //    precision       double            â€” precisiÃ³n del modelo 0..1
  //    heatmap         Map<String,double>â€” ocupaciÃ³n por hora 0..1
  //                    Keys: '07:00'..'22:00' (cada hora)
  //                    Values: 0.0 (vacÃ­o) .. 1.0 (lleno)
  //    preciosDinamicos List             â€” ajustes de precio por hora
  //                    horaInicio: 'HH:MM'
  //                    multiplicador: double (0.8=descuento, 1.4=pico)
  //                    precioSugerido: double (en S/)
  //    generadoEn      TS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<void> _seedPrediccionesIA() async {
    final semana = _semanaISO(DateTime.now());

    // Datos de heatmap realistas para Huancayo:
    // maÃ±anas bajas, tarde media, noche alta (18-21h pico)
    const heatmap = {
      '07:00': 0.10,
      '08:00': 0.20,
      '09:00': 0.25,
      '10:00': 0.35,
      '11:00': 0.40,
      '12:00': 0.55,
      '13:00': 0.50,
      '14:00': 0.45,
      '15:00': 0.60,
      '16:00': 0.70,
      '17:00': 0.85,
      '18:00': 0.95,
      '19:00': 1.00,
      '20:00': 0.90,
      '21:00': 0.75,
      '22:00': 0.40,
    };

    // Precios dinÃ¡micos: descuento en horas bajas, recargo en pico
    const preciosDinamicos = [
      {'horaInicio': '07:00', 'multiplicador': 0.75, 'precioSugerido': 30.0},
      {'horaInicio': '09:00', 'multiplicador': 0.85, 'precioSugerido': 34.0},
      {'horaInicio': '12:00', 'multiplicador': 1.00, 'precioSugerido': 40.0},
      {'horaInicio': '15:00', 'multiplicador': 1.10, 'precioSugerido': 44.0},
      {'horaInicio': '17:00', 'multiplicador': 1.25, 'precioSugerido': 50.0},
      {'horaInicio': '19:00', 'multiplicador': 1.40, 'precioSugerido': 56.0},
      {'horaInicio': '21:00', 'multiplicador': 1.15, 'precioSugerido': 46.0},
    ];

    final precisiones = {
      _c1: 0.87,
      _c2: 0.82,
      _c3: 0.79,
      _c4: 0.74,
      _c5: 0.91,
    };

    final batch = _db.batch();
    for (final entry in precisiones.entries) {
      final docId = '${entry.key}_$semana';
      batch.set(_db.collection('prediccionesIA').doc(docId), {
        'complejoId': entry.key,
        'semana': semana,
        'precision': entry.value,
        'heatmap': heatmap,
        'preciosDinamicos': preciosDinamicos,
        'generadoEn': FieldValue.serverTimestamp(),
        'esDemo': true,
      });
    }
    await batch.commit();
    debugPrint('[Seeder] âœ“ ${precisiones.length} predicciones IA');
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  7. RESEÃ‘AS
  //  ColecciÃ³n: resenas/{resenaId}
  //  (No hay modelo explÃ­cito, usamos la estructura del repositorio)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //
  //  Campos:
  //    complejoId     String  â€” complejo reseÃ±ado
  //    userId         String  â€” UID del jugador
  //    userName       String  â€” nombre del jugador
  //    userAvatar     String  â€” URL avatar (vacÃ­o si no tiene)
  //    reservaId      String  â€” reserva que originÃ³ la reseÃ±a
  //    calificacion   double  â€” 1.0 .. 5.0
  //    comentario     String  â€” texto de la reseÃ±a
  //    respuestaDueno String? â€” respuesta del dueÃ±o (opcional)
  //    fecha          TS      â€” cuÃ¡ndo se publicÃ³
  //    esDemo         bool
  //    creadoEn       TS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<void> _seedResenas() async {
    final ahora = DateTime.now();
    final hace2 = ahora.subtract(const Duration(days: 2));
    final hace5 = ahora.subtract(const Duration(days: 5));
    final hace8 = ahora.subtract(const Duration(days: 8));
    final hace12 = ahora.subtract(const Duration(days: 12));

    final resenas = [
      {
        '_id': 'resena_001',
        'complejoId': _c1,
        'userId': kUidJugador,
        'userName': 'Carlos Demo',
        'userAvatar': '',
        'reservaId': 'res_t_004',
        'calificacion': 5.0,
        'comentario':
            'Excelente cancha. La iluminaciÃ³n LED es perfecta para jugar de '
            'noche. Los vestuarios muy limpios. VolverÃ­a sin dudarlo.',
        'respuestaDueno': 'Â¡Gracias Carlos! Te esperamos pronto ðŸ™Œ',
        'fecha': Timestamp.fromDate(hace2),
        'esDemo': true,
      },
      {
        '_id': 'resena_002',
        'complejoId': _c1,
        'userId': kUidJugador,
        'userName': 'Carlos Demo',
        'userAvatar': '',
        'reservaId': 'res_t_009',
        'calificacion': 4.0,
        'comentario':
            'Muy buena cancha, el pasto sintÃ©tico estÃ¡ en buen estado. '
            'Solo mejorarÃ­a el estacionamiento que a veces estÃ¡ lleno.',
        'fecha': Timestamp.fromDate(hace5),
        'esDemo': true,
      },
      {
        '_id': 'resena_003',
        'complejoId': _c2,
        'userId': kUidJugador,
        'userName': 'Carlos Demo',
        'userAvatar': '',
        'reservaId': 'res_c_001',
        'calificacion': 5.0,
        'comentario':
            'La mejor cancha de grass natural en Huancayo. Se siente increÃ­ble '
            'jugar en pasto real. El personal muy atento.',
        'respuestaDueno': 'Muchas gracias por tu comentario. Nos esforzamos cada dÃ­a.',
        'fecha': Timestamp.fromDate(hace5),
        'esDemo': true,
      },
      {
        '_id': 'resena_004',
        'complejoId': _c3,
        'userId': kUidJugador,
        'userName': 'Carlos Demo',
        'userAvatar': '',
        'reservaId': 'res_a_001',
        'calificacion': 4.0,
        'comentario':
            'Buena ubicaciÃ³n, precio justo y trato amable. La cancha podrÃ­a '
            'tener iluminaciÃ³n para jugar de noche.',
        'fecha': Timestamp.fromDate(hace8),
        'esDemo': true,
      },
      {
        '_id': 'resena_005',
        'complejoId': _c5,
        'userId': kUidJugador,
        'userName': 'Carlos Demo',
        'userAvatar': '',
        'reservaId': 'res_i_001',
        'calificacion': 5.0,
        'comentario':
            'El indoor es perfecto para no depender del clima. La pista estÃ¡ '
            'siempre limpia y bien mantenida. El WiFi funciona excelente.',
        'respuestaDueno': 'Â¡AsÃ­ es! Disponibles los 365 dÃ­as sin importar el clima ðŸŒŸ',
        'fecha': Timestamp.fromDate(hace12),
        'esDemo': true,
      },
    ];

    final batch = _db.batch();
    for (final r in resenas) {
      final id = r['_id'] as String;
      final data = Map<String, dynamic>.from(r)..remove('_id');
      batch.set(
        _db.collection('resenas').doc(id),
        {...data, 'creadoEn': FieldValue.serverTimestamp()},
      );
    }
    await batch.commit();
    debugPrint('[Seeder] âœ“ ${resenas.length} reseÃ±as');
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  UTILIDADES
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  /// Semana ISO: '2026-W22'
  static String _semanaISO(DateTime d) {
    final dias = d.difference(DateTime(d.year, 1, 1)).inDays;
    return '${d.year}-W${((dias / 7).ceil()).toString().padLeft(2, '0')}';
  }

  /// CÃ³digo de acceso derivado del ID (sin UUID para ser reproducible)
  static String _codigoAcceso(String id) {
    final hash = id.hashCode.abs().toRadixString(16).padLeft(8, '0');
    return 'AT-${hash.toUpperCase()}';
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  VERIFICACIÃ“N
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  /// Retorna true si ya existen datos en Firestore.
  static Future<bool> yaEjecutado() async {
    final snap = await _db
        .collection('complejos')
        .where('activo', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return false;
    // Verificar que tambiÃ©n haya canchas
    final canchas = await _db
        .collection('complejos/${snap.docs.first.id}/canchas')
        .where('activa', isEqualTo: true)
        .limit(1)
        .get();
    return canchas.docs.isNotEmpty;
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  LIMPIEZA
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  /// Borra los usuarios demo (esDemo == true) que dejÃ³ el seeder anterior.
  /// NO elimina usuarios reales registrados por el usuario de la app.
  static Future<void> limpiarUsuariosDemo() async {
    try {
      final snap = await _db
          .collection('usuarios')
          .where('esDemo', isEqualTo: true)
          .get();
      if (snap.docs.isEmpty) {
        debugPrint('[Seeder] âœ“ No hay usuarios demo que limpiar');
        return;
      }
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('[Seeder] âœ“ ${snap.docs.length} usuarios demo eliminados');
    } catch (e) {
      debugPrint('[Seeder] âš  No se pudo limpiar usuarios demo: $e');
    }
  }

  /// Borra todos los datos del seed (no toca usuarios reales).
  static Future<void> limpiar() async {
    debugPrint('[Seeder] ðŸ—‘  Limpiandoâ€¦');

    // Complejos + canchas
    for (final cId in [_c1, _c2, _c3, _c4, _c5]) {
      try {
        final canchas = await _db.collection('complejos/$cId/canchas').get();
        if (canchas.docs.isNotEmpty) {
          final b = _db.batch();
          for (final d in canchas.docs) { b.delete(d.reference); }
          await b.commit();
        }
        await _db.doc('complejos/$cId').delete();
      } catch (e) {
        debugPrint('[Seeder] âš  $cId: $e');
      }
    }

    // Colecciones con IDs fijos
    final fijos = <String, List<String>>{
      'reservas': [
        'res_t_001','res_t_002','res_t_003','res_t_004','res_t_005',
        'res_t_006','res_t_007','res_t_008','res_t_009','res_t_010',
        'res_t_011','res_t_012','res_t_013','res_t_014','res_t_015',
        'res_c_001','res_a_001','res_i_001',
      ],
      'partidos': ['partido_demo_001','partido_demo_002','partido_demo_003'],
      'flashSlots': ['flash_001','flash_002','flash_003'],
      'resenas': ['resena_001','resena_002','resena_003','resena_004','resena_005'],
    };

    for (final entry in fijos.entries) {
      try {
        final b = _db.batch();
        for (final id in entry.value) {
          b.delete(_db.collection(entry.key).doc(id));
        }
        await b.commit();
      } catch (e) {
        debugPrint('[Seeder] âš  ${entry.key}: $e');
      }
    }

    // prediccionesIA por query (IDs dinÃ¡micos segÃºn semana)
    try {
      final snap = await _db
          .collection('prediccionesIA')
          .where('esDemo', isEqualTo: true)
          .get();
      if (snap.docs.isNotEmpty) {
        final b = _db.batch();
        for (final d in snap.docs) { b.delete(d.reference); }
        await b.commit();
      }
    } catch (e) {
      debugPrint('[Seeder] âš  prediccionesIA: $e');
    }

    debugPrint('[Seeder] âœ… Limpieza completada');
  }
}

