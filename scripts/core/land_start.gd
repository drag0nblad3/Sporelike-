class_name LandStart
extends RefCounted
## The first land body of a run, read from how stage 2 ended: the colony's
## symmetry and colour carry over, and its FinalBody sets the shape (a
## creeping sole becomes a flat, wide-legged crawler; comb rows a long
## keeled runner; a holdfast a bulbous, raised sucker-mouth). Only parts
## that need no landmark are used.


static func recipe_for(plan: BodyPlan, tint: Color) -> AnimalRecipe:
	var recipe := AnimalRecipe.new()
	if plan.symmetry == Symmetry.RADIAL:
		recipe.put("symmetry", "radial")
	match plan.final_body:
		FinalBody.CRAWLER:
			recipe.put("shape", "flat")
			recipe.put("legs", "3")
			recipe.put("leg_length", "short")
			recipe.put("stance", "wide")
		FinalBody.SWIMMER:
			recipe.put("shape", "keel")
			recipe.put("segments", "6")
			recipe.put("taper", "narrow tail")
			recipe.put("tail", "spike")
			recipe.put("leg_length", "long")
		FinalBody.ANCHOR:
			recipe.put("shape", "bulb")
			recipe.put("segments", "3")
			recipe.put("head_at", "raised")
			recipe.put("neck", "short")
			recipe.put("mouth", "sucker")
			recipe.put("legs", "2")
	var hues := AnimalRecipe.HUES.size()
	recipe.picks["hue"] = roundi(tint.h * hues) % hues
	recipe.picks["hue2"] = (recipe.index("hue") + 3) % hues
	LandUnlocks.new().fix(recipe)
	return recipe
