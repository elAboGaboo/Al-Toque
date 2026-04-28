// tools/seed.dart
//
// Script de seed: crea 3 complejos de Huancayo con sus canchas.
//
// Cómo correrlo:
//   1) Asegúrate de haberte registrado en la app y de que tu usuario tenga rol='admin'
//      (Firebase Console → Firestore → usuarios/{tu-uid} → editar campo "rol" → "admin")
//   2) Edita las constantes ADMIN_EMAIL y ADMIN_PASSWORD abajo
//   3) Ejecuta:    flutter run -t lib/tools/seed.dart
//   4) Pulsa el botón "Sembrar datos" una sola vez
//   5) Verás los logs en consola y un check verde cuando termine
//
// IMPORTANTE: Solo se ejecuta en modo debug. Está pensado para desarrollo.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';

// ⚠️ Edita estas dos constantes antes de correr el seed.
const String ADMIN_EMAIL = 'gabriel@gmail.com';
const String ADMIN_PASSWORD = 'gabriel123';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SeedApp());
}

class SeedApp extends StatelessWidget {
  const SeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CanchApp · Seed',
      debugShowCheckedModeBanner: false,
      home: const SeedScreen(),
    );
  }
}

class SeedScreen extends StatefulWidget {
  const SeedScreen({super.key});

