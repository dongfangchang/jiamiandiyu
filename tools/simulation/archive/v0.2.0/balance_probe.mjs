#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(scriptDirectory, "..", "..");
const balancePath = path.join(projectRoot, "data", "balance", "v0.2.0", "balance_draft.json");
const outputDirectory = path.join(scriptDirectory, "out");
export const balance = JSON.parse(fs.readFileSync(balancePath, "utf8"));

function mulberry32(seed) {
  let state = seed >>> 0;
  return function random() {
    state += 0x6d2b79f5;
    let value = state;
    value = Math.imul(value ^ (value >>> 15), value | 1);
    value ^= value + Math.imul(value ^ (value >>> 7), value | 61);
    return ((value ^ (value >>> 14)) >>> 0) / 4294967296;
  };
}

function randomInteger(random, min, max) {
  return Math.floor(random() * (max - min + 1)) + min;
}

function pickRandom(random, values) {
  return values[Math.floor(random() * values.length)];
}

function round(value, places = 4) {
  const factor = 10 ** places;
  return Math.round(value * factor) / factor;
}

function weightedRarity(random, weights) {
  const roll = random();
  let cursor = 0;
  for (const rarity of ["common", "uncommon", "rare"]) {
    cursor += weights[rarity];
    if (roll < cursor) {
      return rarity;
    }
  }
  return "rare";
}

export function simulateDrawSequence(seed) {
  const random = mulberry32(seed);
  const randomCards = balance.cards.filter((card) => card.acquisition === "random");
  const cardsByRarity = new Map();
  for (const rarity of ["common", "uncommon", "rare"]) {
    cardsByRarity.set(
      rarity,
      randomCards.filter((card) => card.rarity === rarity),
    );
  }

  const owned = new Set(balance.gacha.starter_cards);
  const rarityCounts = { common: 0, uncommon: 0, rare: 0 };
  const milestones = [];
  let duplicateDust = 0;
  let pityCounter = 0;

  for (let draw = 0; draw < balance.simulation.draw_sequence_length; draw += 1) {
    let rarity;
    if (pityCounter >= balance.gacha.pity.rare_guarantee_within - 1) {
      rarity = "rare";
    } else {
      rarity = weightedRarity(random, balance.gacha.rarity_weights);
    }

    rarityCounts[rarity] += 1;
    pityCounter = rarity === "rare" ? 0 : pityCounter + 1;

    const card = pickRandom(random, cardsByRarity.get(rarity));
    if (owned.has(card.id)) {
      duplicateDust += balance.gacha.duplicate_dust[rarity];
    } else {
      owned.add(card.id);
    }

    const completedDraws = draw + 1;
    if ([6, 11, 20].includes(completedDraws)) {
      milestones.push({
        draws: completedDraws,
        uniqueCardsOwned: owned.size,
        rareCardsDrawn: rarityCounts.rare,
        duplicateDust,
      });
    }
  }

  return {
    rarityCounts,
    duplicateDust,
    uniqueCardsOwned: owned.size,
    milestones,
  };
}

export function simulateDraws() {
  const samples = [];
  for (let index = 0; index < balance.simulation.sample_draw_sequences; index += 1) {
    samples.push(simulateDrawSequence(balance.simulation.fixed_seed + index));
  }

  const average = (selector) =>
    samples.reduce((total, sample) => total + selector(sample), 0) / samples.length;
  const milestoneDraws = [6, 11, 20];
  const milestoneAverages = milestoneDraws.map((draws) => {
    const relevant = samples.map(
      (sample) => sample.milestones.find((milestone) => milestone.draws === draws),
    );
    return {
      draws,
      average_unique_cards_owned: round(
        relevant.reduce((total, milestone) => total + milestone.uniqueCardsOwned, 0) /
          relevant.length,
      ),
      average_rare_cards_drawn: round(
        relevant.reduce((total, milestone) => total + milestone.rareCardsDrawn, 0) /
          relevant.length,
      ),
      average_duplicate_dust: round(
        relevant.reduce((total, milestone) => total + milestone.duplicateDust, 0) /
          relevant.length,
      ),
    };
  });

  return {
    sequences: samples.length,
    draws_per_sequence: balance.simulation.draw_sequence_length,
    milestone_averages: milestoneAverages,
    average_rare_per_sequence: round(average((sample) => sample.rarityCounts.rare)),
    average_uncommon_per_sequence: round(average((sample) => sample.rarityCounts.uncommon)),
    average_duplicate_dust_per_sequence: round(average((sample) => sample.duplicateDust)),
    average_unique_cards_owned_after_sequence: round(
      average((sample) => sample.uniqueCardsOwned),
    ),
  };
}

