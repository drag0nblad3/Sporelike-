class_name Glossary
extends RefCounted
## The in-game explanations of every term, shown in the pause menu.
## Keep this in step with Genome, FoodKind and the population screen.

const TEXT := """[font_size=34][b]How it works[/b][/font_size]

[b]Energy[/b]: your fuel, shown by the bar across the top. Every trait costs \
energy each second just to have (its upkeep), so the bar keeps emptying. Eat \
to refill it. When it runs out you starve.

[b]Units[/b]: lengths are in micrometres (µm, thousandths of a millimetre), \
speeds in µm per second, and energy is the same energy shown on the bar.

[font_size=28][b]Traits[/b][/font_size] (0 to 1; higher is stronger but costs more upkeep)
[b]Size[/b]: a bigger body with a longer reach that chews faster, but slower \
to turn and costlier to run. Grow big enough and hunters can no longer \
swallow you.
[b]Speed[/b]: top swimming speed. Catches darting food and outruns hunters. \
Each step adds a little less than the last, but as your species gets faster \
the hunters and darting food around it slow down very slightly.
[b]Agility[/b]: how fast you speed up and turn.
[b]Sense[/b]: how far away you notice food and hunters.
[b]Armor[/b]: spikes that can deflect a hunter's bite.
[b]Toxin[/b]: poison that stings a hunter that bites you. Stung hunters back \
off for a while and learn to avoid toxic prey.
[b]Diet[/b]: 0 digests plants best, 1 digests meat best. In between gets less from both.
[b]Jaw[/b]: bite strength. Food a little harder than your jaw can still be \
chewed through: stay on top of it while it shakes until it breaks open. Bigger \
bodies chew faster. Food far harder than your jaw cannot be eaten.

[font_size=28][b]Food[/b][/font_size]
The sea goes on forever in every direction, and food covers most of the \
floor in large connected fields, cut by channels of bare sand. Regions shade \
from algae meadows to open water to dark trenches, with vents in the trenches.
[b]Hidden fields[/b]: rare stretches that look like bare sand but hold faint, \
extra-rich food that is very hard to sense.
[b]Algae[/b] (green, plant): teal meadows, one where your species starts. \
Easy, low value.
[b]Plankton[/b] (yellow, meat): clouds over blue open water, often at a \
meadow's edge. Drifts and darts away when you come close. Rich if caught.
[b]Shells[/b] (purple, meat): beds on glowing orange vents, often beside \
trenches. Very rich, but need a strong jaw.
[b]Motes[/b] (faint blue, plant): dark trenches. Hard to see, so they need keen sense.

[b]Food grades[/b]: every piece is a little different. Bigger, darker pieces \
are worth a bit more energy, but are much tougher to crack, harder to spot, \
and faster and nimbler at dodging. Small pale pieces are slow, sluggish and \
soft: easy pickings.

[font_size=28][b]Dangers[/b][/font_size]
[b]Hunters[/b] (red): predators that chase the nearest prey they want. \
Armor and toxin both make them think twice.

[font_size=28][b]Generations[/b][/font_size]
[b]Generation[/b]: a timed round (top right shows time left). It ends when \
the timer runs out or you die.
[b]Fed[/b] (top right): energy you have gathered this generation compared \
with what your body burns in a whole generation. 100% means you broke even. \
A bigger, more evolved body costs more to run, so it must gather more.
[b]Species[/b]: the other cells of your kind. They eat, breed and die on \
their own, and roam between nearby patches when food runs out. Cells left \
far behind you sleep until you come back. The \
top-left line shows their average traits: a description of \
everyone in the species this generation, so deaths do not drag it down.
[b]Births[/b]: well-fed cells split into offspring with small random mutations.
[b]Population screen[/b]: between generations it shows how your species \
changed and what killed it.
[b]Mutation choice[/b]: pick a trait to push your whole species toward. \
Each pick is a big step, and bigger still when it pushes a trait further the \
way your species already leans, so repeated picks build a specialist. \
Picks only ever add; diet is the one trait you can push either way. \
[b]Leaner metabolism[/b], offered often, simply burns less energy \
(12.5% less per pick at x1, up to 50% less).
[b]Upgrades[/b]: each button lists every number it changes for a cell like \
you, gains and costs alike, such as "Top speed 59 → 62 µm/s". Pushing a trait far enough \
unlocks new body parts that can appear as choices:
  [b]Grabbing cilia[/b] (from high agility): snatch food that is very close.
  [b]Tail bud[/b] (from high speed): grow another tail; faster, but costs more.
  [b]Eye cluster[/b] (from high sense): spot food from farther away.
  [b]Jet boost[/b] (from speed): tap the Jet button for a quick burst. Cells \
of your species jet away from hunters on their own.
  [b]Sticky coat[/b] (from armor): darting food that comes close gets stuck.
  [b]Scent trail[/b] (from very high sense): an arrow by your cell points to \
the nearest food your body can eat well, even in hidden fields. Cells of your \
species follow the scent too.
  [b]Gut lining[/b] (any time): a new species digests only 80% of what its \
diet allows; each level adds 10%, up to 110%.
  [b]Fat store[/b] (any time): keep eating past full. Stored food shows as a \
gold bar over the energy bar and is burned once the stomach runs low.
[b]Hard times[/b]: after a bad generation (your species shrank a lot, or you \
starved), your species adapts to burn less energy, so the game keeps going.
[b]Influence[/b]: the better you fed yourself (the Fed number), the \
stronger your choice: from x0.5 up to x2.
[b]Multicellular progress[/b]: thriving generations (a big population and \
a good Fed score) move your species toward its next stage, where single \
cells band together into one body. Your view also widens slowly as you progress.
[b]Rebirth[/b]: you return as the offspring of a surviving cell. If all \
died, your species starts over from you.
"""
