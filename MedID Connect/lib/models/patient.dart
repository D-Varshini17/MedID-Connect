class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.birthDate,
    required this.bloodGroup,
    required this.phone,
    required this.email,
    required this.address,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.healthScore,
  });

  final String id;
  final String name;
  final int age;
  final String gender;
  final DateTime birthDate;
  final String bloodGroup;
  final String phone;
  final String email;
  final String address;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final int healthScore;

  String get initials {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return "${parts.first[0]}${parts.last[0]}".toUpperCase();
  }
}
