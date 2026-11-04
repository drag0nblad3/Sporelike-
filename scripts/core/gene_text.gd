class_name GeneText
extends RefCounted
## Describes a gene in real numbers for the gene trees and the subspecies
## creator: what a brand-new founder gains from it, and what it costs.


## "Body 6 → 7 µm; Energy use 24.7 → 26.8/min", or the organelle's effect.
static func effect(id: String) -> String:
	var before := Genome.new()
	var after := before.copy()
	GeneCatalog.apply(after, [id])
	var f := GeneCatalog.feature_of(id)
	if f == "":
		return "; ".join(StatSheet.changes(before, after))
	var text := Feature.effect(f)
	if Ability.is_ability(f):
		text = Ability.card_text(f, after.feature(f), before.feature(f))
	var level := after.feature(f)
	var title := Feature.label(f) if level == 1 else "%s level %d" % [Feature.label(f), level]
	return "Born with %s. %s" % [title, text]


static func label(id: String) -> String:
	return GeneCatalog.label(id)


## "2 slots" / "1 slot".
static func slot_text(id: String) -> String:
	var n := GeneCatalog.slots(id)
	return "%d slot%s" % [n, "" if n == 1 else "s"]


## "Defense: Spines", the tree and branch the gene sits in.
static func place(id: String) -> String:
	for tree in GeneCatalog.BRANCHES:
		for branch in GeneCatalog.BRANCHES[tree]:
			var ids: Array = branch[1]
			if id in ids:
				return "%s: %s" % [GeneCatalog.TREE_NAMES[tree], branch[0]]
	return ""
