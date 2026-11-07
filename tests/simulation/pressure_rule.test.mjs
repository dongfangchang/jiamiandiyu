import assert from "node:assert/strict";
import test from "node:test";
import { balance, simulateBattle } from "../../tools/simulation/balance_probe.mjs";

test("enemy pressure starts after round seven and resets per encounter", () => {
  const slowProfile = {
    id: "profile.test.slow",
    potency_per_round: 1,
    guard_per_round: 20,
    rest_heal: 0,
  };
  const result = simulateBattle(
    slowProfile,
    balance.simulation.fixed_seed,
  );

  assert.equal(result.won, false);
  assert.ok(result.pressure_stacks > 0);
  assert.ok(result.max_pressure_bonus >= 1);
  assert.equal(result.failed_by_round_limit, true);
});

test("fast encounters finish before pressure can stack", () => {
  const fastProfile = {
    id: "profile.test.fast",
    potency_per_round: 100,
    guard_per_round: 0,
    rest_heal: 0,
  };
  const result = simulateBattle(
    fastProfile,
    balance.simulation.fixed_seed,
  );

  assert.equal(result.won, true);
  assert.equal(result.pressure_stacks, 0);
  assert.equal(result.max_pressure_bonus, 0);
});
