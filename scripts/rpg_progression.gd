class_name RpgProgression
extends RefCounted

const SKILLS := {
	"quiet_step": {
		"name": "Quiet Step",
		"description": "Walking and vaulting create 32% less acoustic trail."
	},
	"charged_pulse": {
		"name": "Charged Pulse",
		"description": "Arc pulses stun Echo Scavengers for 4 seconds longer."
	},
	"insulated_pack": {
		"name": "Insulated Pack",
		"description": "Scavenger attacks drain 50% less flashlight charge."
	}
}

var level := 1
var experience := 0
# Mara begins as a trained field engineer, so the player chooses one opening
# specialty before the first objective rather than waiting through a prologue.
var skill_points := 1
var companion_trust := 0
var skills := {
	"quiet_step": false,
	"charged_pulse": false,
	"insulated_pack": false
}

func experience_to_next() -> int:
	return 90 + (level - 1) * 65

func gain_experience(amount: int) -> int:
	experience += max(0, amount)
	var levels_gained := 0
	while experience >= experience_to_next():
		experience -= experience_to_next()
		level += 1
		skill_points += 1
		levels_gained += 1
	return levels_gained

func can_unlock(skill_id: String) -> bool:
	return skill_points > 0 and skills.has(skill_id) and not bool(skills[skill_id])

func unlock(skill_id: String) -> bool:
	if not can_unlock(skill_id):
		return false
	skills[skill_id] = true
	skill_points -= 1
	return true

func has_skill(skill_id: String) -> bool:
	return bool(skills.get(skill_id, false))

func gain_companion_trust(amount: int = 1) -> void:
	companion_trust = clampi(companion_trust + amount, 0, 3)

func to_save_data() -> Dictionary:
	return {
		"level": level,
		"experience": experience,
		"skill_points": skill_points,
		"companion_trust": companion_trust,
		"skills": skills.duplicate()
	}

func load_save_data(data: Dictionary) -> void:
	level = max(1, int(data.get("level", 1)))
	experience = max(0, int(data.get("experience", 0)))
	skill_points = max(0, int(data.get("skill_points", 0)))
	companion_trust = clampi(int(data.get("companion_trust", 0)), 0, 3)
	var saved_skills: Dictionary = data.get("skills", {})
	for skill_id in skills:
		skills[skill_id] = bool(saved_skills.get(skill_id, false))
