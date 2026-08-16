import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'domain/repositories/notification_service.dart';
import 'presentation/blocs/calendar/calendar_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_MX');
  configureDependencies();

  final notificationService = getIt<NotificationService>();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Fire-and-forget: evalúa el cierre del ciclo escolar (`SchoolCycleGate`)
  // en cada arranque, no sólo cuando el usuario visita Horario — la guarda
  // de `loadAcademicCalendar` hace que la llamada posterior de la pantalla
  // no repita nada.
  getIt<CalendarCubit>().loadAcademicCalendar();

  runApp(const PoliNexuApp());
}
