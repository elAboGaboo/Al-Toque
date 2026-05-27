// core/services/database_seeder.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// ── Credencial de demo — devuelta al SeedScreen para mostrar al usuario ──────
class DemoCredencial {
  final String nombre;
  final String email;
  final String password;
  final String rol;
  final String? complejo; // nombre del complejo (solo dueños)
  const DemoCredencial({
    required this.nombre,
    required this.email,
    required this.password,
    required this.rol,
    this.complejo,
  });
}

// ── Definición interna de una cuenta demo ─────────────────────────────────────
class _CuentaDef {
  final String key;       // clave lógica: 'd1'..'d5', 'u1'..'u9'
  final String email;
  final String nombre;
  final String iniciales;
  final String rol;       // 'dueno' | 'jugador'
  final String? complejoId;
  final String? complejoNombre;
  const _CuentaDef(this.key, this.email, this.nombre, this.iniciales,
      this.rol, this.complejoId, this.complejoNombre);
}

/// Pobla Firestore con datos de demostración reales de Huancayo.
/// Crea cuentas Firebase Auth reales + documentos Firestore correctamente
/// vinculados entre sí.
class DatabaseSeeder {
  DatabaseSeeder._();

  static final _db   = FirebaseFirestore.instance;
  static const _pass = 'AlToque2024!'; // contraseña para todas las cuentas demo

  // ── IDs fijos — Complejos ─────────────────────────────────────────────────
  static const _c1 = 'complejo_tambo_sport';
  static const _c2 = 'complejo_sport_center_chilca';
  static const _c3 = 'complejo_los_andes';
  static const _c4 = 'complejo_shullcas_fc';
  static const _c5 = 'complejo_indoor_huancayo';

  // ── IDs fijos — Canchas ───────────────────────────────────────────────────
  static const kTamboF5a   = 'k_tambo_f5a';
  static const kTamboF5b   = 'k_tambo_f5b';
  static const kTamboF7    = 'k_tambo_f7';
  static const kTamboBas   = 'k_tambo_bas';
  static const kChilcaF5a  = 'k_chilca_f5a';
  static const kChilcaF5b  = 'k_chilca_f5b';
  static const kChilcaF7   = 'k_chilca_f7';
  static const kAndesF5a   = 'k_andes_f5a';
  static const kAndesF5b   = 'k_andes_f5b';
  static const kAndesVol   = 'k_andes_vol';
  static const kShullcasF7 = 'k_shullcas_f7';
  static const kShullcasF5 = 'k_shullcas_f5';
  static const kIndoorF5a  = 'k_indoor_f5a';
  static const kIndoorF5b  = 'k_indoor_f5b';
  static const kIndoorBas  = 'k_indoor_bas';
  static const kIndoorVol  = 'k_indoor_vol';

  // ── Definición de las 14 cuentas demo ────────────────────────────────────
  static final _cuentasDefs = <_CuentaDef>[
    _CuentaDef('d1','juan.huaman@demo.pe',    'Juan Huamán',    'JH','dueno',  _c1,'El Tambo Sport'),
    _CuentaDef('d2','maria.ccori@demo.pe',    'María Ccori',    'MC','dueno',  _c2,'Sport Center Chilca'),
    _CuentaDef('d3','roberto.quispe@demo.pe', 'Roberto Quispe', 'RQ','dueno',  _c3,'Los Andes FC'),
    _CuentaDef('d4','carmen.palomino@demo.pe','Carmen Palomino','CP','dueno',  _c4,'Shullcas FC'),
    _CuentaDef('d5','jorge.flores@demo.pe',   'Jorge Flores',   'JF','dueno',  _c5,'Indoor Sport'),
    _CuentaDef('u1','carlos.mamani@demo.pe',  'Carlos Mamani',  'CM','jugador',null,null),
    _CuentaDef('u2','luis.quispe@demo.pe',    'Luis Quispe',    'LQ','jugador',null,null),
    _CuentaDef('u3','pedro.huanca@demo.pe',   'Pedro Huanca',   'PH','jugador',null,null),
    _CuentaDef('u4','miguel.torres@demo.pe',  'Miguel Torres',  'MT','jugador',null,null),
    _CuentaDef('u5','jose.palomino@demo.pe',  'José Palomino',  'JP','jugador',null,null),
    _CuentaDef('u6','ana.flores@demo.pe',     'Ana Flores',     'AF','jugador',null,null),
    _CuentaDef('u7','rosa.ccori@demo.pe',     'Rosa Ccori',     'RC','jugador',null,null),
    _CuentaDef('u8','jhon.poma@demo.pe',      'Jhon Poma',      'JP','jugador',null,null),
    _CuentaDef('u9','david.suarez@demo.pe',   'David Suarez',   'DS','jugador',null,null),
  ];

