class_name AppBootstrap
extends RefCounted

const InfrastructureResultScript := preload("res://src/infrastructure/infrastructure_result.gd")
const JsonDocumentLoaderScript := preload("res://src/infrastructure/json_document_loader.gd")
const BattleContentAdapterScript := preload("res://src/infrastructure/battle_content_adapter.gd")
const BattleBalanceAdapterScript := preload("res://src/infrastructure/battle_balance_adapter.gd")


static func create_services(run_seed: int) -> AppServices:
	return AppServices.new(SeededRandomService.new(run_seed))


static func load_battle_ports(
	run_seed: int,
	content_path: String,
	content_schema_path: String,
	balance_path: String,
	balance_schema_path: String,
	random_stream_name: StringName = &"battle.shuffle"
) -> InfrastructureResult:
	var loader := JsonDocumentLoaderScript.new()
	var content_loaded := loader.load_document(content_path, content_schema_path)
	if not content_loaded.ok:
		return content_loaded
	var cards: Variant = content_loaded.data.get("cards")
	if not cards is Array:
		return InfrastructureResultScript.failure(
			&"content_cards_missing",
			"Validated content document must contain a cards array.",
			{"source": content_path}
		)

	var balance_loaded := loader.load_document(balance_path, balance_schema_path)
	if not balance_loaded.ok:
		return balance_loaded

	var services := create_services(run_seed)
	return InfrastructureResultScript.success({
		"services": services,
		"content": BattleContentAdapterScript.new(cards),
		"balance": BattleBalanceAdapterScript.new(balance_loaded.data),
		"random": services.create_battle_random(random_stream_name),
	})
