extends Resource
class_name UnitBaseStats

## The unit's base HP stat.
@export_range(0, 999999) var hp: int

## The amount of mana the unit needs to cast its ability.
@export_range(0, 999) var mana: int

## The unit's attack stat, affects basic attacks and physical abilities.
@export_range(0, 9999) var attack: int

## The unit's magic stat, affects physical abilites a little and magic abilites a lot.
@export_range(0, 9999) var magic: int

## The unit's physical damage reduction.
@export_range(0, 9999) var defense: int

## The unit's magic damage reduction.
@export_range(0, 9999) var magic_defense: int

## The unit's speed, which affects attack speed, projectile speed, movement speed, and cooldown times.
@export_range(0.0, 300.0) var speed: float = 30.0

## The range of the unit's basic attacks.
@export_range(1, 10) var attack_range: int = 1

## The unit's critical hit chance.
@export_range(0.0, 1.0, 0.01) var crit_chance: float = 0.1

## The damage multiplier for critical hits.
@export_range(0.0, 5.0, 0.01) var crit_power: float = 2.0

## The unit's luck stat, which affects various RNG-related mechanics.
@export_range(0.0, 100.0) var luck: float = 0.0
