class_name Glossary
extends RefCounted
## The in-game explanations of every term, shown in the pause menu.
## Keep this in step with Genome, FoodKind and the population screen.

const TEXT := """[font_size=34][b]How it works[/b][/font_size]

[b]Energy[/b]: your fuel. Every trait costs energy each second just to have \
(its upkeep). Eat to refill it. At zero you starve.

[font_size=28][b]Traits[/b][/font_size] (0 to 1; higher is stronger but costs more upkeep)
[b]Size[/b]: a bigger body with a longer reach, but slower to turn.
[b]Speed[/b]: top swimming speed. Catches darting food and outruns hunters.
[b]Agility[/b]: how fast you speed up and turn.
[b]Sense[/b]: how far away you notice food and hunters.
[b]Armor[/b]: spikes that can deflect a hunter's bite.
[b]Toxin[/b]: poison that stings a hunter that bites you. Stung hunters back \
off for a while and learn to avoid toxic prey.
[b]Diet[/b]: 0 digests plants best, 1 digests meat best. In between gets less from both.
[b]Jaw[/b]: bite strength. Food harder than your jaw cannot be eaten at all.

[font_size=28][b]Food[/b][/font_size]
[b]Algae[/b] (green, plant): plentiful in the sunlit outer ring. Easy, low value.
[b]Plankton[/b] (yellow, meat): drifts in the middle ring and darts away when \
you come close. Rich if you can catch it.
[b]Shells[/b] (purple, meat): around the warm center. Very rich, but need a strong jaw.
[b]Motes[/b] (faint blue, plant): in the deep center. Hard to see, so they need keen sense.

[b]Food grades[/b]: every piece is a little different. Bigger, darker pieces \
are worth up to four times as much energy as small pale ones, but are tougher \
to crack, harder to spot, or flee faster. Small pale pieces are easy pickings.

[font_size=28][b]Dangers[/b][/font_size]
[b]Hunters[/b] (red): predators that chase the nearest prey they want. \
Armor and toxin both make them think twice.

[font_size=28][b]Generations[/b][/font_size]
[b]Generation[/b]: a timed round (top right shows time left). It ends when \
the timer runs out or you die.
[b]Species[/b]: the other cells of your kind. They eat, breed and die on \
their own. The top-left line shows their average traits.
[b]Births[/b]: well-fed cells split into offspring with small random mutations.
[b]Population screen[/b]: between generations it shows how your species \
changed and what killed it.
[b]Mutation choice[/b]: pick a trait to push your whole species toward.
[b]Influence[/b]: the more food you ate this generation, the stronger your choice.
[b]Multicellular progress[/b]: thriving generations (a big population and \
plenty of food eaten) move your species toward its next stage, where single \
cells band together into one body.
[b]Rebirth[/b]: you return as the offspring of a surviving cell. If all \
died, your species starts over from you.
"""
