class_name SenseReach
extends RefCounted
## How far past the screen edge a body can feel things (SenseCues shows them
## as edge glows for food fields and red "!" marks for hunters). Starts very
## low and grows with the sense trait, Eyespot clusters and Chemoreceptors.

## Sight (world units) that only covers what is already on screen.
const BASE_SIGHT := 5.0
## Each unit of sight past BASE_SIGHT reaches this far off screen.
const PER_SIGHT := 1.5
## Chemoreceptors taste the water this much farther out.
const SCENT_BONUS := 4.0


## World units past the screen edge; 0 means nothing off screen is felt.
static func beyond_screen(g: Genome) -> float:
	return maxf(0.0, g.sense_range() - BASE_SIGHT) * PER_SIGHT \
		+ SCENT_BONUS * g.feature("food_scent")
