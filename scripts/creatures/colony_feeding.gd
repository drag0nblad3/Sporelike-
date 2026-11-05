class_name ColonyFeeding
extends RefCounted
## What the player's colony eats each frame through its mouth cells and
## tentacle tips from the open water: loose food and single cells small
## enough to swallow, each weighed by its FeedingStyle. (ColonyWorld feeds
## it plants, marine snow and remains.)


## Returns the energy taken in this frame, before digestion.
static func eat(colony: Colony, eco: Ecosystem) -> float:
	var style := colony.plan.style
	var gained := 0.0
	var reach := FeedingStyle.mouth_reach(style) + FinalBody.reach_bonus(colony.plan.final_body)
	var largest := FeedingStyle.prey_radius(style)
	var prey := eco.prey_list()
	for point in colony.eat_points():
		var at := Vector2(point.x, point.z)
		gained += eco.food.take_near(at, reach) * FeedingStyle.food_factor(style)
		if largest <= 0.0:
			continue
		for org in prey:
			if not org.alive or org.radius() > largest:
				continue
			if org.flat_pos().distance_to(at) <= org.radius() + reach:
				gained += maxf(org.energy, 0.0) + FeedingStyle.prey_bonus(style)
				org.die("eaten")
	return gained
