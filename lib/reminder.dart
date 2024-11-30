import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ReminderService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final List<Reminder> _reminders = []; // Lista para armazenar lembretes agendados

  /// Inicialização do serviço de notificações
  static Future<void> init() async {
    print("Iniciando o serviço de notificações...");

    const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInitSettings);

    // Inicializar o plugin de notificações
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Lógica ao clicar na notificação
        print("Notificação clicada com ID: ${response.id}");
      },
    );
    print("Serviço de notificações inicializado.");

    // Iniciar o verificador de hora a cada segundo
    _startScheduledTaskChecker();
  }

  /// Verificar os lembretes agendados a cada segundo
  static void _startScheduledTaskChecker() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      final now = DateTime.now();

      // Verificar se algum lembrete corresponde ao horário atual
      for (var reminder in _reminders) {
        if (reminder.scheduledTime.year == now.year &&
            reminder.scheduledTime.month == now.month &&
            reminder.scheduledTime.day == now.day &&
            reminder.scheduledTime.hour == now.hour &&
            reminder.scheduledTime.minute == now.minute) {
          // Enviar a notificação se o horário coincidir
          _sendNotification(reminder);
          _reminders.remove(reminder); // Remover o lembrete após enviar a notificação
        }
      }
    });
  }

  /// Enviar notificação do lembrete
  static Future<void> _sendNotification(Reminder reminder) async {
    print("Enviando notificação para: ${reminder.title}");

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel', // ID do canal
      'Task Reminders',   // Nome do canal
      channelDescription: 'Notificações para lembretes de tarefas.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      reminder.id,
      reminder.title,
      reminder.body,
      notificationDetails,
    );
    print("Notificação enviada para o lembrete: ${reminder.title}");
  }

  /// Agendar lembrete para a tarefa
  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    print("Agendando lembrete: $title");

    final now = DateTime.now();
    // Verificar se o horário do lembrete não passou
    if (scheduledTime.isBefore(now)) {
      print("O horário agendado já passou.");
      return;
    }

    // Armazenar o lembrete na lista
    final reminder = Reminder(id, title, body, scheduledTime);
    _reminders.add(reminder);

    print("Lembrete agendado para: $scheduledTime");
  }

  /// Cancelar um lembrete específico
  static Future<void> cancelReminder(int id) async {
    print("Cancelando o lembrete com ID: $id");
    _reminders.removeWhere((reminder) => reminder.id == id);
    print("Lembrete com ID $id cancelado.");
  }

  /// Cancelar todos os lembretes
  static Future<void> cancelAllReminders() async {
    print("Cancelando todos os lembretes...");
    _reminders.clear();
    print("Todos os lembretes cancelados.");
  }
}

class Reminder {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledTime;

  Reminder(this.id, this.title, this.body, this.scheduledTime);
}
