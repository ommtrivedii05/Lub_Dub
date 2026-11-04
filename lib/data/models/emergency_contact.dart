class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    this.priority = 1,
    this.notifyOnWarning = false,
    this.notifyOnEmergency = true,
  });

  final String id;
  final String name;
  final String relationship;
  final String phone;

  /// 1 is called/notified first.
  final int priority;
  final bool notifyOnWarning;
  final bool notifyOnEmergency;

  EmergencyContact copyWith({
    String? name,
    String? relationship,
    String? phone,
    int? priority,
    bool? notifyOnWarning,
    bool? notifyOnEmergency,
  }) {
    return EmergencyContact(
      id: id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      priority: priority ?? this.priority,
      notifyOnWarning: notifyOnWarning ?? this.notifyOnWarning,
      notifyOnEmergency: notifyOnEmergency ?? this.notifyOnEmergency,
    );
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      name: json['name'] as String,
      relationship: json['relationship'] as String? ?? '',
      phone: json['phone'] as String,
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      notifyOnWarning: json['notifyOnWarning'] as bool? ?? false,
      notifyOnEmergency: json['notifyOnEmergency'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relationship': relationship,
        'phone': phone,
        'priority': priority,
        'notifyOnWarning': notifyOnWarning,
        'notifyOnEmergency': notifyOnEmergency,
      };
}