  @override
  State<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<SeedScreen> {
  final List<String> _logs = [];
  bool _running = false;
  bool _done = false;

  void _log(String s) {
    debugPrint(s);
    setState(() => _logs.add(s));
  }

  Future<void> _run() async {
    if (_running) return;
    setState(() {
      _running = true;
      _done = false;
      _logs.clear();
    });

    try {
      _log('▶ Autenticando como $ADMIN_EMAIL ...');
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: ADMIN_EMAIL,
        password: ADMIN_PASSWORD,
      );
      final uid = FirebaseAuth.instance.currentUser!.uid;
      _log('✓ Autenticado uid=$uid');

      // Verifica que el usuario sea admin
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();
      final rol = userDoc.data()?['rol'] as String?;
      if (rol != 'admin') {
        _log('✗ El usuario tiene rol="$rol", se necesita "admin".');
        _log(
            '  Ve a Firebase Console → Firestore → usuarios/$uid → cambia "rol" a "admin"');
        setState(() => _running = false);
        return;
      }
      _log('✓ rol=admin confirmado');

      final db = FirebaseFirestore.instance;
      final ahora = Timestamp.now();

      // ── Complejo 1: Cancha El Tambo ────────────────────────
      _log('▶ Creando complejo 1: El Tambo Sport Center');
      const c1Id = 'complejo-tambo';
      await db.collection('complejos').doc(c1Id).set({
        'nombre': 'El Tambo Sport Center',
        'direccion': 'Av. Mariscal Castilla 3909, El Tambo',
        'ciudad': 'Huancayo',
        'lat': -12.0432,
        'lng': -75.2089,
        'rating': 4.8,
        'totalReseñas': 124,
        'horarioApertura': '07:00',
        'horarioCierre': '23:00',
        'imagenes': [
          'https://images.unsplash.com/photo-1551958219-acbc608c6377?w=800',
          'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
        ],
        'adminUid': uid,
        'activo': true,
        'configIA': {
          'preciosDinamicosActivo': true,
          'flashAutomaticoActivo': true,
          'precioTechoMax': 200.0,
          'notificarJugadores': true,
        },
      });
      await db.collection('complejos/$c1Id/canchas').doc('cancha-1').set({
        'nombre': 'Cancha 1 - Sintética',
        'deporte': 'futbol5',
        'superficie': 'sintetico',
        'capacidad': 10,
        'precioBase': 80.0,
        'activa': true,
      });
      await db.collection('complejos/$c1Id/canchas').doc('cancha-2').set({
        'nombre': 'Cancha 2 - Grass',
        'deporte': 'futbol7',
        'superficie': 'grass',
        'capacidad': 14,
        'precioBase': 120.0,
        'activa': true,
      });
      _log('✓ El Tambo Sport Center + 2 canchas');

      // ── Complejo 2: Cancha Chilca ──────────────────────────
      _log('▶ Creando complejo 2: Chilca FC');
      const c2Id = 'complejo-chilca';
      await db.collection('complejos').doc(c2Id).set({
        'nombre': 'Chilca FC',
        'direccion': 'Jr. Túpac Amaru 567, Chilca',
        'ciudad': 'Huancayo',
        'lat': -12.0789,
        'lng': -75.2078,
        'rating': 4.5,
        'totalReseñas': 87,
        'horarioApertura': '08:00',
        'horarioCierre': '22:00',
        'imagenes': [
          'https://images.unsplash.com/photo-1556056504-5c7696c4c28d?w=800',
        ],
        'adminUid': uid,
        'activo': true,
        'configIA': {
          'preciosDinamicosActivo': false,
          'flashAutomaticoActivo': false,
          'precioTechoMax': 150.0,
          'notificarJugadores': true,
        },
      });
      await db.collection('complejos/$c2Id/canchas').doc('cancha-1').set({
        'nombre': 'Cancha Principal',
        'deporte': 'futbol5',
        'superficie': 'sintetico',
        'capacidad': 10,
        'precioBase': 70.0,
        'activa': true,
      });
      _log('✓ Chilca FC + 1 cancha');

      // ── Complejo 3: Cancha Centro ──────────────────────────
      _log('▶ Creando complejo 3: Centro Deportivo Huancayo');
      const c3Id = 'complejo-centro';
      await db.collection('complejos').doc(c3Id).set({
        'nombre': 'Centro Deportivo Huancayo',
        'direccion': 'Av. Giráldez 245, Huancayo',
        'ciudad': 'Huancayo',
        'lat': -12.0651,
        'lng': -75.2049,
        'rating': 4.2,
        'totalReseñas': 45,
        'horarioApertura': '06:00',
        'horarioCierre': '23:30',
        'imagenes': [
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
        ],
        'adminUid': uid,
        'activo': true,
        'configIA': {
          'preciosDinamicosActivo': false,
          'flashAutomaticoActivo': false,
          'precioTechoMax': 180.0,
          'notificarJugadores': true,
        },
      });
      await db
          .collection('complejos/$c3Id/canchas')
          .doc('cancha-basquet')
          .set({
        'nombre': 'Cancha Multiuso',
        'deporte': 'basquet',
        'superficie': 'cemento',
        'capacidad': 10,
        'precioBase': 50.0,
        'activa': true,
      });
      await db.collection('complejos/$c3Id/canchas').doc('cancha-voley').set({
        'nombre': 'Cancha de Voley',
        'deporte': 'voley',
        'superficie': 'cemento',
        'capacidad': 12,
        'precioBase': 45.0,
        'activa': true,
      });
      _log('✓ Centro Deportivo Huancayo + 2 canchas');

      // Marca timestamp de seed (opcional)
      await db.collection('_meta').doc('seed').set({
        'ejecutadoEn': ahora,
        'porUid': uid,
        'totalComplejos': 3,
      });

      _log('');
      _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _log('✓ SEED COMPLETADO');
      _log('  3 complejos · 5 canchas');
      _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      setState(() => _done = true);
    } catch (e, st) {
      _log('✗ ERROR: $e');
      debugPrint('$st');
    } finally {
      setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1320),
      appBar: AppBar(
        title: const Text('CanchApp · Seed'),
        backgroundColor: const Color(0xFF080C12),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _running ? null : _run,
              icon: _running
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(_done ? Icons.check_circle : Icons.local_florist),
              label: Text(_running
                  ? 'Sembrando...'
                  : _done
                      ? 'Sembrado completo'
                      : 'Sembrar datos'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _done ? Colors.green : const Color(0xFF64D28C),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF080C12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _logs[i],
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: _logs[i].startsWith('✗')
                            ? Colors.red
                            : _logs[i].startsWith('✓')
                                ? Colors.greenAccent
                                : Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
