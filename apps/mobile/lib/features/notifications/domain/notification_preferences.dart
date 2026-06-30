class NotificationPreferences {
  const NotificationPreferences({
    this.inAppEnabled = true,
    this.emailEnabled = false,
    this.pushEnabled = false,
    this.smsEnabled = false,
    this.appointmentRemindersEnabled = true,
    this.treatmentUpdatesEnabled = true,
    this.reviewRequestsEnabled = true,
    this.marketingEnabled = false,
  });

  final bool inAppEnabled;
  final bool emailEnabled;
  final bool pushEnabled;
  final bool smsEnabled;
  final bool appointmentRemindersEnabled;
  final bool treatmentUpdatesEnabled;
  final bool reviewRequestsEnabled;
  final bool marketingEnabled;

  NotificationPreferences copyWith({
    bool? inAppEnabled,
    bool? emailEnabled,
    bool? pushEnabled,
    bool? smsEnabled,
    bool? appointmentRemindersEnabled,
    bool? treatmentUpdatesEnabled,
    bool? reviewRequestsEnabled,
  }) {
    return NotificationPreferences(
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      appointmentRemindersEnabled: appointmentRemindersEnabled ?? this.appointmentRemindersEnabled,
      treatmentUpdatesEnabled: treatmentUpdatesEnabled ?? this.treatmentUpdatesEnabled,
      reviewRequestsEnabled: reviewRequestsEnabled ?? this.reviewRequestsEnabled,
      marketingEnabled: false,
    );
  }

  Map<String, dynamic> toJson(String userId) {
    return {
      'user_id': userId,
      'in_app_enabled': inAppEnabled,
      'email_enabled': emailEnabled,
      'push_enabled': pushEnabled,
      'sms_enabled': smsEnabled,
      'appointment_reminders_enabled': appointmentRemindersEnabled,
      'treatment_updates_enabled': treatmentUpdatesEnabled,
      'review_requests_enabled': reviewRequestsEnabled,
      'marketing_enabled': false,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      inAppEnabled: json['in_app_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? false,
      pushEnabled: json['push_enabled'] as bool? ?? false,
      smsEnabled: json['sms_enabled'] as bool? ?? false,
      appointmentRemindersEnabled: json['appointment_reminders_enabled'] as bool? ?? true,
      treatmentUpdatesEnabled: json['treatment_updates_enabled'] as bool? ?? true,
      reviewRequestsEnabled: json['review_requests_enabled'] as bool? ?? true,
      marketingEnabled: false,
    );
  }
}
