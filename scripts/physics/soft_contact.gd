class_name SoftContact
extends RefCounted
## Keeps two soft bodies from passing through each other: any two points
## closer than `gap` are pushed apart, the lighter one moving more, so a
## colony shoulders seaweed aside and is slowed a little by it.


## Returns how many point pairs were touching.
static func separate(a: SoftBody, b: SoftBody, gap: float) -> int:
	if a.size() == 0 or b.size() == 0:
		return 0
	var room := a.reach() + b.reach() + gap
	if a.center().distance_squared_to(b.center()) > room * room:
		return 0
	var gap2 := gap * gap
	var hits := 0
	for i in a.size():
		var wa := a.inv_mass[i]
		for j in b.size():
			var d := b.pos[j] - a.pos[i]
			var dist2 := d.length_squared()
			if dist2 >= gap2 or dist2 < 0.000001:
				continue
			var wb := b.inv_mass[j]
			if wa + wb <= 0.0:
				continue
			var dist := sqrt(dist2)
			var fix := d * ((gap - dist) / dist / (wa + wb))
			a.pos[i] -= fix * wa
			b.pos[j] += fix * wb
			hits += 1
	return hits
