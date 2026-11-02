class_name GenerationCycle
extends Node
## Times each generation, collects its GenerationStats, and applies the
## mutation the player picks to every living member of the species.

signal ended(stats: GenerationStats)

## Seconds per generation. CI's smoke test shortens it.
var length := 90.0
var ecosystem: Ecosystem
var number := 0
var time_left := 90.0
var stats: GenerationStats
var running := false

var _births_at_start := 0


func _ready() -> void:
	ecosystem.member_died.connect(_on_member_died)


func _process(delta: float) -> void:
	if not running:
		return
	time_left -= delta
	if time_left <= 0.0:
		finish("time")


func begin() -> void:
	number += 1
	stats = GenerationStats.new()
	stats.number = number
	ecosystem.start_roster()
	stats.start_averages = ecosystem.trait_averages()
	stats.start_population = ecosystem.species.size()
	_births_at_start = ecosystem.births
	time_left = length
	running = true


## Ends the generation early (the player died) or on time.
func finish(reason: String) -> void:
	if not running:
		return
	running = false
	stats.ended_by = reason
	stats.end_averages = ecosystem.trait_averages()
	stats.end_population = ecosystem.species.size()
	stats.births = ecosystem.births - _births_at_start
	ended.emit(stats)


func record_food(energy: float) -> void:
	if running:
		stats.food_eaten += 1
		stats.energy_gained += energy


## Energy made without eating counts toward Fed, but not as a meal.
func record_energy(energy: float) -> void:
	if running:
		stats.energy_gained += energy


func apply(choice: MutationChoice) -> void:
	for member in ecosystem.species:
		choice.apply_to(member.genome, stats.influence())


func _on_member_died(cause: String) -> void:
	if running and stats.deaths.has(cause):
		stats.deaths[cause] += 1
