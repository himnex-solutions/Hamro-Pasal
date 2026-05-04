class Expense {
  final String? id;
  final String userId;
  final String title;
  final String category;
  final double amount;
  final String adDate;
  final String? bsDate;
  final String? note;
  final DateTime? createdAt;

  const Expense({
    this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.amount,
    required this.adDate,
    this.bsDate,
    this.note,
    this.createdAt,
  });

  static const List<String> categories = [
    'Rent',
    'Electricity',
    'Salary',
    'Transport',
    'Maintenance',
    'Marketing',
    'Other',
  ];

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String?,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        adDate: json['ad_date'] as String,
        bsDate: json['bs_date'] as String?,
        note: json['note'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'title': title,
        'category': category,
        'amount': amount,
        'ad_date': adDate,
        'bs_date': bsDate,
        'note': note,
      };
}
