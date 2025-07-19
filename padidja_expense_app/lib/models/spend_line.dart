class SpendLine {
  final int? id;
  final String name;
  final String description;
  final double budget;
  final String proof;
  final String? category;
  final DateTime date;

  SpendLine({
    this.id,
    required this.name,
    required this.description,
    required this.budget,
    required this.proof,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'budget': budget,
      'proof': proof,
      'category': category,
      'date': date.millisecondsSinceEpoch, // Stocker en tant qu'entier (millisecondes)
    };
  }

  factory SpendLine.fromMap(Map<String, dynamic> map) {
    return SpendLine(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      budget: map['budget'] as double,
      proof: map['proof'] as String,
      category: map['category'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int), // Convertir depuis millisecondes
    );
  }
}