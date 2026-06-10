// repositories/reservas_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../nucleo/constantes/firestore_rutas.dart';
import '../modelos/reserva_modelo.dart';

class ReservasRepository {
  final _db = FirebaseFirestore.instance;

  static bool _mismaFecha(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// One-shot: reservas del día para una cancha — con timeout de 8 s.
  ///
  /// Reemplaza al StreamProvider en ReservarScreen porque con
  /// persistenceEnabled=false el stream puede no emitir nunca si Firestore
  /// tarda, dejando los slots en spinner eterno.
  Future<List<ReservaModel>> getReservasDelDia({
    required String complejoId,
    required String canchaId,
    required DateTime fecha,
  }) async {
    try {
      // Solo filtramos por complejoId en Firestore (campo único = sin índice).
      // canchaId y fecha se filtran en cliente — evita requerir índices
      // compuestos que necesitan permisos de despliegue en Firebase Console.
      final snap = await _db
          .collection(FirestorePaths.reservas)
          .where('complejoId', isEqualTo: complejoId)
          .get()
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception(
              'Sin respuesta del servidor (8 s). Verifica tu conexión.',
            ),
          );

      return snap.docs
          .map(ReservaModel.fromFirestore)
          .where((r) =>
              r.canchaId == canchaId &&
              _mismaFecha(r.fecha, fecha) &&
              (r.estaConfirmada || r.estaPendiente))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('[${e.code}] ${e.message ?? "Error de Firestore"}');
    } catch (e) {
      throw Exception('Error cargando disponibilidad: $e');
    }
  }

  /// Stream de reservas del día seleccionado para una cancha (tiempo real).
  /// Filtra por complejoId en Firestore, resto en cliente.
  Stream<List<ReservaModel>> streamReservasDelDia({
    required String complejoId,
    required String canchaId,
    required DateTime fecha,
  }) {
    return _db
        .collection(FirestorePaths.reservas)
        .where('complejoId', isEqualTo: complejoId)
        .snapshots()
        .map((s) => s.docs
            .map(ReservaModel.fromFirestore)
            .where((r) =>
                r.canchaId == canchaId &&
                _mismaFecha(r.fecha, fecha) &&
                (r.estaConfirmada || r.estaPendiente))
            .toList());
  }

  /// Stream de reservas de un usuario â€” ordenadas client-side para evitar
  /// necesidad de Ã­ndice compuesto (where + orderBy en campos distintos).
  Stream<List<ReservaModel>> streamMisReservas(String userId) {
    return _db
        .collection(FirestorePaths.reservas)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
      final lista = s.docs.map(ReservaModel.fromFirestore).toList();
      lista.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
      return lista;
    });
  }

  /// Stream de reservas de un complejo (admin) â€” ordenadas client-side.
  Stream<List<ReservaModel>> streamReservasComplejo(String complejoId) {
    return _db
        .collection(FirestorePaths.reservas)
        .where('complejoId', isEqualTo: complejoId)
        .snapshots()
        .map((s) {
      final lista = s.docs.map(ReservaModel.fromFirestore).toList();
      lista.sort((a, b) => b.fecha.compareTo(a.fecha));
      return lista;
    });
  }

  /// Reservas del complejo para una fecha específica (admin).
  /// Filtra por complejoId en Firestore y por fecha en cliente
  /// para evitar requerir índices compuestos.
  Stream<List<ReservaModel>> streamReservasComplejoFecha({
    required String complejoId,
    required DateTime fecha,
  }) {
    return _db
        .collection(FirestorePaths.reservas)
        .where('complejoId', isEqualTo: complejoId)
        .snapshots()
        .map((s) => s.docs
            .map(ReservaModel.fromFirestore)
            .where((r) => _mismaFecha(r.fecha, fecha))
            .toList());
  }

  /// Crea una reserva nueva. Retorna el ID de la reserva.
  ///
  /// Usa un timeout de 15 s porque la persistencia offline estÃ¡ deshabilitada
  /// (ver main.dart) y sin ella las escrituras esperan confirmaciÃ³n del servidor.
  /// Pasado el lÃ­mite se lanza Exception para que AsyncValue.guard lo capture.
  Future<String> crearReserva(ReservaModel reserva) async {
    // doc() sin argumento genera ID auto en el cliente.
    final docRef = reserva.id.isEmpty
        ? _db.collection(FirestorePaths.reservas).doc()
        : _db.collection(FirestorePaths.reservas).doc(reserva.id);

    try {
      await docRef
          .set({
            ...reserva.toMap(),
            'creadoEn': FieldValue.serverTimestamp(),
          })
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception(
              'Tiempo de espera agotado. Verifica tu conexión e inténtalo de nuevo.',
            ),
          );
    } on FirebaseException catch (e) {
      throw Exception('[${e.code}] ${e.message ?? "Error de Firestore"}');
    }
    return docRef.id;
  }

  /// Obtiene una reserva por ID â€” con timeout de 8 s para evitar spinner eterno.
  Future<ReservaModel?> getReserva(String reservaId) async {
    try {
      final doc = await _db
          .doc(FirestorePaths.reservaDoc(reservaId))
          .get()
          .timeout(const Duration(seconds: 8));
      if (!doc.exists) return null;
      return ReservaModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw Exception('[${e.code}] ${e.message ?? "Error de Firestore"}');
    } catch (e) {
      throw Exception('Error cargando reserva: $e');
    }
  }

  /// Stream de una reserva en tiempo real.
  Stream<ReservaModel?> streamReserva(String reservaId) {
    return _db
        .doc(FirestorePaths.reservaDoc(reservaId))
        .snapshots()
        .map((s) => s.exists ? ReservaModel.fromFirestore(s) : null);
  }

  /// Cancela una reserva (estado â†’ cancelada).
  Future<void> cancelarReserva(String reservaId) async {
    await _db.doc(FirestorePaths.reservaDoc(reservaId)).update({
      'estado': 'cancelada',
    });
  }

  /// Confirma una reserva â€” usado tanto en modo instantÃ¡neo como por el dueÃ±o.
  Future<void> confirmarReserva(String reservaId) async {
    await _db.doc(FirestorePaths.reservaDoc(reservaId)).update({
      'estado': 'confirmada',
    });
  }

  /// El dueÃ±o rechaza una solicitud de reserva â†’ estado cancelada + pago devuelto.
  Future<void> rechazarReserva(String reservaId) async {
    await _db.doc(FirestorePaths.reservaDoc(reservaId)).update({
      'estado': 'cancelada',
      'estadoPago': 'devuelto',
    });
  }

  /// Libera el pago al dueÃ±o tras confirmar que la sesiÃ³n se realizÃ³.
  Future<void> liberarPago(String reservaId) async {
    await _db.doc(FirestorePaths.reservaDoc(reservaId)).update({
      'estadoPago': 'liberado',
    });
  }

  /// El jugador califica al complejo tras la sesiÃ³n.
  Future<void> calificarComplejo({
    required String reservaId,
    required double calificacion,
    String comentario = '',
  }) async {
    await _db.doc(FirestorePaths.reservaDoc(reservaId)).update({
      'calificacionAlComplejo': calificacion,
      'comentarioUsuario': comentario,
    });
  }

  /// El dueÃ±o califica al jugador tras la sesiÃ³n.
  Future<void> calificarJugador({
    required String reservaId,
    required double calificacion,
  }) async {
    await _db.doc(FirestorePaths.reservaDoc(reservaId)).update({
      'calificacionAlJugador': calificacion,
    });
  }
}
