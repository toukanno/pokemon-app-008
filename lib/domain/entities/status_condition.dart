/// 状態異常
enum StatusCondition { none, poison, paralyze, sleep, burn, freeze }

extension StatusConditionX on StatusCondition {
  String get label {
    switch (this) {
      case StatusCondition.none:
        return '';
      case StatusCondition.poison:
        return 'どく';
      case StatusCondition.paralyze:
        return 'まひ';
      case StatusCondition.sleep:
        return 'ねむり';
      case StatusCondition.burn:
        return 'やけど';
      case StatusCondition.freeze:
        return 'こおり';
    }
  }

  String get shortLabel {
    switch (this) {
      case StatusCondition.none:
        return '';
      case StatusCondition.poison:
        return 'PSN';
      case StatusCondition.paralyze:
        return 'PAR';
      case StatusCondition.sleep:
        return 'SLP';
      case StatusCondition.burn:
        return 'BRN';
      case StatusCondition.freeze:
        return 'FRZ';
    }
  }

  static StatusCondition fromName(String name) {
    switch (name) {
      case 'poison':
        return StatusCondition.poison;
      case 'paralyze':
        return StatusCondition.paralyze;
      case 'sleep':
        return StatusCondition.sleep;
      case 'burn':
        return StatusCondition.burn;
      case 'freeze':
        return StatusCondition.freeze;
      default:
        return StatusCondition.none;
    }
  }

  String get storageName => name;
}
