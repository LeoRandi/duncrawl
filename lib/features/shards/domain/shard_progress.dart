enum ColorShard { red, gold, green, blue, lightBlue }

/// Cada fragmento se desbloquea por separado; repetir una recompensa es inocuo.
class ShardProgress {
  final Set<ColorShard> unlocked;

  const ShardProgress._(this.unlocked);

  const ShardProgress.empty() : unlocked = const {};

  bool contains(ColorShard shard) => unlocked.contains(shard);

  ShardProgress unlock(ColorShard shard) => contains(shard)
      ? this
      : ShardProgress._(Set.unmodifiable({...unlocked, shard}));
}
