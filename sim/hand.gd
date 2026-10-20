class_name Hand
extends RefCounted
## The starting hand: three life cards dealt, pick one or reroll. Rerolls
## are limited; once gone, what's in front of you is your life.

const HAND_SIZE: int = 3

const EVENT_CARDS_DEALT: StringName = &"cards_dealt"
const EVENT_LIFE_STARTED: StringName = &"life_started"


static func deal(state: WorldState) -> void:
	if state.catalogue == null or state.catalogue.cards.size() < HAND_SIZE:
		# Nothing to deal from (tests, or thin content): start living.
		state.phase = WorldState.PHASE_LIVING
		return
	var ids: Array[StringName] = state.catalogue.card_ids()
	# Fisher-Yates with the seeded RNG, then take the first three.
	for i: int in range(ids.size() - 1, 0, -1):
		var j: int = state.rng.randi_range(0, i)
		var tmp: StringName = ids[i]
		ids[i] = ids[j]
		ids[j] = tmp
	state.hand = ids.slice(0, HAND_SIZE)
	state.add_event(EVENT_CARDS_DEALT, [Person.PLAYER_ID], {
		"cards": state.hand.map(func(c: StringName) -> String: return String(c)),
		"rerolls_left": state.rerolls_left,
	})


static func reroll(state: WorldState) -> void:
	if state.rerolls_left <= 0:
		return
	state.rerolls_left -= 1
	deal(state)


static func pick(state: WorldState, card_id: StringName) -> void:
	if not state.hand.has(card_id):
		return
	var card: LifeCard = state.catalogue.card(card_id)
	if card == null:
		return
	state.life_card = card_id
	TownBuilder.populate(state, card)
	state.phase = WorldState.PHASE_LIVING
	state.add_event(EVENT_LIFE_STARTED, [Person.PLAYER_ID], {"card": String(card_id)})
