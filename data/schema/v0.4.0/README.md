# v0.4.0 schema

- `progression.schema.json` validates identity, gacha pool, rewards and upgrade metadata.
- `balance.schema.json` validates v0.4 global parameters. Card and enemy values remain in their content files.
- `save.schema.json` validates `save_version: 2` checkpoints with persistent progression.

Cross-document card references and local progression invariants are checked by
`ProgressionContentAdapter` and `ProgressionEngine` after schema validation.
