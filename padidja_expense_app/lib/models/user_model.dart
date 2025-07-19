// lib/models/user_model.dart
class Utilisateur {
  final String id; // ID Supabase (UUID)
  final String nom;
  final String email;
  final String motDePasse;
  final String role;
  final String? imagePath;

  Utilisateur({
    required this.id,
    required this.nom,
    required this.email,
    required this.motDePasse,
    required this.role,
    this.imagePath,
  });

  // Convertir vers Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'user_id': id, // Utiliser 'id' au lieu de 'user_id'
      'nom': nom,
      'email': email,
      'mot_de_passe': motDePasse,
      'role': role,
      'image_path': imagePath,
    };
  }

  // Créer depuis Map SQLite
  factory Utilisateur.fromMap(Map<String, dynamic> map) {
    return Utilisateur(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      email: map['email'] ?? '',
      motDePasse: map['mot_de_passe'] ?? '',
      role: map['role'] ?? 'user',
      imagePath: map['image_path'],
    );
  }

  // Créer depuis JSON Supabase
  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      email: json['email'] ?? '',
      motDePasse: '', // Ne pas stocker le mot de passe en local
      role: json['role'] ?? 'user',
      imagePath: json['image_path'],
    );
  }

  // Convertir vers JSON pour Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'role': role,
      'image_path': imagePath,
    };
  }

  // Créer une copie avec modifications
  Utilisateur copyWith({
    String? id,
    String? nom,
    String? email,
    String? motDePasse,
    String? role,
    String? imagePath,
  }) {
    return Utilisateur(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      motDePasse: motDePasse ?? this.motDePasse,
      role: role ?? this.role,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}