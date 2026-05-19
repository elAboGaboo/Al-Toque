import 'package:cloud_firestore/cloud_firestore.dart';

/// Reseña de un jugador sobre un complejo deportivo, vinculada a una reserva.
class ResenaModel {
  final String id;

  /// Complejo calificado
  final String complejoId;

  /// Jugador que escribe la reseña
  final String userId;
  final String userName;
  final String userAvatar;

  /// Reserva que originó esta reseña
  final String reservaId;

  /// Calificación de 1 a 5 estrellas
  final double calificacion;

  /// Comentario del jugador (opcional)
  final String comentario;

  /// Respuesta del dueño del complejo (opcional)
  final String? respuestaDueno;

  final DateTime fecha;
  final DateTime creadoEn;

  const ResenaModel({
    required this.id,
    required this.complejoId,
    required this.userId,
    required this.userName,
    this.userAvatar = '',
    required this.reservaId,
    required this.calificacion,
    this.comentario = '',
    this.respuestaDueno,
    required this.fecha,
    required this.creadoEn,
  });

  factory ResenaModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ResenaModel(
      id: doc.id,
      complejoId: d['complejoId'] as String? ?? '',
      userId: d['userId'] as String? ?? '',
      userName: d['userName'] as String? ?? '',
      userAvatar: d['userAvatar'] as String? ?? '',
      reservaId: d['reservaId'] as String? ?? '',
      calificacion: (d['calificacion'] as num?)?.toDouble() ?? 5,
      comentario: d['comentario'] as String? ?? '',
      respuestaDueno: d['respuestaDueno'] as String?,
      fecha: (d['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory ResenaModel.fromFirestore(DocumentSnapshot doc) =>
      ResenaModel.fromDoc(doc);

  Map<String, dynamic> toMap() => {
        'complejoId': complejoId,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'reservaId': reservaId,
        'calificacion': calificacion,
        'comentario': comentario,
        if (respuestaDueno != null) 'respuestaDueno': respuestaDueno,
        'fecha': Timestamp.fromDate(fecha),
        'creadoEn': Timestamp.fromDate(creadoEn),
      };

  ResenaModel copyWith({String? respuestaDueno}) => ResenaModel(
        id: id,
        complejoId: complejoId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        reservaId: reservaId,
        calificacion: calificacion,
        comentario: comentario,
        respuestaDueno: respuestaDueno ?? this.respuestaDueno,
        fecha: fecha,
        creadoEn: creadoEn,
      );
}
