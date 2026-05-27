# Al Toque

Aplicación móvil para la reserva de canchas deportivas en Huancayo, Perú.

---

## ¿Qué es Al Toque?

Al Toque conecta jugadores con complejos deportivos de Huancayo. Los usuarios pueden ver canchas disponibles, reservar su horario y recibir un ticket con código QR. Los dueños de complejos administran sus canchas, horarios y finanzas desde un panel dedicado.

---

## Funcionalidades

### Para jugadores
- Explorar complejos deportivos cercanos con precios reales
- Ver disponibilidad de canchas por fecha y hora
- Reservar una cancha (fútbol 5, fútbol 7, básquet, vóley)
- Elegir método de pago (Yape, Plin, tarjeta, efectivo)
- Recibir ticket de confirmación con código QR
- Ver complejos en el mapa con ubicación GPS
- Crear y unirse a partidos abiertos con otros jugadores
- Editar perfil (nombre, teléfono, DNI)

### Para administradores (dueños de complejos)
- Dashboard con estadísticas en tiempo real: reservas, ingresos, ocupación y cancelaciones
- Gestión de canchas: crear, editar, activar/desactivar
- Control de horarios por cancha y fecha
- Flash Slots: descuentos automáticos en horarios de baja demanda
- Historial de reservas y partidos
- Predicción de demanda semanal

---

## Tecnologías

| Capa | Tecnología |
|------|-----------|
| Framework | Flutter 3 |
| Backend | Firebase (Firestore, Auth, Messaging) |
| Estado | Riverpod 3 |
| Navegación | GoRouter |
| Mapas | flutter_map + Geolocator |
| UI | Google Fonts, fl_chart |
| Notificaciones | Firebase Messaging + flutter_local_notifications |

---

## Estructura del proyecto

```
lib/
├── core/
│   ├── constants/      # Constantes de app y rutas Firestore
│   ├── router/         # Configuración de rutas (GoRouter)
│   ├── services/       # Notificaciones, ubicación, deep links
│   ├── theme/          # Colores y tema de la app
│   └── utils/          # Fechas, geo, mapas
├── models/             # Modelos de datos (Complejo, Cancha, Reserva, Partido...)
├── providers/          # Providers Riverpod
├── repositories/       # Acceso a Firestore
└── screens/
    ├── admin/          # Panel del dueño
    ├── auth/           # Login y registro
    ├── mapa/           # Vista de mapa
    └── usuario/        # Flujo del jugador
```

---

## Configuración

1. Clonar el repositorio
2. Copiar `lib/core/constants/app_constants.dart.example` → `app_constants.dart` y completar las keys
3. Agregar `lib/firebase_options.dart` y `android/app/google-services.json` con las credenciales de tu proyecto Firebase
4. Ejecutar `flutter pub get`
5. Ejecutar `flutter run`

> Los archivos con credenciales están en `.gitignore` y no se incluyen en el repositorio.

---

## Roles de usuario

| Rol | Acceso |
|-----|--------|
| `jugador` | Explorar complejos, reservar canchas, crear/unirse a partidos |
| `dueno` | Panel de administración del complejo |

El registro de dueños requiere un código especial provisto por el equipo de Al Toque.
