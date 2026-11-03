class_name GeneText
extends RefCounted
## Describes a gene in real numbers for the gene trees and the subspecies
## creator: what a brand-new founder gains from it, and what it costs.


## "Body 6 → 7 µm; Energy use 24.7 → 26.8/min", or the organelle's effect.
static func effect(id: String) -> String:
	var row := GeneCatalog.info(id)
	if row.has("feature"):
		var f: String = row["feature"]
		var before := Genome.new()
		var after := before.copy()
		GeneCatalog.apply(after, [id])
		var text := Feature.effect(f)
		if Ability.is_ability(f):
			text = Ability.card_text(f, after.feature(f), before.feature(f))
		return "Born with %s. %s" % [Feature.label(f), text]
	var base := Genome.new()
	var changed := base.copy()
	GeneCatalog.apply(changed, [id])
	return "; ".join(StatSheet.changes(base, changed))


static func label(id: String) -> String:
	return str(GeneCatalog.info(id).get("label", id))


## "2 slots" / "1 slot".
static func slot_text(id: String) -> String:
	var n := GeneCatalog.slots(id)
	return "%d slot%s" % [n, "" if n == 1 else "s"]
