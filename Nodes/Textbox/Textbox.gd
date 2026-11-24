extends CanvasLayer

enum State {READING, FINISHED}

@onready var character_name_node : RichTextLabel = $Full/OuterMargin/CharacterName
@onready var dialogue_node : RichTextLabel = $Full/OuterMargin/InnerMargin/Dialogue
@onready var timer : Timer = $Timer
var end_dialogue_manually : bool = true
var character_read_rate : float = 0.025
var current_state : int = State.READING
var visible_characters : int = 0
var total_characters : int = 0
var character_name : String = "Default"
var dialogue : String = "The quick brown fox jumped over the lazy dog."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.dialogue_started.emit(self.name)
	timer.wait_time = character_read_rate
	dialogue_node.text = dialogue
	character_name_node.text = character_name
	total_characters = len(dialogue_node.text)
	dialogue_node.visible_characters = 0
	timer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") && end_dialogue_manually:
		match current_state:
			State.READING:
				timer.stop()
				dialogue_node.visible_characters = total_characters
				current_state = State.FINISHED
			State.FINISHED:
				_finish()

func _finish():
	Events.dialogue_finished.emit(self.name)
	self.queue_free()

func _on_timer_timeout() -> void:
	dialogue_node.visible_characters += 1
	
	if dialogue_node.visible_characters == total_characters:
		current_state = State.FINISHED
	else:
		match dialogue.substr(dialogue_node.visible_characters - 1, 1):
			'.', '!', '?', ',': # Waits a beat to read the next character if there's a pause in speech.
				await get_tree().create_timer(0.1).timeout
				timer.start()
			_:
				timer.start()
