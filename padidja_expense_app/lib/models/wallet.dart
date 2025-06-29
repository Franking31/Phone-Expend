class Wallet {
  final int? id;
  final String name; // Exemple : Orange Money, MoMo, Carte, Caisse
  final double balance;

  Wallet({
    this.id,
    required this.name,
    required this.balance,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'],
      name: map['name'],
      balance: map['balance'],
    );
  }

  Wallet copyWith({
    int? id,
    String? name,
    double? balance,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
    );
  }
}
