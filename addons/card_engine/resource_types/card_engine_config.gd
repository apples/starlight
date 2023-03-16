class_name CardEngineConfig extends Resource


@export_dir var data_root := "res://data"
@export var cards_path := "cards/carddata"
@export var ability_costs_path := "cards/abilities/costs"
@export var ability_effects_path := "cards/abilities/effects"
@export var ability_triggers_path := "cards/abilities/triggers"
@export var design_notes_path: String = "cards/design_notes"

@export var card_script: Script
@export var ability_script: Script

@export_file var cost_template_path: String
@export_file var effect_template_path: String
@export_file var trigger_template_path: String



@export var card_control: PackedScene


@export var set_list: Array[String] = []

