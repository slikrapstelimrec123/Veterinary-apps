class PetTransfer {
  const PetTransfer({
    required this.id,
    required this.petId,
    required this.fromUserId,
    required this.toEmail,
    required this.status,
    required this.createdAt,
    this.petName,
    this.petSpecies,
    this.fromUserName,
    this.toUserId,
  });

  final String id;
  final String petId;
  final String fromUserId;
  final String toEmail;
  final String? toUserId;
  final String status;
  final DateTime createdAt;
  final String? petName;
  final String? petSpecies;
  final String? fromUserName;

  bool get isPending => status == 'pending';

  String get statusLabel => switch (status) {
        'pending' =>
          '\u041e\u0447\u0456\u043a\u0443\u0454 \u043f\u0456\u0434\u0442\u0432\u0435\u0440\u0434\u0436\u0435\u043d\u043d\u044f',
        'accepted' => '\u041f\u0440\u0438\u0439\u043d\u044f\u0442\u043e',
        'declined' => '\u0412\u0456\u0434\u0445\u0438\u043b\u0435\u043d\u043e',
        'cancelled' => '\u0421\u043a\u0430\u0441\u043e\u0432\u0430\u043d\u043e',
        _ => status,
      };

  factory PetTransfer.fromJson(Map<String, dynamic> json) {
    return PetTransfer(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      fromUserId: json['from_user_id'] as String,
      toEmail: json['to_email'] as String,
      toUserId: json['to_user_id'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      petName: json['pet_name'] as String?,
      petSpecies: json['pet_species'] as String?,
      fromUserName: json['from_user_name'] as String?,
    );
  }
}