function rewardForTier(tier) {
  return balance.rewards[tier] ?? {
    echo_dust: 0,
    divination_tickets: 0,
    characteristic_fragments: 0,
  };
}

export function simulateEconomy() {
  const normalReward = rewardForTier("normal");
  const eliteReward = rewardForTier("elite");
  const bossReward = rewardForTier("boss");
  const firstClear = balance.rewards.first_clear_bonus;
  const dayOptions = balance.rewards.day_reward_options;
  const maxDayTickets = Math.max(...dayOptions.map((option) => option.divination_tickets));
  const maxDayDust = Math.max(...dayOptions.map((option) => option.echo_dust));

  const perRun = {
    echo_dust:
      normalReward.echo_dust * balance.run_structure.normal_encounters +
      eliteReward.echo_dust +
      bossReward.echo_dust +
      maxDayDust * balance.run_structure.day_choices,
    divination_tickets:
      normalReward.divination_tickets * balance.run_structure.normal_encounters +
      eliteReward.divination_tickets +
      bossReward.divination_tickets +
      maxDayTickets * balance.run_structure.day_choices,
    characteristic_fragments:
      normalReward.characteristic_fragments * balance.run_structure.normal_encounters +
      eliteReward.characteristic_fragments +
      bossReward.characteristic_fragments,
  };

  const cumulative = [];
  let total = { echo_dust: 0, divination_tickets: 0, characteristic_fragments: 0 };
  for (let run = 1; run <= 3; run += 1) {
    total = {
      echo_dust: total.echo_dust + perRun.echo_dust,
      divination_tickets: total.divination_tickets + perRun.divination_tickets,
      characteristic_fragments:
        total.characteristic_fragments + perRun.characteristic_fragments,
    };
    if (run === 1) {
      total.echo_dust += firstClear.echo_dust;
      total.divination_tickets += firstClear.divination_tickets;
      total.characteristic_fragments += firstClear.characteristic_fragments;
    }
    cumulative.push({
      run,
      ...total,
      available_draws: Math.floor(total.divination_tickets / balance.gacha.ticket_cost_per_draw),
    });
  }

  const promotion = balance.upgrades.sequence_advance;
  const promotionReadyAfterFirstRun =
    cumulative[0].characteristic_fragments >= promotion.characteristic_fragments &&
    cumulative[0].echo_dust >= promotion.echo_dust;
  const promotionReadyAfterSecondRun =
    cumulative[1].characteristic_fragments >= promotion.characteristic_fragments &&
    cumulative[1].echo_dust >= promotion.echo_dust;

  return {
    maximum_draw_focused_reward_per_run: perRun,
    cumulative_including_first_clear: cumulative,
    promotion_cost: {
      characteristic_fragments: promotion.characteristic_fragments,
      echo_dust: promotion.echo_dust,
    },
    promotion_ready_after_first_run: promotionReadyAfterFirstRun,
    promotion_ready_after_second_run: promotionReadyAfterSecondRun,
  };
}

export function simulateBattle(profile, seed) {
  const random = mulberry32(seed);
  let health = balance.player.starting_health;
  let corruption = 0;
  let attention = 0;
  let pressureStacks = 0;
  let maxPressureBonusObserved = 0;
  let failedByRoundLimit = false;

  const normalEnemies = balance.encounters.filter((enemy) => enemy.tier === "normal");
  const eliteEnemies = balance.encounters.filter((enemy) => enemy.tier === "elite");
  const boss = balance.encounters.find((enemy) => enemy.tier === "boss");
  const route = [
    ...normalEnemies.slice(0, balance.run_structure.normal_encounters),
    { tier: "rest" },
    pickRandom(random, eliteEnemies),
    boss,
  ];

  let rounds = 0;
  for (const encounter of route) {
    if (health <= 0) {
      break;
    }

    if (encounter.tier === "rest") {
      health = Math.min(balance.player.max_health, health + profile.rest_heal);
      continue;
    }

    let enemyHealth = encounter.health;
    let encounterRound = 0;
    let pressureBonus = 0;
    while (enemyHealth > 0 && health > 0) {
      rounds += 1;
      encounterRound += 1;
      const variance = 1 + (random() * 2 - 1) * balance.combat.random_damage_variance;
      const playerDamage = Math.max(1, profile.potency_per_round * variance);
      enemyHealth -= playerDamage;

      if (enemyHealth <= 0) {
        break;
      }

      const attack = randomInteger(
        random,
        encounter.attack_per_round.min,
        encounter.attack_per_round.max,
      );
      const damageTaken = Math.max(
        1,
        attack + pressureBonus - profile.guard_per_round,
      );
      health -= damageTaken;

      if (corruption >= balance.player.corruption.penalty_at) {
        health -= balance.player.corruption.penalty_damage_per_round;
      }

      maxPressureBonusObserved = Math.max(
        maxPressureBonusObserved,
        pressureBonus,
      );

      if (
        health > 0 &&
        enemyHealth > 0 &&
        encounterRound >= balance.combat.enemy_pressure.start_round
      ) {
        pressureBonus +=
          balance.combat.enemy_pressure.attack_bonus_per_completed_enemy_round;
        pressureStacks += 1;
      }

      if (health > 0 && encounterRound >= balance.combat.max_rounds) {
        health = 0;
        failedByRoundLimit = true;
        break;
      }
    }

    if (encounter.tier === "normal") {
      if (encounter.threat.includes("corruption")) {
        corruption = Math.min(balance.player.corruption.max, corruption + 1);
      }
      if (encounter.threat.includes("attention")) {
        attention = Math.min(balance.player.attention.max, attention + 1);
      }
    }
  }

  const won = health > 0;
  attention = Math.max(
    balance.player.attention.min,
    attention - balance.player.attention.default_run_end_decay,
  );
  return {
    won,
    remaining_health: Math.max(0, health),
    rounds,
    corruption,
    attention,
    pressure_stacks: pressureStacks,
    max_pressure_bonus: maxPressureBonusObserved,
    failed_by_round_limit: failedByRoundLimit,
  };
}

