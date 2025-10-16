// models/expense.dart

class Expense {
  final String name;
  final String category;
  final double amount;
  final DateTime date;

  Expense({
    required this.name,
    required this.category,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      name: map['name'],
      category: map['category'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
    );
  }

  @override
  String toString() {
    return 'Expense(name: $name, category: $category, amount: $amount, date: $date)';
  }
}
