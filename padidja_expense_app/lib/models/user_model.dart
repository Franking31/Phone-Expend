class Utilisateur {
  final int id;
  final String nom;
  final String email;
  final String motDePasse;
  final String role;
  final String? imagePath; // Added imagePath field

  Utilisateur({
    required this.id,
    required this.nom,
    required this.email,
    required this.motDePasse,
    required this.role,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'mot_de_passe': motDePasse,
      'role': role,
      'image_path': imagePath, // Include imagePath in map
    };
  }

  static Utilisateur fromMap(Map<String, dynamic> map) {
    return Utilisateur(
      id: map['id'] ?? 0,
      nom: map['nom'] ?? '',
      email: map['email'] ?? '',
      motDePasse: map['mot_de_passe'] ?? '',
      role: map['role'] ?? 'user',
      imagePath: map['image_path'], // Retrieve imagePath from map
    );
  }
}