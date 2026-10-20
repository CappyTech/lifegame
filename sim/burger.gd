class_name Burger
extends RefCounted
## The burger shop shift: you learn a business. Choose a shift, engage (or
## keep your head down), assemble order tickets against the clock, then
## wages, tips and the owner's trust.

const JOB: StringName = &"burger_shop"
const OWNER: StringName = &"dean"
const MENU: Array[String] = ["burger", "cheeseburger", "fries", "drink", "shake"]
const SHIFTS: Dictionary = {
	"lunch": {"wage": 55, "tickets": 6, "energy": -28},
	"evening": {"wage": 45, "tickets": 4, "energy": -18},
}
const TIP_PER_TICKET: int = 2
const TIP_LOST_PER_MISTAKE: int = 3
const SKILL_PER_SHIFT: float = 0.06
const SKILL_AUTO: float = 0.02
const AUTO_PAY_FACTOR: float = 0.9

const CONVERSATION_ENGAGE: StringName = &"burger_engage"
## When Dean is close to quitting (the overnight warning has shown) and you
## haven't had the conversation yet, the shift opens with him pulling you
## aside. Timed: silence is an answer.
const CONVERSATION_WORD: StringName = &"manager_word"
const WORD_TAGS: Array[StringName] = [&"heard_out", &"promised_more", &"dismissed", &"brushed_off"]

const EVENT_SHIFT_CHOSEN: StringName = &"shift_chosen"
const EVENT_TICKET_DONE: StringName = &"ticket_done"
const EVENT_TICKET_MISTAKE: StringName = &"ticket_mistake"
const EVENT_SHIFT_WORKED: StringName = &"shift_worked"

const ENGAGE_FALLBACK: Dictionary = {
	"owner": {"id": "owner", "trust": 3.0, "belonging": 6.0, "memory_tag": "talked"},
	"customers": {"id": "customers"},
	"head_down": {"id": "head_down"},
}


static func start(state: WorldState, auto: bool) -> bool:
	if auto and state.is_auto_unlocked(JOB):
		_auto(state)
		return true
	state.activity = {
		"kind": String(Sim.ACTIVITY_BURGER),
		"phase": "choose_shift",
		"shift": "",
		"engaged": "",
		"tickets": [],
		"ticket": 0,
		"item": 0,
		"mistakes": 0,
		"relationships": [],
	}
	return true


static func step(state: WorldState, choice: Dictionary) -> void:
	var a: Dictionary = state.activity
	match str(a["phase"]):
		"choose_shift":
			var shift: String = str(choice.get("shift", ""))
			if not SHIFTS.has(shift):
				return
			a["shift"] = shift
			a["tickets"] = _tickets(state, int(SHIFTS[shift]["tickets"]))
			a["conversation"] = String(_engage_conversation(state))
			state.add_event(EVENT_SHIFT_CHOSEN, [Person.PLAYER_ID], {"job": String(JOB), "shift": shift})
			a["phase"] = "engage"
		"engage":
			_engage(state, a, str(choice.get("choice", "head_down")))
		"work":
			_work(state, a, str(choice.get("item", "")))


static func _tickets(state: WorldState, count: int) -> Array:
	var out: Array = []
	for _t: int in count:
		var n: int = state.rng.randi_range(2, 4)
		var items: Array = []
		for _i: int in n:
			items.append(MENU[state.rng.randi_range(0, MENU.size() - 1)])
		out.append(items)
	return out


## Which conversation opens the shift.
static func _engage_conversation(state: WorldState) -> StringName:
	var owner: Person = state.person(OWNER)
	if owner == null or not bool(owner.warned.get(&"quit", false)):
		return CONVERSATION_ENGAGE
	for tag: StringName in WORD_TAGS:
		if owner.memory_weight(tag) > 0.0:
			return CONVERSATION_ENGAGE
	return CONVERSATION_WORD


