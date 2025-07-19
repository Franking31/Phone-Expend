class Transaction {
  final int? id;
  final String type;
  final String source;
  final double amount;
  final String? description;
  final DateTime date;

  Transaction({
    this.id,
    required this.type,
    required this.source,
    required this.amount,
    this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'source': source,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      type: map['type'] as String,
      source: map['source'] as String,
      amount: map['amount'] as double,
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
    );
  }
}