class_name HunterSpawner
extends RefCounted
## Puts every kind of hunter (HunterKind) into the sea around the player:
## lone Didinia and Heliozoa, one swarm of dinoflagellates swimming as a
## HunterPack, and a single giant Stentor.


static func spawn_all(eco: Ecosystem) -> void:
	for kind in HunterKind.ids():
		var pack: HunterPack = HunterPack.new() if kind == HunterKind.PACK else null
		var base := eco.focus + Vector2.from_angle(eco.rng.randf() * TAU) \
			* eco.rng.randf_range(25.0, 50.0)
		for _i in HunterKind.count(kind):
			var at := base + Vector2.from_angle(eco.rng.randf() * TAU) * 2.0 if pack \
				else eco.focus + Vector2.from_angle(eco.rng.randf() * TAU) \
				* eco.rng.randf_range(25.0, 50.0)
			spawn(eco, kind, at, pack)


static func spawn(eco: Ecosystem, kind: String, at: Vector2, pack: HunterPack) -> Predator:
	var hunter := _make(kind)
	hunter.setup(HunterKind.genome(kind), 1.0)
	hunter.kind = kind
	hunter.ecosystem = eco
	hunter.lineage = eco.hunters.of(kind)
	hunter.speed_scale = eco.others_pace * hunter.lineage.speed_factor()
	hunter.position = Vector3(at.x, 0.0, at.y)
	if hunter is PackHunter:
		(hunter as PackHunter).pack = pack
		pack.members.append(hunter)
	eco.add_child(hunter)
	eco.predators.append(hunter)
	return hunter


static func _make(kind: String) -> Predator:
	match kind:
		HunterKind.AMBUSHER:
			return AmbushHunter.new()
		HunterKind.PACK:
			return PackHunter.new()
		HunterKind.FILTER:
			return FilterHunter.new()
	return Predator.new()
