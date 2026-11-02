class_name RivalCell
extends SpeciesCell
## A member of a rival species: behaves like one of yours but wears its
## species' colour and belongs to its RivalSpecies.

var colour := Color.WHITE
## Name of its RivalSpecies, for NicheLedger.
var group_name := ""


func tint() -> Color:
	return colour
