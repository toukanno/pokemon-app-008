/// アイテムのカテゴリ
enum ItemCategory { ball, heal, statusHeal, revive, other }

/// アイテムの静的定義(オリジナル)。
class ItemDef {
  final String id;
  final String name;
  final ItemCategory category;
  final int price;
  final String description;

  /// 効果量(回復HP・ボール捕獲補正など)
  final double power;

  const ItemDef({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    this.power = 0,
  });
}

/// 所持アイテム(ID と 個数)。
class BagItem {
  final String id;
  int count;
  BagItem({required this.id, required this.count});

  Map<String, dynamic> toJson() => {'id': id, 'count': count};
  factory BagItem.fromJson(Map<String, dynamic> json) =>
      BagItem(id: json['id'] as String, count: json['count'] as int);
}
