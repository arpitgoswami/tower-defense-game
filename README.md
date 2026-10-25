<img width="1917" height="1078" alt="Screenshot 2026-10-25 151338" src="https://github.com/user-attachments/assets/22fdfada-4502-468a-bf87-7720d148849b" />
<img width="1917" height="1078" alt="Screenshot 2026-10-25 151402" src="https://github.com/user-attachments/assets/8258303a-6d4a-4535-b40d-0fba590f5d14" />

# 🧙 Tower Defense

An auto-battler tower defence game made with **Godot 4.2+** and typed **GDScript**.

You never aim or shoot. A wizard on a central stone tower auto-targets the nearest zombie and hurls bolts at it. Your only job is to spend coins on upgrades and survive as many waves as you can.

## Features

- Fully automatic combat with nearest-zombie targeting and a visible range circle
- Four upgrade stats with an exponential cost curve and a live `current → next` preview on every button
- Waves with rising difficulty, a "Wave N" banner, and a boss every 10 waves
- Four zombie types (normal, fast, tank, boss), each with a 4-frame walk cycle and an attack animation
- Coins pop out of zombies and fly to the tower to be collected
- Hit flash shader, death particles and floating damage numbers (crits are bigger and gold)
- Pause, 1x / 2x / 3x speed and mute
- Best score and settings saved with `ConfigFile`
- 100% procedurally generated art and audio, so there are no third-party assets

## Getting started

1. Install **Godot 4.2 or newer** (the standard build; .NET is not needed).
2. Clone or download this repository.
3. Open Godot, choose **Import**, and select `project.godot`. Wait for the first asset import to finish.
4. Press **F5**.

The project uses the **Compatibility** renderer, a 1920×1080 window and `canvas_items` stretch. The battlefield is a 960×540 world shown through a 2× `Camera2D`, so the pixel art stays crisp. The HUD and menus are laid out natively at 1080p.

## Controls

| Input | Action |
|---|---|
| Click the upgrade buttons (bottom bar) | Buy Health / Damage / Strength / Durability |
| `Space`, `Esc`, `P` or the pause button | Pause (upgrades still work while paused) |
| `1` `2` `3` or the 1x / 2x / 3x buttons | Game speed |
| `M` or the MUTE button | Mute / unmute |

The cost on an upgrade button turns **red** when you can't afford it.

## Upgrades

Cost of the next level is `base × 1.27^level`.

| Stat | Effect per level | Base cost |
|---|---|---|
| **Health** | +25 max HP, +0.45 HP/s regeneration (also heals the HP gained) | 18 |
| **Damage** | +5 damage per spell | 14 |
| **Strength** | +12 knockback, +3% crit chance (cap 70%, crits deal ×2), +6% damage multiplier | 22 |
| **Durability** | Reduces damage taken (×0.93 per level), capped at 70% | 22 |

## Enemies

Base stats before wave scaling (`scripts/zombie.gd`, `TYPE_DATA`):

| Type | HP | Speed | Damage / hit | Coins | Notes |
|---|---|---|---|---|---|
| Normal | 22 | 38 | 6 | 3 | Appears from wave 1 |
| Fast | 13 | 78 | 4 | 3 | From wave 3, attacks quickly |
| Tank | 95 | 24 | 14 | 7 | From wave 5, half knockback |
| Boss | 420 | 20 | 32 | 60 | Every 10th wave, very high knockback resistance |

Each wave adds roughly 9.5% HP (compounding), 5% damage, 1.2% speed (capped) and 10% coin value, and clearing a wave gives a bonus payout.

## Balance and tuning

Most tuning values are `@export` variables or constants at the top of a script:

| File | What to tweak |
|---|---|
| `scripts/game_state.gd` | Upgrade formulas, `cost_base`, `cost_growth`, `max_damage_reduction`, `max_crit_chance`, `starting_coins` |
| `scripts/wave_spawner.gd` | `base_count`, `count_per_wave`, `boss_every`, spawn timing, `hp_growth`, `damage_growth`, `speed_growth`, `coin_growth`, `clear_bonus_*` |
| `scripts/zombie.gd` | `TYPE_DATA` table for per-type stats |
| `scripts/wizard.gd` | `attack_range`, `shots_per_second`, `bolt_speed` |
| `scripts/coin.gd` | `collect_delay`, `fly_accel` |
| `scripts/game.gd` | `tree_count`, `tree_ring_radius` |

Measured with the included headless bot, a run with **no** upgrades ends around wave 7, while a bot that buys upgrades sensibly reaches roughly wave 15–18. Waves 1–5 are comfortable even without upgrades.

## Project structure

```
project.godot
scenes/    MainMenu, Game, HUD, GameOver, Wizard, Zombie, Bolt, Impact,
           Coin, DamageNumber, DeathParticles, UpgradeButton  (.tscn)
scripts/   game_state.gd (autoload)   audio_manager.gd (autoload)
           wizard.gd  zombie.gd  bolt.gd  wave_spawner.gd  coin.gd
           game.gd  hud.gd  upgrade_button.gd  main_menu.gd  game_over.gd ...
assets/    sprites/  (PNG)   frames/ (SpriteFrames .tres)
           audio/    (WAV)   shaders/ (hit flash)   ui_theme.tres
tools/     generate_sprites.py   generate_audio.py
tests/     bot.gd  flow.gd  run.sh
```

## Regenerating assets

All sprites and sounds come from scripts, so you can edit and rebuild them:

```bash
pip install pillow
python3 tools/generate_sprites.py   # PNGs in assets/sprites, SpriteFrames in assets/frames
python3 tools/generate_audio.py     # WAVs in assets/audio
```

## Headless tests (optional)

```bash
# Smoke test: menu → play → upgrades → game over → retry → menu
godot --headless --fixed-fps 60 --path . -s tests/flow.gd

# Balance bot: strategy is none | balanced | dmg, followed by max simulated seconds
tests/run.sh balanced 1800
```

Set the `GODOT` environment variable if your Godot binary is not on the default path used by `tests/run.sh`.

## Save data

Best score, volume and mute are stored in `user://savegame.cfg`, which Godot places in your per-user app data folder.

## Credits

- All art and audio are generated by the scripts in `tools/` (Python with Pillow, and the Python standard library for the WAV synthesis). No third-party assets are used.
- Font: Godot's built-in default font.
- Engine: [Godot Engine](https://godotengine.org) (MIT licence).

## Licence

No licence has been chosen yet. Add a `LICENSE` file (for example MIT) before publishing if you want others to be able to reuse the code.
