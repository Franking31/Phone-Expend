class Transaction {
  final int? id;
  final String type; // income / outcome
  final String source; // OM, MoMo, Carte, etc.
  final double amount;
  final String description;
  final DateTime date;

  Transaction({
    this.id,
    required this.type,
    required this.source,
    required this.amount,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'source': source,
      'amount': amount,
      'description': description,
      'date': date.millisecondsSinceEpoch, // Stocker comme timestamp
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      type: map['type'],
      source: map['source'],
      amount: map['amount'],
      description: map['description'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']), // Convertir depuis timestamp
    );
  }
}