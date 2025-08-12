class UserModel {
  final String email;
  final String password;
  final String role; // 'usuario' | 'profesor'
  final Map<String, dynamic> chats;
  final List<String> availableDates; // YYYY-MM-DD

  UserModel({
    required this.email,
    required this.password,
    required this.role,
    Map<String, dynamic>? chats,
    List<String>? availableDates,
  })  : chats = chats ?? {},
        availableDates = availableDates ?? [];

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'role': role,
        'chats': chats,
        'availableDates': availableDates,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        email: json['email'],
        password: json['password'],
        role: json['role'],
        chats: Map<String, dynamic>.from(json['chats'] ?? {}),
        availableDates:
            (json['availableDates'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}
