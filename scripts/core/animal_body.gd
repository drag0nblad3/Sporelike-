class_name AnimalBody
extends RefCounted
## The body plan of a stage 3 land animal: a chain of segments from the
## head back, each with a shape, a size, 0 to 2 pairs of limbs and maybe a
## part on top, plus the limbs' build, extras on the head and tail, and its
## colours. AnimalRandom makes varied ones; AnimalGait reads how it moves.

## Width, height and length of each segment shape, per unit of radius.
const SHAPES := {
	"round": Vector3(1.0, 0.85, 1.25), "flat": Vector3(1.35, 0.55, 1.2),
	"keel": Vector3(0.75, 1.3, 1.2), "tube": Vector3(0.8, 0.8, 1.8),
	"bulb": Vector3(1.25, 1.15, 1.3),
}

var radii := PackedFloat32Array()
var shapes: Array[String] = []
## Pairs of limbs on each segment (0 to 2), and how long they are.
var leg_pairs := PackedByteArray()
var leg_lengths := PackedFloat32Array()
## What grows on top of each segment: "", "spikes", "sail" or "plates".
var tops: Array[String] = []
## "leg" (jointed, with feet) or "tentacle" (bendy, many joints).
var limb := "leg"
## Bones in each limb (2 to 4 for legs).
var joints := 2
## "pad", "claw", "spike" or "sucker".
var foot := "pad"
## How much the middle of the back arches up (0 = flat).
var arch := 0.0
## How far out to the sides the feet stand (low = upright, high = sprawling).
var sprawl := 0.6
## A single big claw on one side of the head (-1 or 1), or 0 for none.
var claw_side := 0
## "", "fork", "club" or "spike".
var tail := ""
## Where the head sits: "front" (leading the body), "raised" (up on top of
## the front), "low" (slung under the front) or "middle" (rising from the
## middle of the back).
var head_at := "front"
## "two-sided" (mirrored), "radial" (limbs and eyes spread all round) or
## "lopsided" (one side's limbs and eyes bigger than the other's).
var symmetry := "two-sided"
## "none", "smile", "beak", "mandibles", "tusks", "trunk" or "sucker".
var mouth := "smile"
## How thick and strong the legs are (1 = thin, up to about 2.6 = mighty).
var leg_build := 1.0
## Which way the knees bend: "up" (arched), "high" (crouched, knees above
## the body like a spider) or "back" (backward knees, like a bird's).
var knee := "up"
## A neck between the head and the body, in head radii (0 = none).
var neck := 0.0
## Pairs of arms held up at the front (not walked on), 0 to 2, and what
## they end in: "hand", "pincer" or "blade".
var arm_pairs := 0
var arm_tip := "hand"
var horns := 0
var feelers := false
var eye_stalks := false
## 1 to 8 eyes; an odd count puts one in the middle.
var eyes := 2
## Where the eyes sit: "front" (facing ahead), "wide" (on the sides of the
## head) or "top" (up on the crown).
var eye_set := "front"
## One smooth skin over the whole body instead of separate segments.
var smooth := false
## "plain", "stripes", "spots" or "bands".
var pattern := "plain"
var hue := 0.3
var hue2 := 0.6


func segments() -> int:
	return radii.size()


func pairs() -> int:
	var n := 0
	for count in leg_pairs:
		n += count
	return n


## Limbs it walks on: mirrored pairs, or a ring of 2n+1 per segment when radial.
func limb_count() -> int:
	if symmetry != "radial":
		return pairs() * 2
	var n := 0
	for count in leg_pairs:
		n += count * 2 + 1 if count > 0 else 0
	return n


func shape_scale(i: int) -> Vector3:
	var s: Vector3 = SHAPES.get(shapes[i], SHAPES["round"])
	return s


## Half the segment's length along the body.
func half_length(i: int) -> float:
	return radii[i] * shape_scale(i).z


func longest_leg() -> float:
	var most := 0.0
	for i in segments():
		if leg_pairs[i] > 0:
			most = maxf(most, leg_lengths[i])
	return most


## How high the body rides above the ground: on its legs, or on its belly.
func ride_height() -> float:
	if pairs() == 0:
		return 0.0
	var lift := 0.6 if limb == "leg" else 0.3
	var knees := {"high": 0.6, "back": 1.1}.get(knee, 1.0) as float
	return longest_leg() * lift * (1.15 - sprawl * 0.5) * knees


func gait() -> String:
	return AnimalGait.of(self)


func speed() -> float:
	return AnimalGait.speed(self)


func color() -> Color:
	return Color.from_hsv(hue, 0.55, 0.75)


func color2() -> Color:
	return Color.from_hsv(hue2, 0.6, 0.85)


func describe() -> String:
	return AnimalWords.describe(self)
