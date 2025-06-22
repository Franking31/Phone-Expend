class SpendLine {
  final int? id;
  final String name;
  final String description;
  final double budget;
  final String proof;
  final DateTime date;

  SpendLine({
    this.id,
    required this.name,
    required this.description,
    required this.budget,
    required this.proof,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'budget': budget,
      'proof': proof,
      'date': date.toIso8601String(),
    };
  }

  factory SpendLine.fromMap(Map<String, dynamic> map) {
    return SpendLine(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      budget: map['budget'],
      proof: map['proof'],
      date: DateTime.parse(map['date']),
    );
  }
}