static func _engage(state: WorldState, a: Dictionary, with: String) -> void:
	a["engaged"] = with
	var owner: Person = state.person(OWNER)
	var conv_id: StringName = StringName(str(a.get("conversation", CONVERSATION_ENGAGE)))
	var effects: Dictionary = Activity.choice_effects(state, conv_id, with, ENGAGE_FALLBACK)
	a["reply_key"] = str(effects.get("reply_key", ""))
	var spoke: bool = with == "owner" or conv_id == CONVERSATION_WORD
	if owner != null and spoke:
		var e: SimEvent = state.add_event(Activity.EVENT_TALKED, [Person.PLAYER_ID, OWNER], {"choice": with, "conversation": String(conv_id)})
		Activity.push(a, "relationships", Activity.apply_choice_effects(state, owner, effects, e.id))
		if conv_id == CONVERSATION_WORD:
			# Being heard eases the pressure; being brushed off does not.
			var relief: float = 0.5 if with == "hear_out" or with == "promise" else 1.0
			for option_id: StringName in owner.pressure:
				owner.pressure[option_id] = float(owner.pressure[option_id]) * relief
	a["phase"] = "work"


static func _work(state: WorldState, a: Dictionary, item: String) -> void:
	var tickets: Array = a["tickets"]
	var ti: int = int(a["ticket"])
	if ti >= tickets.size():
		return
	var ticket: Array = tickets[ti]
	var ii: int = int(a["item"])
	if item == str(ticket[ii]):
		ii += 1
		if ii >= ticket.size():
			state.add_event(EVENT_TICKET_DONE, [Person.PLAYER_ID], {"ticket": ti})
			ti += 1
			ii = 0
	else:
		a["mistakes"] = int(a["mistakes"]) + 1
		state.add_event(EVENT_TICKET_MISTAKE, [Person.PLAYER_ID], {"ticket": ti, "wanted": ticket[ii], "got": item})
	a["ticket"] = ti
	a["item"] = ii
	if ti >= tickets.size():
		_finish(state, a)


static func _finish(state: WorldState, a: Dictionary) -> void:
	var shift: Dictionary = SHIFTS[str(a["shift"])]
	var tickets: Array = a["tickets"]
	var mistakes: int = int(a["mistakes"])
	var items: int = 0
	for t: Array in tickets:
		items += t.size()
	var tips: int = maxi(0, TIP_PER_TICKET * tickets.size() - TIP_LOST_PER_MISTAKE * mistakes)
	var out: Dictionary = Activity.new_outcome()
	out["money"] = int(shift["wage"]) + tips
	out["energy"] = int(shift["energy"])
	out["lines"] = [{"key": "outcome.burger_shift", "params": {"wage": shift["wage"], "tips": tips, "mistakes": mistakes}}]
	out["relationships"] = a["relationships"]

	var owner: Person = state.person(OWNER)
	if owner != null:
		var trust: float = (3.0 if str(a["engaged"]) == "owner" else 1.0) - mistakes * 0.5
		owner.adjust_trust(Person.PLAYER_ID, trust)
		if mistakes >= 3:
			Activity.push(out, "lines", {"key": "outcome.owner_unimpressed", "params": {"name": owner.name}})
		if str(a["engaged"]) != "owner":
			Activity.push(out, "relationships", {"name": owner.name, "key": "outcome.rel.up" if trust > 0.0 else "outcome.rel.down"})

	var accuracy: float = 1.0 - float(mistakes) / float(maxi(1, items))
	state.add_skill(JOB, SKILL_PER_SHIFT * maxf(0.0, accuracy))
	Activity.push(out, "learned", "learned.burger." + str(a["shift"]))
	state.add_event(EVENT_SHIFT_WORKED, [Person.PLAYER_ID], {"job": String(JOB), "pay": out["money"], "mistakes": mistakes, "auto": false})
	Activity.check_unlock(state, JOB, out)
	Activity.finish(state, out)


static func _auto(state: WorldState) -> void:
	var shift: Dictionary = SHIFTS["evening"]
	var tickets: int = int(shift["tickets"])
	var mistakes: int = int(round((1.0 - state.skill(JOB)) * tickets * 0.5))
	var tips: int = maxi(0, TIP_PER_TICKET * tickets - TIP_LOST_PER_MISTAKE * mistakes)
	var out: Dictionary = Activity.new_outcome()
	out["money"] = int(round((int(shift["wage"]) + tips) * AUTO_PAY_FACTOR))
	out["energy"] = int(shift["energy"])
	out["lines"] = [{"key": "outcome.burger_shift_auto", "params": {"earned": out["money"], "mistakes": mistakes}}]
	state.add_skill(JOB, SKILL_AUTO)
	state.add_event(EVENT_SHIFT_WORKED, [Person.PLAYER_ID], {"job": String(JOB), "pay": out["money"], "mistakes": mistakes, "auto": true})
	state.activity = {"kind": String(Sim.ACTIVITY_BURGER)}
	Activity.finish(state, out)
