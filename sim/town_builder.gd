class_name TownBuilder
extends RefCounted
## Builds the people of a town. Anchors come from the life card's template;
## passers-by come from a fixed pool with seeded variation later. Names are
## generated data, not string keys.

const PASSENGERS: Array[Dictionary] = [
	{"id": "maureen", "name": "Maureen", "trait": "regular", "home": "council", "knows": "council_sale"},
	{"id": "kev", "name": "Kev", "trait": "chatty", "home": "estate", "knows": ""},
	{"id": "lads", "name": "Lads from the Crown", "trait": "late_lads", "home": "crown", "knows": ""},
	{"id": "mr_akhtar", "name": "Mr Akhtar", "trait": "quiet", "home": "retail_park", "knows": "retail_unit"},
	{"id": "shannon", "name": "Shannon", "trait": "chatty", "home": "hospital", "knows": ""},
	{"id": "bill", "name": "Bill", "trait": "regular", "home": "station", "knows": ""},
	{"id": "jo", "name": "Jo", "trait": "quiet", "home": "hospital", "knows": ""},
	{"id": "tasha", "name": "Tasha", "trait": "chatty", "home": "estate", "knows": ""},
]


static func dean() -> Person:
	return Person.from_dict({
		"id": "dean",
		"name": "Dean",
		"role": "burger_shop_manager",
		"conversation": "dean_catch_up",
		"needs": {"money": 40, "belonging": 45, "ambition": 50, "rest": 70},
		"traits": {"loyal": 0.3, "proud": 0.6},
		"relationships": {"player": {"trust": 10, "resentment": 0}},
		"options": [{
			"id": "quit", "size": "big", "base": 20,
			"needs": {"money": 0.35, "belonging": 0.4},
			"traits": {"loyal": -25},
			"trust": {"player": -0.15},
			"memories": {"talked": -2, "asked_after_them": -3, "offered_cover": -6, "heard_out": -6, "promised_more": -3, "dismissed": 8, "brushed_off": 6, "pushed": 2},
		}],
	})


static func pat() -> Person:
	return Person.from_dict({
		"id": "pat",
		"name": "Auntie Pat",
		"role": "family",
		"conversation": "pat_catch_up",
		"needs": {"money": 55, "belonging": 50, "ambition": 80, "rest": 60},
		"traits": {"loyal": 0.8, "cautious": 0.7},
		"relationships": {"player": {"trust": 40, "resentment": 0}},
		"options": [{
			"id": "stops_inviting_you_round", "size": "medium", "base": 10,
			"needs": {"belonging": 0.5},
			"traits": {"loyal": -10},
			"trust": {"player": -0.1},
			"memories": {"talked": -4, "helped_out": -6},
		}],
	})


## Fills a fresh state from a life card.
static func populate(state: WorldState, card: LifeCard) -> void:
	state.player_money = card.start_money
	state.player_energy = card.start_energy
	state.add_person(dean())
	match card.anchor:
		&"uncle_chippy":
			state.add_person(Person.from_dict({
				"id": "ray", "name": "Uncle Ray", "role": "chippy_owner", "conversation": "ray_catch_up",
				"needs": {"money": 60, "belonging": 40, "ambition": 20, "rest": 35},
				"traits": {"loyal": 0.7, "cautious": 0.6},
				"relationships": {"player": {"trust": 35, "resentment": 0}},
				"options": [{
					"id": "sells_up", "size": "big", "base": 15,
					"needs": {"rest": 0.5, "ambition": 0.1},
					"trust": {"player": -0.2},
					"memories": {"helped_out": -8, "talked": -2, "talked_round": -4, "suggested_selling": 6, "offered_to_take_over": -8},
				}],
			}))
		&"mum_council_friend":
			state.add_person(Person.from_dict({
				"id": "carol", "name": "Carol", "role": "council_clerk", "conversation": "carol_catch_up",
				"needs": {"money": 65, "belonging": 55, "ambition": 50, "rest": 60},
				"traits": {"cautious": 0.8, "loyal": 0.5},
				"relationships": {"player": {"trust": 20, "resentment": 0}},
				"options": [],
			}))
		&"mate_cab_office":
			state.add_person(Person.from_dict({
				"id": "stevo", "name": "Stevo", "role": "cab_controller", "conversation": "stevo_catch_up",
				"needs": {"money": 45, "belonging": 60, "ambition": 55, "rest": 50},
				"traits": {"loyal": 0.6, "proud": 0.4},
				"relationships": {"player": {"trust": 45, "resentment": 0}},
				"options": [{
					"id": "leaves_town", "size": "big", "base": 15,
					"needs": {"money": 0.3, "ambition": 0.3},
					"traits": {"loyal": -20},
					"trust": {"player": -0.1},
					"memories": {"talked": -3, "talked_round": -6, "encouraged_to_leave": 5, "put_ideas": 2},
				}],
			}))
		&"nan_estate":
			state.add_person(pat())
	for pd: Dictionary in PASSENGERS:
		state.passers_by[pd["id"]] = {
			"name": pd["name"], "trait": pd["trait"], "home": pd["home"],
			"knows": pd["knows"], "rides": 0, "trust": 0.0,
		}


## A hand-written town with no life card, for tests and quick runs.
static func debug_town(world_seed: int, catalogue: Catalogue = null) -> WorldState:
	var s: WorldState = WorldState.create(world_seed, catalogue)
	s.phase = WorldState.PHASE_LIVING
	s.player_money = 120
	s.player_energy = 80
	s.add_person(dean())
	s.add_person(pat())
	for pd: Dictionary in PASSENGERS:
		s.passers_by[pd["id"]] = {
			"name": pd["name"], "trait": pd["trait"], "home": pd["home"],
			"knows": pd["knows"], "rides": 0, "trust": 0.0,
		}
	return s
