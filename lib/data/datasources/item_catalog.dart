import '../../core/constants/game_constants.dart';
import '../../domain/entities/item.dart';

/// アイテムの静的カタログ(オリジナル)。
class ItemCatalog {
  ItemCatalog._();

  static Map<String, ItemDef> build() {
    final defs = <ItemDef>[
      const ItemDef(
        id: ItemIds.monsterBall,
        name: 'エレメンボール',
        category: ItemCategory.ball,
        price: 200,
        power: 1.0,
        description: 'やせいの モンスターを つかまえる ための ボール。',
      ),
      const ItemDef(
        id: ItemIds.superBall,
        name: 'スーパーボール',
        category: ItemCategory.ball,
        price: 600,
        power: 1.5,
        description: 'エレメンボールより つかまえやすい ボール。',
      ),
      const ItemDef(
        id: ItemIds.hyperBall,
        name: 'ハイパーボール',
        category: ItemCategory.ball,
        price: 1200,
        power: 2.0,
        description: 'とても つかまえやすい こうせいのうな ボール。',
      ),
      const ItemDef(
        id: ItemIds.potion,
        name: 'キズぐすり',
        category: ItemCategory.heal,
        price: 300,
        power: 30,
        description: 'モンスターの HPを 30 かいふく する。',
      ),
      const ItemDef(
        id: ItemIds.superPotion,
        name: 'いいキズぐすり',
        category: ItemCategory.heal,
        price: 700,
        power: 60,
        description: 'モンスターの HPを 60 かいふく する。',
      ),
      const ItemDef(
        id: ItemIds.hyperPotion,
        name: 'すごいキズぐすり',
        category: ItemCategory.heal,
        price: 1500,
        power: 120,
        description: 'モンスターの HPを 120 かいふく する。',
      ),
      const ItemDef(
        id: ItemIds.antidote,
        name: 'どくけし',
        category: ItemCategory.statusHeal,
        price: 150,
        description: 'モンスターの「どく」を かいふく する。',
      ),
      const ItemDef(
        id: ItemIds.awakening,
        name: 'めざめスプレー',
        category: ItemCategory.statusHeal,
        price: 250,
        description: 'モンスターの「ねむり」を かいふく する。',
      ),
      const ItemDef(
        id: ItemIds.paralyzeHeal,
        name: 'まひなおし',
        category: ItemCategory.statusHeal,
        price: 250,
        description: 'モンスターの「まひ」を かいふく する。',
      ),
      const ItemDef(
        id: ItemIds.fullHeal,
        name: 'なんでもなおし',
        category: ItemCategory.statusHeal,
        price: 700,
        description: 'モンスターの すべての じょうたいいじょうを かいふく する。',
      ),
      const ItemDef(
        id: ItemIds.revive,
        name: 'げんきのかけら',
        category: ItemCategory.revive,
        price: 2000,
        power: 0.5,
        description: 'ひんしの モンスターを HP はんぶんで ふっかつ させる。',
      ),
    ];
    return {for (final d in defs) d.id: d};
  }

  /// ショップで販売するアイテムID
  static const List<String> shopStock = [
    ItemIds.monsterBall,
    ItemIds.superBall,
    ItemIds.hyperBall,
    ItemIds.potion,
    ItemIds.superPotion,
    ItemIds.hyperPotion,
    ItemIds.antidote,
    ItemIds.paralyzeHeal,
    ItemIds.awakening,
    ItemIds.fullHeal,
    ItemIds.revive,
  ];
}