  // ── App secundaria de Firebase (para crear cuentas sin cerrar la sesión activa)
  static FirebaseApp? _auxApp;
  static Future<FirebaseApp> _getAuxApp() async {
    if (_auxApp != null) return _auxApp!;
    try {
      _auxApp = Firebase.app('seeder_aux');
    } catch (_) {
      _auxApp = await Firebase.initializeApp(
        name: 'seeder_aux',
        options: Firebase.app().options,
      );
    }
    return _auxApp!;
  }

  // ── Entry point ───────────────────────────────────────────────────────────

  /// Ejecuta el seed completo y devuelve la lista de credenciales demo.
  static Future<List<DemoCredencial>> ejecutar({String? duenoUid}) async {
    debugPrint('[Seeder] Iniciando seed…');

    // 0. Garantizar que el dueño logueado tiene doc en Firestore.
    //    isDueno() en las reglas lo necesita para autorizar las escrituras.
    await _ensureDuenoDoc();

    // 1. Crear cuentas Firebase Auth + obtener sus UIDs reales
    final uids = await _crearCuentas();

    // 2. Crear documentos Firestore
    await _seedUsuarios(uids);
    await _seedComplejos(uids);
    await _seedCanchas();
    await _seedReservas(uids);
    await _seedPartidos(uids);
    await _seedFlashSlots();
    await _seedPrediccionesIA();
    await _seedResenas(uids);

    debugPrint('[Seeder] ✅ Seed completado.');

    // 3. Devolver credenciales para mostrar en pantalla
    return _cuentasDefs.map((c) => DemoCredencial(
      nombre: c.nombre,
      email: c.email,
      password: _pass,
      rol: c.rol,
      complejo: c.complejoNombre,
    )).toList();
  }

  // ── Garantizar doc del dueño logueado ────────────────────────────────────
  // Si Firestore está vacío (primera vez o después de limpiar), el usuario
  // activo no tiene documento → isDueno() devuelve false → todo falla.
  // Esta función crea el documento con isOwner(uid), que siempre funciona.

  static Future<void> _ensureDuenoDoc() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay usuario logueado');

    final ref = _db.collection('usuarios').doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      // Primera vez — crear doc completo con rol: 'dueno'
      debugPrint('[Seeder] ⚠️ Dueño sin doc en Firestore. Creando…');
      final nombre = user.displayName
          ?? user.email?.split('@').first
          ?? 'Dueño';
      final iniciales = nombre
          .split(' ')
          .where((w) => w.isNotEmpty)
          .take(2)
          .map((w) => w[0].toUpperCase())
          .join();
      await ref.set({
        'nombre': nombre,
        'email': user.email ?? '',
        'iniciales': iniciales,
        'rol': 'dueno',
        'avatarUrl': '',
        'complejoId': null,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      debugPrint('[Seeder] ✓ Doc dueño creado: ${user.uid}');
    } else if (doc.data()?['rol'] != 'dueno') {
      // Doc existe pero con rol incorrecto (jugador u otro) — corregir
      debugPrint('[Seeder] ⚠️ Doc dueño con rol="${doc.data()?['rol']}". Actualizando…');
      await ref.update({'rol': 'dueno'});
      debugPrint('[Seeder] ✓ Rol actualizado a dueno: ${user.uid}');
    } else {
      debugPrint('[Seeder] ✓ Doc dueño ya existe con rol correcto: ${user.uid}');
    }
  }

  // ── Crear cuentas Firebase Auth ───────────────────────────────────────────
  // Usa una app secundaria para no cerrar la sesión del dueño activo.
  // Si la cuenta ya existe (seed anterior), se recupera su UID vía signIn.

  static Future<Map<String, String>> _crearCuentas() async {
    final auxApp = await _getAuxApp();
    final auth   = FirebaseAuth.instanceFor(app: auxApp);
    final uids   = <String, String>{};

    for (final c in _cuentasDefs) {
      String uid;
      try {
        final cred = await auth.createUserWithEmailAndPassword(
            email: c.email, password: _pass);
        uid = cred.user!.uid;
        debugPrint('[Seeder] ✓ Creada cuenta ${c.email} → $uid');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Ya existe — obtenemos el UID iniciando sesión
          final cred = await auth.signInWithEmailAndPassword(
              email: c.email, password: _pass);
          uid = cred.user!.uid;
          debugPrint('[Seeder] ✓ Cuenta existente ${c.email} → $uid');
        } else {
          rethrow;
        }
      }
      uids[c.key] = uid;
    }

