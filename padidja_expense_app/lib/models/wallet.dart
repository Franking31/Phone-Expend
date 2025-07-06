class Wallet {
  final int? id;
  final String name; // Exemple : Orange Money, MoMo, Carte, Caisse
  final double balance;
  double expenseLimit; // Nouvelle propriété pour la limite de dépense
  final DateTime creationDate;
  DateTime lastUpdated;
  bool isActive;

  Wallet({
    this.id,
    required this.name,
    required this.balance,
    this.expenseLimit = 0.0, // Par défaut à 0 si non spécifié
    DateTime? creationDate,
    DateTime? lastUpdated,
    this.isActive = true, // Par défaut actif
  })  : creationDate = creationDate ?? DateTime.now(), // Défaut : date actuelle
        lastUpdated = lastUpdated ?? DateTime.now(); // Défaut : date actuelle

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'expenseLimit': expenseLimit,
      'creationDate': creationDate.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'isActive': isActive ? 1 : 0, // Stocker comme entier (1 ou 0) pour SQLite
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'],
      name: map['name'],
      balance: map['balance'],
      expenseLimit: map['expenseLimit'] ?? 0.0,
      creationDate: DateTime.parse(map['creationDate']),
      lastUpdated: DateTime.parse(map['lastUpdated']),
      isActive: (map['isActive'] ?? 1) == 1, // Convertir 1/0 en booléen
    );
  }

  Wallet copyWith({
    int? id,
    String? name,
    double? balance,
    double? expenseLimit,
    DateTime? creationDate,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      expenseLimit: expenseLimit ?? this.expenseLimit,
      creationDate: creationDate ?? this.creationDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
    );
  }

  bool validate() {
    if (name.isEmpty) {
      print("⚠️ Le nom du portefeuille ne peut pas être vide");
      return false;
    }
    if (balance < 0) {
      print("⚠️ Le solde ne peut pas être négatif");
      return false;
    }
    if (expenseLimit < 0) {
      print("⚠️ La limite de dépense ne peut pas être négative");
      return false;
    }
    return true;
  }

  void updateLastUpdated() {
    lastUpdated = DateTime.now();
  }
}