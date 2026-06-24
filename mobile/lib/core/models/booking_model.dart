class BookingModel {
  final int id;
  final int workoutSession;
  final String sessionName;
  final String coachName;
  final String date;
  final String time;
  final String status;
  final String confirmedAt;

  const BookingModel({
    required this.id,
    required this.workoutSession,
    required this.sessionName,
    required this.coachName,
    required this.date,
    required this.time,
    required this.status,
    required this.confirmedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: json['id'] as int,
        workoutSession: json['workout_session'] as int,
        sessionName: json['session_name'] as String? ?? '',
        coachName: json['coach_name'] as String? ?? '',
        date: json['date'] as String? ?? '',
        time: json['time'] as String? ?? '',
        status: json['status'] as String? ?? '',
        confirmedAt: json['confirmed_at'] as String? ?? '',
      );
}
