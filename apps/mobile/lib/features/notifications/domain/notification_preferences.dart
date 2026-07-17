class NotificationPreferences {
  const NotificationPreferences({
    this.inAppEnabled = true,
    this.emailEnabled = false,
    this.pushEnabled = false,
    this.smsEnabled = false,
    this.treatmentUpdatesEnabled = true,
    this.marketingEnabled = false,
  });

  final bool inAppEnabled;
  final bool emailEnabled;
  final bool pushEnabled;
  final bool smsEnabled;
  final bool treatmentUpdatesEnabled;
  final bool marketingEnabled;

  NotificationPreferences copyWith({
    bool? inAppEnabled,
    bool? emailEnabled,
    bool? pushEnabled,
    bool? smsEnabled,
    bool? treatmentUpdatesEnabled,
  }) {
    return NotificationPreferences(
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      treatmentUpdatesEnabled:
          treatmentUpdatesEnabled ?? this.treatmentUpdatesEnabled,
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
      'treatment_updates_enabled': treatmentUpdatesEnabled,
      'marketing_enabled': false,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      inAppEnabled: json['in_app_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? false,
      pushEnabled: json['push_enabled'] as bool? ?? false,
      smsEnabled: json['sms_enabled'] as bool? ?? false,
      treatmentUpdatesEnabled:
          json['treatment_updates_enabled'] as bool? ?? true,
      marketingEnabled: false,
    );
  }
}
