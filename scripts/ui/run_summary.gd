class_name RunSummary
extends MenuPanel
## The end of a subspecies run, or the moment it establishes itself: how it
## went, the gene flow back to the main species, and what to do next.

signal keep_playing
signal end_run


## established: the subspecies reached the stage goal (it may play on into
## the multicellular stage); otherwise it died out.
func open(subspecies_name: String, sea_title: String, established: bool, generation: int,
		earned: int, bank: GeneBank, fresh: Array[String]) -> void:
	clear()
	visible = true
	if established:
		label("%s is established!" % subspecies_name, 36, UiTheme.ACCENT)
		label("Your subspecies holds the %s after %d generations." % [sea_title, generation], 26)
	else:
		label("%s died out" % subspecies_name, 36, UiTheme.LOSS)
		label("The last of your subspecies was lost in the %s in generation %d." % [
			sea_title, generation], 26)
	label("Gene flow: +%d gene points back to the main species (%d to spend)." % [
		earned, bank.points], 24, UiTheme.GOLD)
	if not fresh.is_empty():
		var names := PackedStringArray()
		for id in fresh:
			names.append(GeneText.label(id))
		label("Newly banked genes: %s" % ", ".join(names), 26, UiTheme.GAIN)
	label("Gene slots for the next subspecies: %d" % bank.slots(), 26)
	if established:
		button("Keep evolving (multicellular stage)", func() -> void: _choose(true))
	button("Return to the main species", func() -> void: _choose(false))


func _choose(keep: bool) -> void:
	visible = false
	if keep:
		keep_playing.emit()
	else:
		end_run.emit()
