import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const testDirectory = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(testDirectory, "..", "..");
const balance = JSON.parse(
  fs.readFileSync(
    path.join(projectRoot, "data", "balance", "v0.2.0", "balance_draft.json"),
    "utf8",
  ),
);

function collectObjectKeys(value, keys = []) {
  if (Array.isArray(value)) {
    for (const item of value) {
      collectObjectKeys(item, keys);
    }
    return keys;
  }
  if (value && typeof value === "object") {
    for (const [key, child] of Object.entries(value)) {
      keys.push(key);
      collectObjectKeys(child, keys);
    }
  }
  return keys;
}

function countBy(items, selector) {
  return items.reduce((result, item) => {
    const key = String(selector(item));
    result[key] = (result[key] ?? 0) + 1;
    return result;
  }, {});
}

test("balance uses the frozen corruption field", () => {
  const keys = collectObjectKeys(balance);
  assert.equal(keys.includes("pollution"), false);
  assert.equal(keys.includes("corruption"), true);
  assert.equal(keys.includes("attention"), true);
});

test("card IDs and distributions match the v0.2.0 target", () => {
  assert.equal(balance.schema_version, 1);
  assert.equal(balance.cards.length, 20);
  assert.equal(
    new Set(balance.cards.map((card) => card.id)).size,
    balance.cards.length,
  );
  assert.deepEqual(countBy(balance.cards, (card) => card.cost), {
    0: 2,
    1: 7,
    2: 8,
    3: 3,
  });
  assert.deepEqual(countBy(balance.cards, (card) => card.rarity), {
    common: 10,
    uncommon: 6,
    rare: 3,
    unique: 1,
  });
});

test("enemy pressure rule is parameterized and reset per battle", () => {
  assert.deepEqual(balance.combat.enemy_pressure, {
    start_round: 7,
    attack_bonus_per_completed_enemy_round: 1,
    reset_each_battle: true,
  });
  assert.ok(balance.combat.max_rounds > balance.combat.enemy_pressure.start_round);
});

test("gacha and progression keep deterministic acquisition paths", () => {
  assert.equal(balance.gacha.ticket_cost_per_draw, 2);
  assert.equal(balance.gacha.pity.rare_guarantee_within, 10);
  assert.ok(balance.gacha.deterministic_cards.length >= 1);
  assert.equal(balance.upgrades.sequence_advance.from_sequence, 9);
  assert.equal(balance.upgrades.sequence_advance.to_sequence, 8);
  assert.equal(
    balance.upgrades.sequence_advance.ritual_failure_does_not_consume_materials,
    true,
  );
});