export function simulateBattles() {
  const output = [];
  for (const [profileIndex, profile] of balance.simulation.profiles.entries()) {
    const samples = [];
    for (let index = 0; index < balance.simulation.sample_runs; index += 1) {
      samples.push(
        simulateBattle(
          profile,
          balance.simulation.fixed_seed + 100000 * (profileIndex + 1) + index,
        ),
      );
    }

    const winCount = samples.filter((sample) => sample.won).length;
    const wonSamples = samples.filter((sample) => sample.won);
    output.push({
      profile: profile.id,
      assumptions: {
        potency_per_round: profile.potency_per_round,
        guard_per_round: profile.guard_per_round,
        rest_heal: profile.rest_heal,
      },
      win_rate: round(winCount / samples.length),
      average_remaining_health_on_win:
        wonSamples.length === 0
          ? 0
          : round(
              wonSamples.reduce((total, sample) => total + sample.remaining_health, 0) /
                wonSamples.length,
            ),
      average_total_rounds: round(
        samples.reduce((total, sample) => total + sample.rounds, 0) / samples.length,
      ),
      average_pressure_stacks: round(
        samples.reduce((total, sample) => total + sample.pressure_stacks, 0) /
          samples.length,
      ),
      max_pressure_bonus_observed: Math.max(
        ...samples.map((sample) => sample.max_pressure_bonus),
      ),
      round_limit_failures: samples.filter(
        (sample) => sample.failed_by_round_limit,
      ).length,
    });
  }
  return output;
}

export function buildSimulationResult() {
  return {
    source: "data/balance/v0.2.0/balance_draft.json",
    seed: balance.simulation.fixed_seed,
    enemy_pressure_rule: balance.combat.enemy_pressure,
    assumptions: [
      "Battle profiles are aggregate resource budgets, not a claim about final card timing.",
      "The economy assumes draw-focused daytime choices.",
      "The unique boss card is excluded from the random pool.",
      "Enemy pressure resets per encounter; round 7 receives the base attack and gains +1 after its completed enemy action.",
    ],
    draw_simulation: simulateDraws(),
    economy: simulateEconomy(),
    battle_simulation: simulateBattles(),
  };
}

export function writeSimulationOutput(result) {
  fs.mkdirSync(outputDirectory, { recursive: true });
  const summaryPath = path.join(outputDirectory, "v0.2.0_summary.json");
  const csvPath = path.join(outputDirectory, "v0.2.0_battle_profiles.csv");
  fs.writeFileSync(summaryPath, `${JSON.stringify(result, null, 2)}\n`, "utf8");

  const csvRows = [
    "profile,win_rate,average_remaining_health_on_win,average_total_rounds,average_pressure_stacks,max_pressure_bonus_observed,round_limit_failures",
    ...result.battle_simulation.map(
      (item) =>
        `${item.profile},${item.win_rate},${item.average_remaining_health_on_win},${item.average_total_rounds},${item.average_pressure_stacks},${item.max_pressure_bonus_observed},${item.round_limit_failures}`,
    ),
  ];
  fs.writeFileSync(csvPath, `${csvRows.join("\n")}\n`, "utf8");
  return { summaryPath, csvPath };
}

function runCli() {
  const result = buildSimulationResult();
  const { summaryPath, csvPath } = writeSimulationOutput(result);
  console.log(JSON.stringify(result, null, 2));
  console.log(`\nWrote ${summaryPath}`);
  console.log(`Wrote ${csvPath}`);
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href
) {
  runCli();
}
