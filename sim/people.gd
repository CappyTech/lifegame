class_name People
extends RefCounted
## The people system, v0. Pure functions over Person. Numbers are provisional
## and mirror the "people system" section of CLAUDE.md and docs/design.md.

const CARRY_ON_SCORE: float = 30.0
const NOISE: float = 3.0
const PRESSURE_LEAK: float = 0.75

const THRESHOLDS: Dictionary = {
	&"small": 8.0,
	&"medium": 20.0,
	&"big": 45.0,
}

## How much each need wears down per night. Rest is restored by activities,
## not by sleep alone, so that tiredness can build across a bad week.
const DRIFT: Dictionary = {
	&"money": -2.0,
	&"belonging": -3.0,
	&"ambition": -1.0,
	&"rest": -2.0,
}

const MEMORY_FADE: float = 0.98
const MEMORY_FADE_EMOTIONAL: float = 0.995
const MEMORY_FORGOTTEN_BELOW: float = 0.05


## A need barely matters until it is low, then it matters a lot.
static func urgency(need: float) -> float:
	var unmet: float = 100.0 - clampf(need, 0.0, 100.0)
	return unmet * unmet / 100.0


## Bucket with a small leak: a quarter drains each night, excess over
## "carry on as normal" is added.
static func next_pressure(previous: float, score: float) -> float:
	return previous * PRESSURE_LEAK + maxf(0.0, score - CARRY_ON_SCORE)


static func threshold_for(size: StringName) -> float:
	return float(THRESHOLDS.get(size, THRESHOLDS[&"small"]))


## Scores one option for one person. Noise is passed in so the caller owns
## the RNG and the function stays pure.
static func score_option(person: Person, option: Dictionary, noise: float) -> float:
	var score: float = float(option.get("base", 0.0))
	var needs: Dictionary = option.get("needs", {})
	for need: StringName in needs:
		score += urgency(float(person.needs.get(need, 60.0))) * float(needs[need])
	var traits: Dictionary = option.get("traits", {})
	for trait_name: StringName in traits:
		score += float(person.traits.get(trait_name, 0.0)) * float(traits[trait_name])
	var trust: Dictionary = option.get("trust", {})
	for who: StringName in trust:
		score += person.trust_toward(who) * float(trust[who])
	var resentment: Dictionary = option.get("resentment", {})
	for who: StringName in resentment:
		score += person.resentment_toward(who) * float(resentment[who])
	var mems: Dictionary = option.get("memories", {})
	for tag: StringName in mems:
		score += person.memory_weight(tag) * float(mems[tag])
	return score + noise


static func drift_needs(person: Person) -> void:
	for need: StringName in DRIFT:
		person.adjust_need(need, float(DRIFT[need]))


static func fade_memories(person: Person) -> void:
	var kept: Array[Dictionary] = []
	for m: Dictionary in person.memories:
		var fade: float = MEMORY_FADE_EMOTIONAL if bool(m.get("emotional", false)) else MEMORY_FADE
		m["weight"] = float(m["weight"]) * fade
		if float(m["weight"]) >= MEMORY_FORGOTTEN_BELOW:
			kept.append(m)
	person.memories = kept


## Words, not numbers: the band a trust value falls into, for the UI and
## the report. Keys exist in strings as rel.<band>.
static func trust_band(trust: float) -> StringName:
	if trust < -30.0:
		return &"cold"
	if trust < 0.0:
		return &"wary"
	if trust < 20.0:
		return &"civil"
	if trust < 50.0:
		return &"warm"
	return &"close"


## A mood word from needs: the lowest need wins once it is low.
## One of fine, low, tired, skint. Keys exist in strings as mood.<word>.
static func mood(p: Person) -> StringName:
	var lowest: StringName = &""
	var value: float = 101.0
	for need: StringName in p.needs:
		if float(p.needs[need]) < value:
			value = float(p.needs[need])
			lowest = need
	if value >= 40.0:
		return &"fine"
	match lowest:
		&"rest":
			return &"tired"
		&"money":
			return &"skint"
		_:
			return &"low"
