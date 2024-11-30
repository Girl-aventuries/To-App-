import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  /// Inicialização do serviço de notificações
  static Future<void> init() async {
    print("Iniciando o serviço de notificações...");

    const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInitSettings);

    // Inicializar o plugin de notificações
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Opcional: Lógica ao clicar na notificação
        print("Notificação clicada com ID: ${response.id}");
      },
    );
    print("Serviço de notificações inicializado.");

    // Criar o canal de notificações para Android 8.0 ou superior
    const androidChannel = AndroidNotificationChannel(
      'reminder_channel', // ID do canal
      'Task Reminders',   // Nome do canal
      description: 'Notificações para lembretes de tarefas.',
      importance: Importance.high,
      playSound: true, // Tocar som para notificações
      showBadge: true,
    );

    // Criar o canal, se necessário
    await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
    print("Canal de notificações criado.");

    // Inicializar timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo')); // Ajuste conforme necessário
    print("Timezone configurado para 'America/Sao_Paulo'.");
  }

  /// Enviar a notificação imediatamente (apenas para testes)
  static Future<void> sendImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    print("Enviando notificação imediata...");

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel', // ID do canal
      'Task Reminders',   // Nome do canal
      channelDescription: 'Notificações para lembretes de tarefas.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
    );
    print("Notificação imediata enviada.");
  }

  /// Agendar lembrete para a tarefa
  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    print("Agendando lembrete: $title");

    // Converter DateTime para TZDateTime
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    print("Data e hora do lembrete: $tzTime");

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel', // ID do canal
      'Task Reminders',   // Nome do canal
      channelDescription: 'Notificações para lembretes de tarefas.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    // Agendar a notificação
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      notificationDetails,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Substituto para androidAllowWhileIdle
      matchDateTimeComponents: DateTimeComponents.time, // Opcional: para notificações diárias no mesmo horário
    );

    print("Lembrete agendado para: $tzTime");
  }


  /// Cancelar um lembrete específico
  static Future<void> cancelReminder(int id) async {
    print("Cancelando o lembrete com ID: $id");
    await _notifications.cancel(id);
    print("Lembrete com ID $id cancelado.");
  }

  /// Cancelar todos os lembretes
  static Future<void> cancelAllReminders() async {
    print("Cancelando todos os lembretes...");
    await _notifications.cancelAll();
    print("Todos os lembretes cancelados.");
  }
}
