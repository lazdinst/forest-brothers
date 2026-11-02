extends Resource
## An NPC as content: names, portrait, which interactions it offers, where its dialogue lives,
## how its relationship stages are reached and what it trades. One definition per NPC; every
## NPC runs on the same interaction, dialogue and trade code. Names and people are fictional.
@export var id: StringName
## Short name for prompts ("Ģirts").
@export var display_name: String
## Full name for windows ("Ģirts Ozoliņš").
@export var full_name: String
## One line under the name in the dialogue window.
@export var description: String
## Portrait shown in the dialogue window; empty shows a plain silhouette.
@export var portrait: Texture2D
## Part of the portrait texture to show (empty rect: the whole texture).
@export var portrait_region: Rect2
## What the NPC says at the top of the trade window.
@export_multiline var trade_line: String
## Interactions offered, in order: &"talk", &"trade", &"leave" (later: recruit, give, ...).
@export var actions: Array[StringName] = [&"talk", &"leave"]
## Authored dialogue data (JSON, see docs/NPC_DIALOGUE.md).
@export_file("*.json") var dialogue_path: String
## Relationship stages from lowest to highest, each with the minimum values that reach it:
## [{"stage": "acquaintance", "familiarity": 2}, ...]. The first stage needs nothing.
@export var stages: Array[Dictionary] = [{"stage": "stranger"}]
## Suspicion at or above this caps the stage at the second stage.
@export var suspicion_cap: int = 3
## Limited trade stock: [{"id", "kind": "item"|"stores", "supply"/"stock", "amount", "label",
## "rubles", "lats", "max", "restock"}]. Items go to the carried inventory (or the goods chest);
## stores go to the camp stores. "max" is how many lots he has; "restock" lots come back per outing.
@export var trade_stock: Array[Dictionary] = []
