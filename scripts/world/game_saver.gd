class_name GameSaver
extends Node
## Turns the running game into a save Dictionary and back. Saves on its own
## when the app is sent to the background or closed, since Android may kill
## a backgrounded app without warning.

var ecosystem: Ecosystem
var director: PlayerDirector
var cycle: GenerationCycle
var progress: EvolutionProgress
var world_seed := 0


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST,
			NOTIFICATION_WM_GO_BACK_REQUEST, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		save_now()


## Saves the generation in progress. Between generations (population screen
## open) the save from the start of the generation is kept instead.
func save_now() -> void:
	if not cycle.running:
		return
	var members: Array = []
	for cell in ecosystem.species:
		if cell.alive:
			members.append(_organism_entry(cell))
	var you := {"genome": director.genome.to_dict(), "x": 0.0, "y": 0.0, "energy": 8.0}
	if director.is_alive():
		you = _organism_entry(director.player)
	SaveGame.write({
		"generation": cycle.number,
		"time_left": cycle.time_left,
		"births": ecosystem.births,
		"progress": progress.points,
		"world_seed": world_seed,
		"player": you,
		"species": members,
		"rivals": ecosystem.rivals.to_save(),
		"hunters": ecosystem.hunters.levels,
	})


static func _organism_entry(org: Organism) -> Dictionary:
	var at := org.flat_pos()
	return {"genome": org.genome.to_dict(), "x": at.x, "y": at.y, "energy": org.energy}


## Saved species members as spawn entries: [Genome, Vector2, energy].
static func members_from(data: Dictionary) -> Array:
	var out: Array = []
	var list: Array = data.get("species", [])
	for item in list:
		var entry: Dictionary = item
		out.append(_spawn_entry(entry))
	return out


## The saved player as a spawn entry: [Genome, Vector2, energy].
static func player_from(data: Dictionary) -> Array:
	var entry: Dictionary = data.get("player", {})
	return _spawn_entry(entry)


static func _spawn_entry(entry: Dictionary) -> Array:
	var genome_data: Dictionary = entry.get("genome", {})
	var at := Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
	return [Genome.from_dict(genome_data), at, float(entry.get("energy", 6.0))]
