class_name TownBuilder
extends RefCounted
## Builds a starting town. For now one hand-written debug town so the day
## loop has people in it; life cards will replace this with authored
## templates plus generated names.


static func debug_town(world_seed: int) -> WorldState:
	var s: WorldState = WorldState.create(world_seed)
	s.player_money = 120
	s.player_energy = 80

	s.add_person(Person.from_dict({
		"id": "dean",
		"name": "Dean",
		"role": "burger_shop_manager",
		"needs": {"money": 40, "belonging": 45, "ambition": 50, "rest": 70},
		"traits": {"loyal": 0.3, "proud": 0.6},
		"relationships": {"player": {"trust": 10, "resentment": 0}},
		"options": [{
			"id": "quit", "size": "big", "base": 20,
			"needs": {"money": 0.35, "belonging": 0.4},
			"traits": {"loyal": -25},
			"trust": {"player": -0.15},
			"memories": {"talked": -2},
		}],
	}))

	s.add_person(Person.from_dict({
		"id": "pat",
		"name": "Auntie Pat",
		"role": "family",
		"needs": {"money": 55, "belonging": 50, "ambition": 80, "rest": 60},
		"traits": {"loyal": 0.8, "cautious": 0.7},
		"relationships": {"player": {"trust": 40, "resentment": 0}},
		"options": [{
			"id": "stops_inviting_you_round", "size": "medium", "base": 10,
			"needs": {"belonging": 0.5},
			"traits": {"loyal": -10},
			"trust": {"player": -0.1},
			"memories": {"talked": -4},
		}],
	}))
	return s
