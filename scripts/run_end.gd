class_name RunEnd
extends Node
## Ends a subspecies run: works out the gene flow back to the main species
## (GeneBank), shows the RunSummary, and either lets the player keep going
## (after establishing) or ends the run, deleting the run save.

signal keep_playing
signal finished

## Gene points for a thriving run: one per this many progress points.
const PROGRESS_PER_POINT := 20.0
const ESTABLISH_BONUS := 5

var subspecies_name := ""
var throwaway := false
var smoke_test := false
var screen: RunSummary


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


static func points_for(progress: float, established: bool) -> int:
	return floori(progress / PROGRESS_PER_POINT) + (ESTABLISH_BONUS if established else 0)


## Pays out the gene flow and shows the summary. evolved: the subspecies'
## genome at the end, whose organelles join the gene bank.
func conclude(established: bool, generation: int, progress: float, evolved: Genome) -> void:
	var bank := GeneBank.load_bank()
	var earned := 0
	var fresh: Array[String] = []
	if not throwaway:
		earned = points_for(progress, established)
		fresh = bank.receive(earned, evolved)
		bank.save()
	if smoke_test:
		print("smoke: run %s, +%d gene points, %d banked" % [
			"established" if established else "extinct", earned, fresh.size()])
	screen.open(subspecies_name, established, generation, earned, bank, fresh)
	if not screen.keep_playing.is_connected(_on_keep):
		screen.keep_playing.connect(_on_keep)
		screen.end_run.connect(_on_end)
	if smoke_test and established:
		_on_keep.call_deferred()


func _on_keep() -> void:
	screen.visible = false
	keep_playing.emit()


func _on_end() -> void:
	screen.visible = false
	if not throwaway:
		SaveGame.delete()
	finished.emit()
