class_name VillageStatus
extends RefCounted
## The stage 4 status lines: frame rate and generation clock, people,
## food and the elder's health, the rival tribe's mood, the raid, and the
## run goals and each job's learning bar.


static func text(lab: VillageLab) -> String:
	var village := lab.village
	var left := ceili(maxf(lab.generations.time_left, 0.0))
	var lines := PackedStringArray()
	lines.append("Stage 4 test  ·  %d FPS  ·  Generation %d of %d  ·  %d:%02d left" % [
		roundi(Engine.get_frames_per_second()),
		mini(lab.generations.number, VillageRun.GENERATIONS), VillageRun.GENERATIONS,
		left / 60, left % 60])
	lines.append("People %d/%d  ·  Food %d/%d  ·  Elder %d/%d  ·  Carrying %d" % [
		village.people(), VillageRun.WIN_PEOPLE, village.stock, village.stock_cap(),
		ceili(maxf(village.elder.health, 0.0)), roundi(village.elder.max_health),
		village.food.carried])
	lines.append("Rival tribe: %d, %s  ·  %s" % [lab.rival.size(), lab.rival.mood(), _raid(lab)])
	lines.append(lab.run.goals_text())
	var bars := PackedStringArray()
	for job: int in [VillageJob.GATHER, VillageJob.HUNT, VillageJob.GUARD, VillageJob.IDLE]:
		var done := village.learning.offers(job).is_empty()
		bars.append("%s %s" % [Discovery.learner(job),
			"all" if done else "%d%%" % roundi(village.learning.share(job) * 100.0)])
	lines.append("Learning: " + "  ·  ".join(bars))
	return "\n".join(lines)


static func _raid(lab: VillageLab) -> String:
	var raids := lab.raids
	if raids.active:
		return "RAID under way (%d attackers)" % raids.actors.size()
	if raids.done:
		return "Raid survived"
	if not raids.warned:
		return "No raid in sight"
	var share := 1.0 - lab.generations.time_left / lab.generations.length
	var wait := ceili(maxf((VillageRaids.WHEN - share) * lab.generations.length, 0.0))
	return "RAID in %d s" % wait
