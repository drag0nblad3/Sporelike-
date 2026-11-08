class_name ColonyChoices
extends Node
## The choices between multicellular generations, while the game is
## paused: a new kind of cell every time (CellPickScreen), the colony's
## FeedingStyle once early on, and its FinalBody once the body is full,
## which ends the stage once the colony is in the shallows. Changes the
## plan it is given. Past FAST_GROWTH_AT cells each pick grows twice.

## The pick is done; the next generation can start.
signal done
## The final body was picked: the stage is complete.
signal stage_finished

## Cells after which every pick grows its cells twice, so the bigger
## body still fills out at a steady pace.
const FAST_GROWTH_AT := 30

var hud: Hud
var rng: RandomNumberGenerator
var smoke_test := false
## Whether the colony ended the generation in the shallows (Shallows.reached).
var at_shore := true

var _plan: BodyPlan
var _stats: GenerationStats
var _cells: CellPickScreen
var _cards: ChoiceScreen


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cells = CellPickScreen.new()
	_cells.chosen.connect(_on_cell_chosen)
	hud.add_child(_cells)
	_cards = ChoiceScreen.new()
	hud.add_child(_cards)


## generations: how many multicellular generations have ended, this one included.
func open(stats: GenerationStats, plan: BodyPlan, generations: int) -> void:
	_plan = plan
	_stats = stats
	if plan.final_body == "" and plan.parts.size() >= BodyPlan.MAX_CELLS:
		if at_shore or smoke_test:
			_offer(FinalBody.ALL, "Your body is fully grown",
				"Choose the body your species takes out of the sea. This completes the stage.",
				_on_final)
		else:
			hud.flash_message("Fully grown! Swim north into the shallows to finish the stage", 5.0)
			done.emit.call_deferred()
	elif plan.style == "" and generations >= FeedingStyle.OFFER_AT:
		_offer(FeedingStyle.ALL, "How does your colony feed?",
			"Your body specializes. This choice is for good.", _on_style)
	else:
		_offer_cells()


func _offer(ids: Array, title: String, subtitle: String, then: Callable) -> void:
	if smoke_test:
		then.call_deferred(str(ids[rng.randi() % ids.size()]))
		return
	var cards: Array = []
	for id in ids:
		if id in FinalBody.ALL:
			cards.append([id, FinalBody.title(id), FinalBody.card_text(id), FinalBody.color(id)])
		else:
			cards.append([id, FeedingStyle.title(id), FeedingStyle.card_text(id), UiTheme.GOLD])
	for connection in _cards.chosen.get_connections():
		_cards.chosen.disconnect(connection["callable"])
	_cards.chosen.connect(then, CONNECT_ONE_SHOT)
	_cards.open(title, subtitle, cards)


func _on_style(id: String) -> void:
	_plan.style = id
	hud.flash_message("Your colony is now a %s" % FeedingStyle.title(id).to_lower(), 3.0)
	_offer_cells()


func _on_final(id: String) -> void:
	_plan.final_body = id
	stage_finished.emit()


func _offer_cells() -> void:
	var roles: Array[String] = []
	for role in LabHud.GROWABLE:
		roles.append(role)
	for i in range(roles.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := roles[i]
		roles[i] = roles[j]
		roles[j] = swap
	roles.resize(3)
	if smoke_test:
		_on_cell_chosen.call_deferred(roles[0])
		return
	_cells.open(_stats, _plan, roles)


func _on_cell_chosen(role: String) -> void:
	_cells.visible = false
	if role != "":
		_plan.grow(role)
		if _plan.parts.size() >= FAST_GROWTH_AT:
			_plan.grow(role)
	done.emit()
