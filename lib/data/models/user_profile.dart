class UserProfile {
  const UserProfile({
    this.name = '',
    this.age = 0,
    this.sex = '',
    this.bloodGroup = '',
    this.abhaId = '',
    this.abhaAddress = '',
    this.abhaLinked = false,
    this.conditions = const [],
    this.allergies = const [],
    this.medications = const [],
    this.doctorName = '',
    this.doctorPhone = '',
    this.shareWithResponders = false,
  });

  final String name;
  final int age;
  final String sex;
  final String bloodGroup;

  /// 14 digits, no separators. Use Formatters.abhaId to display.
  final String abhaId;
  final String abhaAddress;
  final bool abhaLinked;
  final List<String> conditions;
  final List<String> allergies;
  final List<String> medications;
  final String doctorName;
  final String doctorPhone;
  final bool shareWithResponders;

  bool get isComplete => name.isNotEmpty && age > 0;

  UserProfile copyWith({
    String? name,
    int? age,
    String? sex,
    String? bloodGroup,
    String? abhaId,
    String? abhaAddress,
    bool? abhaLinked,
    List<String>? conditions,
    List<String>? allergies,
    List<String>? medications,
    String? doctorName,
    String? doctorPhone,
    bool? shareWithResponders,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      abhaId: abhaId ?? this.abhaId,
      abhaAddress: abhaAddress ?? this.abhaAddress,
      abhaLinked: abhaLinked ?? this.abhaLinked,
      conditions: conditions ?? this.conditions,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      doctorName: doctorName ?? this.doctorName,
      doctorPhone: doctorPhone ?? this.doctorPhone,
      shareWithResponders: shareWithResponders ?? this.shareWithResponders,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<String> list(String k) =>
        (json[k] as List<dynamic>? ?? const []).map((e) => e.toString()).toList();
    return UserProfile(
      name: json['name'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      sex: json['sex'] as String? ?? '',
      bloodGroup: json['bloodGroup'] as String? ?? '',
      abhaId: json['abhaId'] as String? ?? '',
      abhaAddress: json['abhaAddress'] as String? ?? '',
      abhaLinked: json['abhaLinked'] as bool? ?? false,
      conditions: list('conditions'),
      allergies: list('allergies'),
      medications: list('medications'),
      doctorName: json['doctorName'] as String? ?? '',
      doctorPhone: json['doctorPhone'] as String? ?? '',
      shareWithResponders: json['shareWithResponders'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'sex': sex,
        'bloodGroup': bloodGroup,
        'abhaId': abhaId,
        'abhaAddress': abhaAddress,
        'abhaLinked': abhaLinked,
        'conditions': conditions,
        'allergies': allergies,
        'medications': medications,
        'doctorName': doctorName,
        'doctorPhone': doctorPhone,
        'shareWithResponders': shareWithResponders,
      };
}