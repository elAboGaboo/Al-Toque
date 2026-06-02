// repositories/reservas_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../nucleo/constantes/firestore_rutas.dart';
import '../modelos/reserva_modelo.dart';

class ReservasRepository {
  final _db = FirebaseFirestore.instance;

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
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);

    try {
      // Filtramos por complejoId + canchaId en Firestore para reducir la
      // cantidad de documentos descargados. La fecha se filtra en cliente
      // porque añadir un tercer campo al where requeriría un índice compuesto
      // adicional. Con los índices actuales esto ya es eficiente.
      final snap = await _db
          .collection(FirestorePaths.reservas)
          .where('complejoId', isEqualTo: complejoId)
          .where('canchaId', isEqualTo: canchaId)
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
              !r.fecha.isBefore(inicio) &&
              !r.fecha.isAfter(fin) &&
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
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);

    return _db
        .collection(FirestorePaths.reservas)
        .where('complejoId', isEqualTo: complejoId)
        .snapshots()
        .map((s) => s.docs
            .map(ReservaModel.fromFirestore)
            .where((r) =>
                r.canchaId == canchaId &&
                !r.fecha.isBefore(inicio) &&
                !r.fecha.isAfter(fin) &&
                (r.estaConfirmada || r.estaPendiente))
            .toList());
  }

  /// Stream de reservas de un usuario — ordenadas client-side para evitar
  /// necesidad de índice compuesto (where + orderBy en campos distintos).
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

  /// Stream de reservas de un complejo (admin) — ordenadas client-side.
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
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);

    return _db
        .collection(FirestorePaths.reservas)
        .where('complejoId', isEqualTo: complejoId)
        .snapshots()
        .map((s) => s.docs
            .map(ReservaModel.fromFirestore)
            .where((r) =>
                !r.fecha.isBefore(inicio) && !r.fecha.isAfter(fin))
            .toList());
  }

  /// Crea una reserva nueva. Retorna el ID de la reserva.
  ///
  /// Usa un timeout de 15 s porque la persistencia offline está deshabilitada
  /// (ver main.dart) y sin ella las escrituras esperan confirmación del servidor.
  /// Pasado el límite se lanza Exception para que AsyncValue.guard lo capture.
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

  /// Obtiene una reserva por ID — con timeout de 8 s para evitar spinner eterno.
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

  /// Cancela una reserva (estado → cancelada).
  Future<void> cancelarReserva(String reservaId) async {
    await _db.doc(FirestorePaths.reservaDoc(reservaId)).update({
      'estado': 'cancelada',
    });
  }

  /// Confirma una reserva — usado tanto en modo instantáneo como por el dueño.
  Future<void> confirmarReserva(String reservaId) async {
    await _db.doc(FirestorePaths.reservaDoc(reservaId)).update({
      'estado': 'confirmada',
    });
  }

  /// El dueño rechaza una solicitud de reserva → estado cancelada + pago devuelto.
  Future<void> rechazarReserva(String reservaId) async {
    await _db.doc(FirestorePaths.reservaDoc(reservaId)).update({
      'estado': 'cancelada',
      'estadoPago': 'devuelto',
    });
  }

  /// Libera el pago al dueño tras confirmar que la sesión se realizó.
  Future<void> liberarPago(String reservaId) async {
    await _db.doc(FirestorePaths.reservaDoc(reservaId)).update({
      'estadoPago': 'liberado',
    });
  }

  /// El jugador califica al complejo tras la sesión.
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

  /// El dueño califica al jugador tras la sesión.
  Future<void> calificarJugador({
    required String reservaId,
    required double calificacion,
  }) async {
    await _db.doc(FirestorePaths.reservaDoc(reservaId)).update({
      'calificacionAlJugador': calificacion,
    });
  }
}
