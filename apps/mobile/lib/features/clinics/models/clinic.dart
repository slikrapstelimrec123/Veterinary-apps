class Clinic {
  const Clinic({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    this.description,
    this.phone,
    this.email,
    this.website,
    this.coverImageUrl,
    this.status = 'published',
    this.published = true,
    this.canAcceptOnlineBooking = true,
  });

  final String id;
  final String name;
  final String city;
  final String address;
  final String? description;
  final String? phone;
  final String? email;
  final String? website;
  final String? coverImageUrl;
  final String status;
  final bool published;
  final bool canAcceptOnlineBooking;

  String get locationLabel =>
      [city, address].where((value) => value.trim().isNotEmpty).join(', ');
  bool get isPublished => status == 'published' && published;

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      description: json['description'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      status: json['status'] as String? ?? 'draft',
      published: json['published'] as bool? ?? false,
      canAcceptOnlineBooking:
          json['can_accept_online_booking'] as bool? ?? true,
    );
  }
}