    debugPrint('[Seeder] ✓ ${uids.length} cuentas Auth listas');
    return uids;
  }

  // ── Teléfono y DNI por jugador ────────────────────────────────────────────
  static const _telefonoJugador = {
    'u1': '987 111 001', 'u2': '987 111 002', 'u3': '987 111 003',
    'u4': '987 111 004', 'u5': '987 111 005', 'u6': '987 111 006',
    'u7': '987 111 007', 'u8': '987 111 008', 'u9': '987 111 009',
  };

  static const _dniJugador = {
    'u1': '45231876', 'u2': '72984531', 'u3': '61045892',
    'u4': '48792013', 'u5': '73561024', 'u6': '60123745',
    'u7': '41897632', 'u8': '79043158', 'u9': '52874061',
  };

  // ── Datos de complejo por clave de dueño (para desnormalización en usuario) ─
  static const _complejoInfoPorDueno = {
    'd1': {'nombre': 'El Tambo Sport',       'canchas': 4, 'lat': -12.0478, 'lng': -75.2107},
    'd2': {'nombre': 'Sport Center Chilca',  'canchas': 3, 'lat': -12.0890, 'lng': -75.1978},
    'd3': {'nombre': 'Los Andes Fútbol Club','canchas': 3, 'lat': -12.0651, 'lng': -75.2049},
    'd4': {'nombre': 'Shullcas FC',          'canchas': 2, 'lat': -12.0520, 'lng': -75.1890},
    'd5': {'nombre': 'Indoor Sport Huancayo','canchas': 4, 'lat': -12.0700, 'lng': -75.2100},
  };

  // ── 0. Usuarios (Firestore) ────────────────────────────────────────────────

  static Future<void> _seedUsuarios(Map<String, String> uids) async {
    final batch = _db.batch();

    for (final c in _cuentasDefs) {
      final uid = uids[c.key]!;

      // Campos base — exactamente los del UsuarioModel
      final data = <String, dynamic>{
        'nombre'   : c.nombre,
        'iniciales': c.iniciales,
        'email'    : c.email,
        'telefono' : c.rol == 'jugador' ? (_telefonoJugador[c.key] ?? '') : '',
        'dni'      : c.rol == 'jugador' ? (_dniJugador[c.key]     ?? '') : '',
        'avatarUrl': '',
        'rol'      : c.rol,
        // Campos de dueño (null/0 para jugadores)
        'complejoId'    : c.complejoId,
        'nombreComplejo': null,
        'numeroCanchas' : 0,
        'ubicacionLat'  : null,
        'ubicacionLng'  : null,
        // Metadato del seeder
        'esDemo'  : true,
        'creadoEn': FieldValue.serverTimestamp(),
      };

      // Desnormalización del complejo en el doc del dueño
      if (c.rol == 'dueno') {
        final info = _complejoInfoPorDueno[c.key];
        if (info != null) {
          data['nombreComplejo'] = info['nombre'];
          data['numeroCanchas']  = info['canchas'];
          data['ubicacionLat']   = info['lat'];
          data['ubicacionLng']   = info['lng'];
        }
      }

      batch.set(_db.collection('usuarios').doc(uid), data);
    }

    await batch.commit();
    debugPrint('[Seeder] ✓ ${_cuentasDefs.length} usuarios en Firestore');
  }

  // ── 1. Complejos ──────────────────────────────────────────────────────────

  static Future<void> _seedComplejos(Map<String, String> uids) async {
    final datos = [
      _complejo(id: _c1, duenoUid: uids['d1']!,
        nombre: 'El Tambo Sport',
        descripcion: 'El complejo más grande de El Tambo con 4 canchas sintéticas de última generación con iluminación LED.',
        direccion: 'Av. Mariscal Castilla 2150, El Tambo',
        lat: -12.0478, lng: -75.2107, apertura: '07:00', cierre: '23:00',
        imagenes: ['https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
                   'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800']),
      _complejo(id: _c2, duenoUid: uids['d2']!,
        nombre: 'Sport Center Chilca',
        descripcion: 'Complejo premium con canchas de grass natural y sintético. Cafetería, vestuarios modernos y estacionamiento propio.',
        direccion: 'Jr. Los Ángeles 340, Chilca',
        lat: -12.0890, lng: -75.1978, apertura: '06:00', cierre: '22:00',
        imagenes: ['https://images.unsplash.com/photo-1459865264687-595d652de67e?w=800',
                   'https://images.unsplash.com/photo-1518604666860-9ed391f76460?w=800']),
      _complejo(id: _c3, duenoUid: uids['d3']!,
        nombre: 'Los Andes Fútbol Club',
        descripcion: 'Complejo familiar en el corazón de Huancayo. Tarifas competitivas para todos los niveles.',
        direccion: 'Av. Ferrocarril 890, Huancayo Centro',
        lat: -12.0651, lng: -75.2049, apertura: '08:00', cierre: '22:00',
        imagenes: ['https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?w=800']),
      _complejo(id: _c4, duenoUid: uids['d4']!,
        nombre: 'Shullcas FC',
        descripcion: 'Canchas de grass natural en zona tranquila de San Carlos. Ideal para fútbol 7.',
        direccion: 'Av. Shullcas 450, San Carlos',
        lat: -12.0520, lng: -75.1890, apertura: '07:00', cierre: '21:00',
        imagenes: ['https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=800']),
      _complejo(id: _c5, duenoUid: uids['d5']!,
        nombre: 'Indoor Sport Huancayo',
        descripcion: 'El único complejo indoor de Huancayo. Canchas cubiertas, WiFi y cafetería.',
        direccion: 'Jr. Ancash 120, Huancayo Centro',
        lat: -12.0700, lng: -75.2100, apertura: '08:00', cierre: '23:00',
        imagenes: ['https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800',
                   'https://images.unsplash.com/photo-1515523110800-9415d13b84a8?w=800']),
    ];

    final batch = _db.batch();
    for (final doc in datos) {
      final id = doc['id'] as String;
      final data = Map<String, dynamic>.from(doc)..remove('id');
      batch.set(_db.collection('complejos').doc(id),
          {...data, 'creadoEn': FieldValue.serverTimestamp()});
    }
    await batch.commit();
    debugPrint('[Seeder] ✓ ${datos.length} complejos');
  }

  static Map<String, dynamic> _complejo({
    required String id, required String duenoUid,
    required String nombre, required String descripcion,
    required String direccion, required double lat, required double lng,
    required String apertura, required String cierre,
    required List<String> imagenes,
  }) => {
    'id'             : id,
    'nombre'         : nombre,
    'descripcion'    : descripcion,
    'direccion'      : direccion,
    'ciudad'         : 'Huancayo',
    'lat'            : lat,
    'lng'            : lng,
    'horarioApertura': apertura,
    'horarioCierre'  : cierre,
    'imagenes'       : imagenes,
    'duenoUid'       : duenoUid,
    'activo'         : true,
    'esDemo'         : true,
  };

  // ── 2. Canchas ────────────────────────────────────────────────────────────

  static Future<void> _seedCanchas() async {
    final map = <String, List<Map<String, dynamic>>>{
      _c1: [
        _cancha(_c1, kTamboF5a,  'Cancha 1',       'futbol5','sintetico',10,50.0,ilum:true),
        _cancha(_c1, kTamboF5b,  'Cancha 2',       'futbol5','sintetico',10,50.0,ilum:true),
        _cancha(_c1, kTamboF7,   'Cancha 3',       'futbol7','sintetico',14,70.0,ilum:true),
        _cancha(_c1, kTamboBas,  'Básquet A',      'basquet','cemento',  10,40.0,ilum:true),
      ],
      _c2: [
        _cancha(_c2, kChilcaF5a, 'Cancha 1',       'futbol5','sintetico',10,45.0,ilum:true),
        _cancha(_c2, kChilcaF5b, 'Cancha 2',       'futbol5','sintetico',10,45.0),
        _cancha(_c2, kChilcaF7,  'Cancha Grande',  'futbol7','grass',    14,80.0,ilum:true),
      ],
      _c3: [
        _cancha(_c3, kAndesF5a,  'Cancha Principal','futbol5','sintetico',10,40.0),
        _cancha(_c3, kAndesF5b,  'Cancha 2',       'futbol5','cemento',  10,30.0),
        _cancha(_c3, kAndesVol,  'Voley Indoor',   'voley',  'cemento',  12,35.0,techo:true,ilum:true),
      ],
      _c4: [
        _cancha(_c4, kShullcasF7,'Cancha Grass',   'futbol7','grass',    14,60.0),
        _cancha(_c4, kShullcasF5,'Fútbol 5',       'futbol5','sintetico',10,38.0),
      ],
      _c5: [
        _cancha(_c5, kIndoorF5a, 'Pista Indoor A', 'futbol5','sintetico',10,55.0,techo:true,ilum:true),
        _cancha(_c5, kIndoorF5b, 'Pista Indoor B', 'futbol5','sintetico',10,55.0,techo:true,ilum:true),
        _cancha(_c5, kIndoorBas, 'Básquet Indoor', 'basquet','cemento',  10,45.0,techo:true,ilum:true),
        _cancha(_c5, kIndoorVol, 'Voley Indoor',   'voley',  'cemento',  12,40.0,techo:true,ilum:true),
      ],
    };

    for (final entry in map.entries) {
      final batch = _db.batch();
      for (final c in entry.value) {
        final id = c['_id'] as String;
        final data = Map<String, dynamic>.from(c)..remove('_id');
        batch.set(_db.collection('complejos/${entry.key}/canchas').doc(id),
            {...data, 'creadoEn': FieldValue.serverTimestamp()});
      }
      await batch.commit();
    }
    debugPrint('[Seeder] ✓ ${map.values.fold(0,(s,l)=>s+l.length)} canchas');
  }

  static Map<String, dynamic> _cancha(
    String cId, String kId, String nombre,
    String deporte, String superficie, int cap, double precio, {
    bool techo = false, bool ilum = false,
  }) => {
    '_id': kId, 'complejoId': cId, 'nombre': nombre,
    'deporte': deporte, 'superficie': superficie,
    'capacidad': cap, 'precioBase': precio,
    'activa': true, 'techada': techo, 'iluminacion': ilum, 'descripcion': '',
  };

  // ── 3. Reservas ───────────────────────────────────────────────────────────

  static Future<void> _seedReservas(Map<String, String> uids) async {
    final hoy    = DateTime.now();
    final ayer   = hoy.subtract(const Duration(days: 1));
    final hace3  = hoy.subtract(const Duration(days: 3));
    final hace7  = hoy.subtract(const Duration(days: 7));
    final manana = hoy.add(const Duration(days: 1));

    final list = [
      _reserva('reserva_demo_001', uids['u1']!,'Carlos Mamani',   _c1,kTamboF5a,  hoy,   '18:00','19:00',1.0, 50.0,'confirmada','yape'),
      _reserva('reserva_demo_002', uids['u2']!,'Luis Quispe',     _c2,kChilcaF5a, ayer,  '20:00','21:00',1.0, 45.0,'confirmada','plin'),
      _reserva('reserva_demo_003', uids['u3']!,'Pedro Huanca',    _c3,kAndesF5a,  hace7, '16:00','17:00',1.0, 25.0,'confirmada','yape'),
      _reserva('reserva_demo_004', uids['u4']!,'Miguel Torres',   _c5,kIndoorF5a, manana,'19:00','20:00',1.0, 55.0,'pendiente', 'efectivo', partidoId: 'partido_demo_001'),
      _reserva('reserva_demo_005', uids['u1']!,'Carlos Mamani',   _c4,kShullcasF7,hace7, '10:00','11:00',1.0, 60.0,'cancelada', 'tarjeta'),
      _reserva('reserva_demo_006', uids['u5']!,'José Palomino',   _c1,kTamboF7,   hace3, '09:00','10:30',1.5,105.0,'confirmada','yape'),
      _reserva('reserva_demo_007', uids['u6']!,'Ana Flores',      _c2,kChilcaF7,  hoy,   '07:00','08:00',1.0, 80.0,'confirmada','plin'),
    ];

    final batch = _db.batch();
    for (final r in list) {
      final id = r['_id'] as String;
      final data = Map<String, dynamic>.from(r)..remove('_id');
      batch.set(_db.collection('reservas').doc(id),
          {...data, 'creadoEn': FieldValue.serverTimestamp()});
    }
    await batch.commit();
    debugPrint('[Seeder] ✓ ${list.length} reservas');
  }

  static Map<String, dynamic> _reserva(
    String id, String userId, String userName,
    String cId, String kId, DateTime fecha,
    String ini, String fin, double dur, double precio,
    String estado, String pago, {
    String? partidoId,
  }) {
    final data = <String, dynamic>{
      '_id'          : id,
      'userId'       : userId,
      'userName'     : userName,
      'complejoId'   : cId,
      'canchaId'     : kId,
      'fecha'        : Timestamp.fromDate(DateTime(fecha.year, fecha.month, fecha.day)),
      'horaInicio'   : ini,
      'horaFin'      : fin,
      'duracionHoras': dur,
      'precioTotal'  : precio,
      'estado'       : estado,
      'metodoPago'   : pago,
      'codigoAcceso' : _uuid(),
      'esDemo'       : true,
    };
    if (partidoId != null) data['partidoId'] = partidoId;
    return data;
  }

  // ── 4. Partidos ───────────────────────────────────────────────────────────

  static Future<void> _seedPartidos(Map<String, String> uids) async {
    final manana = DateTime.now().add(const Duration(days: 1));
    final pasado = DateTime.now().add(const Duration(days: 2));

    final list = [
      _partido('partido_demo_001', uids['u1']!,'Carlos Mamani', 'futbol5', manana,'18:00','19:00',10,15.0,[
        _pj(uids['u1']!,'Carlos Mamani','CM'),
        _pj(uids['u2']!,'Luis Quispe',  'LQ'),
        _pj(uids['u3']!,'Pedro Huanca', 'PH'),
      ]),
      _partido('partido_demo_002', uids['u4']!,'Miguel Torres',  'futbol7', manana,'20:00','21:30',14,12.0,[
        _pj(uids['u4']!,'Miguel Torres', 'MT'),
        _pj(uids['u5']!,'José Palomino', 'JP'),
        _pj(uids['u8']!,'Jhon Poma',     'JP'),
      ]),
      _partido('partido_demo_003', uids['u6']!,'Ana Flores',    'basquet', pasado,'17:00','18:00',10, 8.0,[
        _pj(uids['u6']!,'Ana Flores',   'AF'),
        _pj(uids['u7']!,'Rosa Ccori',   'RC'),
        _pj(uids['u8']!,'Jhon Poma',    'JP'),
        _pj(uids['u9']!,'David Suarez', 'DS'),
      ]),
    ];

    final batch = _db.batch();
    for (final p in list) {
      final id = p['_id'] as String;
      final data = Map<String, dynamic>.from(p)..remove('_id');
      batch.set(_db.collection('partidos').doc(id),
          {...data, 'creadoEn': FieldValue.serverTimestamp()});
    }
    await batch.commit();
    debugPrint('[Seeder] ✓ ${list.length} partidos');
  }

  static Map<String, dynamic> _partido(
    String id, String orgId, String orgNombre,
    String deporte, DateTime fecha, String ini, String fin,
    int nec, double precio, List<Map<String,dynamic>> jug,
  ) => {
    '_id': id, 'organizadorId': orgId, 'organizadorNombre': orgNombre,
    'deporte': deporte,
    'fecha': Timestamp.fromDate(DateTime(fecha.year, fecha.month, fecha.day)),
    'horaInicio': ini, 'horaFin': fin,
    'jugadoresNecesarios': nec,
    // jugadoresActuales NO se guarda — es un getter calculado de jugadores.length
    'precioMaxPorJugador': precio, 'estado': 'abierto', 'jugadores': jug,
    'esDemo': true,
  };

  static Map<String, dynamic> _pj(String uid, String nombre, String ini) => {
    'userId': uid, 'nombre': nombre, 'iniciales': ini,
    'avatarUrl': '', 'pagado': false,
    'unidoEn': Timestamp.fromDate(DateTime.now()),
  };

  // ── 5. Flash Slots ────────────────────────────────────────────────────────

  static Future<void> _seedFlashSlots() async {
    final ahora = DateTime.now();
    final hoy   = DateTime(ahora.year, ahora.month, ahora.day);

    final list = [
      _slot('flash_demo_001',_c1,kTamboF5a, hoy,'14:00','15:00',50.0,30.0,40,ahora.add(const Duration(hours:3))),
      _slot('flash_demo_002',_c3,kAndesF5a, hoy,'16:00','17:00',40.0,25.0,37,ahora.add(const Duration(hours:5))),
      _slot('flash_demo_003',_c5,kIndoorF5a,hoy,'21:00','22:00',55.0,35.0,36,ahora.add(const Duration(hours:8))),
    ];

    final batch = _db.batch();
    for (final s in list) {
      final id = s['_id'] as String;
      final data = Map<String, dynamic>.from(s)..remove('_id');
      batch.set(_db.collection('flashSlots').doc(id),
          {...data, 'creadoEn': FieldValue.serverTimestamp()});
    }
    await batch.commit();
    debugPrint('[Seeder] ✓ ${list.length} flash slots');
  }

  static Map<String, dynamic> _slot(
    String id, String cId, String kId, DateTime fecha,
    String ini, String fin, double orig, double flash, int pct, DateTime exp,
  ) => {
    '_id': id, 'complejoId': cId, 'canchaId': kId,
    'fecha': Timestamp.fromDate(fecha),
    'horaInicio': ini, 'horaFin': fin,
    'precioOriginal': orig, 'precioFlash': flash, 'descuentoPct': pct,
    'expiraEn': Timestamp.fromDate(exp), 'estado': 'activo',
    'vistasCount': 0, 'creadoPor': 'seed', 'esDemo': true,
  };

  // ── 6. Predicciones IA ────────────────────────────────────────────────────

  static Future<void> _seedPrediccionesIA() async {
    final semana = _semanaISO(DateTime.now());
    final batch  = _db.batch();
    for (final entry in {_c1:0.84,_c2:0.79,_c3:0.91,_c4:0.72,_c5:0.88}.entries) {
      batch.set(_db.collection('prediccionesIA').doc('${entry.key}_$semana'), {
        'complejoId': entry.key, 'semana': semana, 'precision': entry.value,
        'heatmap': {'07:00':0.15,'08:00':0.20,'09:00':0.25,'10:00':0.30,
                    '11:00':0.35,'12:00':0.50,'13:00':0.45,'14:00':0.40,
                    '15:00':0.55,'16:00':0.65,'17:00':0.80,'18:00':0.95,
                    '19:00':1.00,'20:00':0.90,'21:00':0.70,'22:00':0.40},
        'preciosDinamicos': [
          {'horaInicio':'07:00','multiplicador':0.80,'precioSugerido':32.0},
          {'horaInicio':'12:00','multiplicador':1.00,'precioSugerido':40.0},
          {'horaInicio':'17:00','multiplicador':1.25,'precioSugerido':50.0},
          {'horaInicio':'19:00','multiplicador':1.40,'precioSugerido':56.0},
          {'horaInicio':'21:00','multiplicador':1.15,'precioSugerido':46.0},
        ],
        'generadoEn': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    debugPrint('[Seeder] ✓ 5 predicciones IA');
  }

  // ── 7. Reseñas ────────────────────────────────────────────────────────────

  static Future<void> _seedResenas(Map<String, String> uids) async {
    final hace3  = DateTime.now().subtract(const Duration(days: 3));
    final hace7  = DateTime.now().subtract(const Duration(days: 7));
    final hace14 = DateTime.now().subtract(const Duration(days: 14));

    final list = [
      {'_id':'resena_demo_001','complejoId':_c1,'userId':uids['u1']!,'userName':'Carlos Mamani',
       'reservaId':'reserva_demo_001','calificacion':5.0,
       'comentario':'Excelente cancha. La iluminación es perfecta para jugar de noche.',
       'respuestaDueno':'¡Gracias Carlos! Te esperamos pronto.',
       'fecha':Timestamp.fromDate(hace3),'avatarUrl':'','esDemo':true},
      {'_id':'resena_demo_002','complejoId':_c1,'userId':uids['u2']!,'userName':'Luis Quispe',
       'reservaId':'reserva_demo_002','calificacion':4.0,
       'comentario':'Muy buena cancha. Los vestuarios podrían estar más limpios.',
       'fecha':Timestamp.fromDate(hace7),'avatarUrl':'','esDemo':true},
      {'_id':'resena_demo_003','complejoId':_c2,'userId':uids['u3']!,'userName':'Pedro Huanca',
       'reservaId':'reserva_demo_003','calificacion':5.0,
       'comentario':'La mejor cancha de Huancayo. El grass natural es increíble.',
       'respuestaDueno':'Muchas gracias Pedro, nos esforzamos cada día.',
       'fecha':Timestamp.fromDate(hace7),'avatarUrl':'','esDemo':true},
      {'_id':'resena_demo_004','complejoId':_c3,'userId':uids['u4']!,'userName':'Miguel Torres',
       'reservaId':'reserva_demo_004','calificacion':4.0,
       'comentario':'Buena ubicación y precio accesible. Recomendado para amistosos.',
       'fecha':Timestamp.fromDate(hace14),'avatarUrl':'','esDemo':true},
      {'_id':'resena_demo_005','complejoId':_c5,'userId':uids['u5']!,'userName':'José Palomino',
       'reservaId':'reserva_demo_004','calificacion':5.0,
       'comentario':'Lo mejor es que es cubierto, puedes jugar aunque llueva.',
       'respuestaDueno':'¡Así es José! Disponibles los 365 días del año.',
       'fecha':Timestamp.fromDate(hace3),'avatarUrl':'','esDemo':true},
    ];

    final batch = _db.batch();
    for (final r in list) {
      final id = r['_id'] as String;
      final data = Map<String, dynamic>.from(r)..remove('_id');
      batch.set(_db.collection('resenas').doc(id),
          {...data, 'creadoEn': FieldValue.serverTimestamp()});
    }
    await batch.commit();
    debugPrint('[Seeder] ✓ ${list.length} reseñas');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _semanaISO(DateTime d) {
    final days = d.difference(DateTime(d.year, 1, 1)).inDays;
    return '${d.year}-W${((days / 7).ceil()).toString().padLeft(2, '0')}';
  }

  static String _uuid() {
    final r = DateTime.now().microsecondsSinceEpoch;
    return [r, r^0xDEAD, r^0xBEEF, r^0xCAFE]
        .map((n) => n.toRadixString(16).padLeft(8, '0')).join('-');
  }

  // ── yaEjecutado ───────────────────────────────────────────────────────────

  static Future<bool> yaEjecutado() async {
    final snap = await _db.collection('complejos')
        .where('activo', isEqualTo: true).limit(1).get();
    if (snap.docs.isEmpty) return false;
    final canchas = await _db
        .collection('complejos/${snap.docs.first.id}/canchas')
        .where('activa', isEqualTo: true).limit(1).get();
    return canchas.docs.isNotEmpty;
  }

  // ── Limpiar ───────────────────────────────────────────────────────────────
  // Nota: las cuentas Firebase Auth NO se eliminan (no es posible desde el cliente).
  // Al re-seedar, se reutilizan las mismas cuentas y UIDs.

  static Future<void> limpiar() async {
    final sinPermiso = <String>[];

    // Usuarios Firestore demo
    try {
      final snap = await _db.collection('usuarios')
          .where('esDemo', isEqualTo: true).get();
      if (snap.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final d in snap.docs) { batch.delete(d.reference); }
        await batch.commit();
      }
    } catch (e) {
      sinPermiso.add('usuarios-demo');
      debugPrint('[Seeder] ⚠️ usuarios-demo: $e');
    }

    // Complejos demo + canchas
    for (final cId in [_c1,_c2,_c3,_c4,_c5]) {
      try {
        final canchas = await _db.collection('complejos/$cId/canchas').get();
        if (canchas.docs.isNotEmpty) {
          final b = _db.batch();
          for (final d in canchas.docs) { b.delete(d.reference); }
          await b.commit();
        }
      } catch (e) {
        sinPermiso.add('canchas/$cId');
        debugPrint('[Seeder] ⚠️ canchas/$cId: $e');
      }
      try {
        await _db.doc('complejos/$cId').delete();
      } catch (e) {
        sinPermiso.add('complejo/$cId');
        debugPrint('[Seeder] ⚠️ complejo/$cId: $e');
      }
    }

    // Colecciones con IDs fijos
    final fijos = {
      'reservas':   ['reserva_demo_001','reserva_demo_002','reserva_demo_003',
                     'reserva_demo_004','reserva_demo_005','reserva_demo_006','reserva_demo_007'],
      'partidos':   ['partido_demo_001','partido_demo_002','partido_demo_003'],
      'flashSlots': ['flash_demo_001','flash_demo_002','flash_demo_003'],
      'resenas':    ['resena_demo_001','resena_demo_002','resena_demo_003',
                     'resena_demo_004','resena_demo_005'],
    };
    for (final entry in fijos.entries) {
      try {
        final b = _db.batch();
        for (final id in entry.value) { b.delete(_db.collection(entry.key).doc(id)); }
        await b.commit();
      } catch (e) {
        sinPermiso.add(entry.key);
        debugPrint('[Seeder] ⚠️ ${entry.key}: $e');
      }
    }

    // prediccionesIA por query
    try {
      final snap = await _db.collection('prediccionesIA').get();
      if (snap.docs.isNotEmpty) {
        final b = _db.batch();
        for (final d in snap.docs) { b.delete(d.reference); }
        await b.commit();
      }
    } catch (e) {
      sinPermiso.add('prediccionesIA');
      debugPrint('[Seeder] ⚠️ prediccionesIA: $e');
    }

    if (sinPermiso.isNotEmpty) {
      throw Exception(
        'Limpieza parcial — sin permisos para: ${sinPermiso.join(', ')}.\n'
        'Actualiza las reglas en la Firebase Console.',
      );
    }
    debugPrint('[Seeder] ✓ Base de datos limpiada');
  }
}
