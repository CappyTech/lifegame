extends Control
## The root. Owns the state and the catalogue, keeps the masthead visible,
## and swaps the screen under it according to where the sim is: dealing a
## hand, living a day, or inside an activity. Screens never touch the sim
## directly; they ask this node to apply a choice.

const HAND_SCREEN: PackedScene = preload("res://ui/screens/hand_screen.tscn")
const DAY_SCREEN: PackedScene = preload("res://ui/screens/day_screen.tscn")
const TALK_SCREEN: PackedScene = preload("res://ui/screens/talk_screen.tscn")
const CAB_SCREEN: PackedScene = preload("res://ui/screens/cab_screen.tscn")
const BURGER_SCREEN: PackedScene = preload("res://ui/screens/burger_screen.tscn")

## 0 means a fresh seed each launch. Set to replay a life.
@export var debug_seed: int = 0

var catalogue: Catalogue
var state: WorldState
var current: Control = null
var current_kind: String = ""
## True while an activity screen is showing its outcome after the sim has
## already closed the activity.
var awaiting_outcome: bool = false

@onready var background: ColorRect = %Background
@onready var day_label: Label = %DayLabel
@onready var slot_label: Label = %SlotLabel
@onready var known_label: Label = %KnownLabel
@onready var money_label: Label = %MoneyLabel
@onready var energy_label: Label = %EnergyLabel
@onready var host: MarginContainer = %Host


func _ready() -> void:
	background.color = get_theme_color("paper", "Tokens")
	catalogue = Catalogue.load_all()
	var life_seed: int = debug_seed if debug_seed != 0 else randi()
	state = WorldState.create(life_seed, catalogue)
	Sim.apply(state, {"type": "deal"})
	_route()


## Screens call this with a sim choice.
func apply(choice: Dictionary) -> void:
	var had_activity: bool = not state.activity.is_empty()
	if str(choice.get("type", "")) == "start":
		current_kind = ""  # a fresh screen for every activity
	Sim.apply(state, choice)
	if had_activity and state.activity.is_empty():
		awaiting_outcome = true
	_route()


func sleep() -> void:
	Sim.sleep(state)
	_route()


## An activity screen has shown its outcome and the player carried on.
func outcome_done() -> void:
	awaiting_outcome = false
	_route()


func _route() -> void:
	_refresh_masthead()
	var kind: String = "day"
	if state.phase == WorldState.PHASE_DEALING:
		kind = "hand"
	elif not state.activity.is_empty():
		kind = str(state.activity["kind"])
	elif awaiting_outcome:
		kind = current_kind
	if kind != current_kind or current == null:
		_show(kind)
	current.call("refresh", state)


func _show(kind: String) -> void:
	if current != null:
		host.remove_child(current)
		current.queue_free()
	var scene: PackedScene = DAY_SCREEN
	match kind:
		"hand":
			scene = HAND_SCREEN
		"talk":
			scene = TALK_SCREEN
		"cab_shift":
			scene = CAB_SCREEN
		"burger_shift":
			scene = BURGER_SCREEN
	current = scene.instantiate()
	current_kind = kind
	current.set("game", self)
	host.add_child(current)


func _refresh_masthead() -> void:
	var dealing: bool = state.phase == WorldState.PHASE_DEALING
	day_label.text = tr("ui.hand_masthead") if dealing else tr("ui.day").format({"day": state.day})
	var day_over: bool = state.slot >= WorldState.SLOTS_PER_DAY
	slot_label.text = "" if dealing else (tr("ui.slot.done") if day_over else tr("ui.slot." + Report.SLOT_KEYS[state.slot]))
	known_label.text = "" if dealing else tr("ui.known").format({"n": state.player_known})
	money_label.text = "" if dealing else tr("ui.money").format({"money": state.player_money})
	energy_label.text = "" if dealing else tr("ui.energy").format({"energy": state.player_energy})
