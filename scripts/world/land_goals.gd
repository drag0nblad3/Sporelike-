class_name LandGoals
extends Node3D
## Stage 3's goals in one place: carry food (LandFood) home to the nest
## (LandNest) to lay eggs, and reach the three landmarks (LandLandmarks)
## to unlock part families (LandUnlocks) for the body customizer. Says
## what happened through notice, and sums it up in status_text.

signal notice(text: String)

var food := LandFood.new()
var nest := LandNest.new()
var landmarks := LandLandmarks.new()
var unlocks := LandUnlocks.new()


func _ready() -> void:
	nest.position = Vector3(5.0, 0.0, 4.0)
	add_child(food)
	add_child(nest)
	add_child(landmarks)
	nest.egg_laid.connect(func(total: int) -> void:
		notice.emit("An egg! %d in the nest" % total))
	landmarks.reached.connect(func(id: String) -> void:
		notice.emit("You reached the %s! %s unlocked in Customize" % [
			LandLandmarks.title(id), LandUnlocks.family(id)]))


func step(animal: Animal, delta: float) -> void:
	var was := food.carried
	food.step(animal, delta)
	if food.carried > was and food.carried == LandFood.CARRY:
		notice.emit("Mouth full. Carry it home to the nest")
	var at := animal.focus()
	if food.carried > 0 and nest.is_near(at):
		nest.deliver(food.drop_all())
	landmarks.check(at, unlocks)


## Moves the nest under the animal, keeping its eggs.
func nest_here(animal: Animal) -> void:
	nest.move_to(animal.focus())
	notice.emit("You made your nest here")


func status_text(at: Vector3) -> String:
	var line := "Carrying %d/%d food  ·  Eggs %d (next in %d)" % [food.carried, LandFood.CARRY,
		nest.eggs, LandNest.FOOD_PER_EGG - nest.food]
	var next := landmarks.nearest_text(at, unlocks)
	if next != "":
		line += "\nNext landmark: " + next
	return line
