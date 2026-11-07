import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const testDirectory = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(testDirectory, "..", "..");
const simulationScript = path.join(
  projectRoot,
  "tools",
  "simulation",
  "balance_probe.mjs",
);
const summaryPath = path.join(
  projectRoot,
  "tools",
  "simulation",
  "out",
  "v0.2.0_summary.json",
);

function hashFile(filePath) {
  return crypto
    .createHash("sha256")
    .update(fs.readFileSync(filePath))
    .digest("hex")
    .toUpperCase();
}

test("fixed-seed simulation is reproducible and includes enemy pressure", () => {
  execFileSync(process.execPath, [simulationScript], {
    cwd: projectRoot,
    stdio: "pipe",
  });
  const firstHash = hashFile(summaryPath);

  execFileSync(process.execPath, [simulationScript], {
    cwd: projectRoot,
    stdio: "pipe",
  });
  const secondHash = hashFile(summaryPath);

  assert.equal(secondHash, firstHash);

  const summary = JSON.parse(fs.readFileSync(summaryPath, "utf8"));
  assert.deepEqual(summary.enemy_pressure_rule, {
    start_round: 7,
    attack_bonus_per_completed_enemy_round: 1,
    reset_each_battle: true,
  });
  assert.equal(summary.battle_simulation.length, 3);
  for (const profile of summary.battle_simulation) {
    assert.ok(Object.hasOwn(profile, "average_pressure_stacks"));
    assert.ok(Object.hasOwn(profile, "max_pressure_bonus_observed"));
  }
});
