extends PanelContainer
## Shared frame for modal and existing training content. Rules stay in the caller.
const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")

func _init() -> void:
	theme = JournalTheme.create()
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
