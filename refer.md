<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>KOizi — SEVEN SUMMITS (3D)</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
    <link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&family=JetBrains+Mono:wght@600;800&display=swap" rel="stylesheet">
    <style>
        * {
            box-sizing: border-box;
            user-select: none;
            -webkit-user-select: none;
            touch-action: manipulation;
        }

        body {
            margin: 0;
            padding: 0;
            background-color: #07090f;
            color: #f8fafc;
            font-family: 'JetBrains Mono', monospace;
            overflow: hidden;
            width: 100vw;
            height: 100vh;
            display: flex;
            flex-direction: column;
        }

        .pixel-font {
            font-family: 'Press Start 2P', monospace;
            line-height: 1.45;
        }

        #game-container {
            position: relative;
            width: 100%;
            height: 100%;
            background: #090d16;
            overflow: hidden;
        }

        canvas {
            display: block;
            width: 100%;
            height: 100%;
        }

        /* Crisp Arcade Glass/Voxel UI Panel */
        .voxel-box {
            background: rgba(11, 16, 28, 0.88);
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
            border: 3px solid #cbd5e1;
            box-shadow:
                inset -3px -3px 0px rgba(0, 0, 0, 0.55),
                inset 3px 3px 0px rgba(255, 255, 255, 0.14),
                0 14px 36px rgba(0, 0, 0, 0.78);
        }

        .voxel-btn {
            background: #2563eb;
            border: 3px solid #93c5fd;
            box-shadow: inset -3px -3px 0px #1e3a8a, inset 3px 3px 0px #60a5fa;
            color: #ffffff;
            transition: transform 0.08s ease, filter 0.1s ease;
            cursor: pointer;
        }

        .voxel-btn:hover:not(:disabled) {
            filter: brightness(1.15);
            transform: translateY(-2px);
        }

        .voxel-btn:active:not(:disabled) {
            transform: translateY(1px);
            box-shadow: inset 2px 2px 0px #1e3a8a;
        }

        .voxel-btn:disabled {
            opacity: 0.45;
            cursor: not-allowed;
        }

        .voxel-btn-emerald {
            background: #059669;
            border-color: #6ee7b7;
            box-shadow: inset -3px -3px 0px #064e3b, inset 3px 3px 0px #34d399;
        }

        .voxel-btn-amber {
            background: #d97706;
            border-color: #fcd34d;
            box-shadow: inset -3px -3px 0px #78350f, inset 3px 3px 0px #fbbf24;
        }

        .voxel-btn-slate {
            background: #334155;
            border-color: #94a3b8;
            box-shadow: inset -3px -3px 0px #0f172a, inset 3px 3px 0px #64748b;
        }

        .voxel-btn-rose {
            background: #e11d48;
            border-color: #fda4af;
            box-shadow: inset -3px -3px 0px #881337, inset 3px 3px 0px #fb7185;
        }

        /* Mobile Touch Controls */
        .touch-pad {
            background: rgba(15, 23, 42, 0.72);
            border: 2px solid rgba(203, 213, 225, 0.48);
            backdrop-filter: blur(6px);
        }

        .touch-pad:active, .touch-pad.pressed {
            background: rgba(56, 189, 248, 0.48);
            border-color: #38bdf8;
            transform: scale(0.94);
        }
    </style>
</head>
<body>

<div id="game-container">
    <!-- Three.js 3D WebGL Renderer mounts here -->
    <div id="three-mount" class="w-full h-full"></div>

    <!-- IN-GAME HUD -->
    <div id="hud" class="absolute top-0 left-0 right-0 p-3 sm:p-4 flex items-start justify-between pointer-events-none z-10 hidden">
        <!-- Top-Left: KOizi Brand, Health Hearts & Current Summit -->
        <div class="flex flex-col gap-2 pointer-events-auto">
            <div class="voxel-box px-3 py-2 rounded-lg flex items-center gap-3">
                <span class="pixel-font text-xs sm:text-sm text-sky-400">KOizi</span>
                <div class="w-0.5 h-4 bg-slate-600"></div>
                <div class="flex items-center gap-1.5">
                    <span class="pixel-font text-[9px] text-rose-400">HP</span>
                    <div id="hud-hearts" class="flex items-center gap-1"></div>
                </div>
            </div>
            <div class="voxel-box px-3 py-1.5 rounded-lg inline-block">
                <div id="hud-level-title" class="pixel-font text-[9px] sm:text-[11px] text-amber-300">LVL 1: GREEN HIGHLANDS</div>
            </div>
        </div>

        <!-- Top-Center: Boss Health Bar (Visible on Level 7) -->
        <div id="boss-hud" class="hidden flex-col items-center w-64 sm:w-96 mx-2">
            <div class="voxel-box w-full px-3 py-2 rounded-lg border-rose-400">
                <div class="flex justify-between items-center mb-1.5">
                    <span class="pixel-font text-[9px] sm:text-[10px] text-rose-300">SUMMIT OVERLORD</span>
                    <span id="boss-hp-text" class="pixel-font text-[9px] text-amber-300">65/65</span>
                </div>
                <div class="w-full h-3.5 bg-slate-900 border-2 border-slate-500 p-0.5">
                    <div id="boss-hp-fill" class="h-full bg-gradient-to-r from-rose-600 via-red-500 to-amber-400 transition-all duration-150" style="width: 100%"></div>
                </div>
            </div>
        </div>

        <!-- Top-Right: Enemies Counter, Camera Tilt, Sound & Pause -->
        <div class="flex items-center gap-2 pointer-events-auto">
            <div id="hud-enemy-box" class="voxel-box px-3 py-2 rounded-lg flex items-center gap-2">
                <span id="hud-enemies" class="pixel-font text-[10px] sm:text-xs text-cyan-300">FOES: 0/0</span>
            </div>
            <button id="btn-hud-cam" class="voxel-btn-slate px-2.5 py-2 rounded-lg text-xs font-bold hidden sm:inline-block" title="Toggle 3D Camera Angle (C)">
                🎥 3D
            </button>
            <button id="btn-hud-sound" class="voxel-btn-slate px-2.5 py-2 rounded-lg text-xs font-bold" title="Toggle Audio">
                🔊
            </button>
            <button id="btn-hud-pause" class="voxel-btn-amber px-3 py-2 rounded-lg pixel-font text-[10px]" title="Pause (Esc)">
                II
            </button>
        </div>
    </div>

    <!-- Banner Toast (e.g., Summit Portal Unlocked) -->
    <div id="toast-banner" class="absolute top-20 left-1/2 -translate-x-1/2 pointer-events-none z-20 transition-all duration-300 opacity-0 scale-95">
        <div class="voxel-box px-5 py-2.5 rounded-lg border-emerald-400 bg-slate-950/95 text-center">
            <span id="toast-text" class="pixel-font text-xs sm:text-sm text-emerald-300">SUMMIT PORTAL UNLOCKED!</span>
        </div>
    </div>

    <!-- MAIN MENU OVERLAY -->
    <div id="menu-main" class="absolute inset-0 z-30 flex items-center justify-center p-4 bg-slate-950/55 backdrop-blur-[2px]">
        <div class="voxel-box max-w-xl w-full rounded-xl p-6 sm:p-8 text-center">
            <div class="inline-block px-3 py-1 mb-3 bg-sky-950 border-2 border-sky-400 rounded text-sky-300 pixel-font text-[10px]">
                3D ACTION MOUNTAIN SHOOTER
            </div>
            <h1 class="pixel-font text-3xl sm:text-5xl text-white mb-2 drop-shadow-[0_4px_0_#1e3a8a]">
                KOizi
            </h1>
            <h2 class="pixel-font text-xs sm:text-base text-amber-400 mb-6 tracking-widest">
                — SEVEN SUMMITS —
            </h2>

            <p class="text-slate-200 text-xs sm:text-sm mb-6 leading-relaxed">
                Scale seven 3D mountain peaks, blast ridge guardians to ignite each <span class="text-emerald-300 font-bold">3D Summit Portal</span>, and defeat the <span class="text-rose-400 font-bold">Summit Overlord</span> on Peak 7!
            </p>

            <!-- Primary Actions -->
            <div class="flex flex-col sm:flex-row gap-3 justify-center mb-6">
                <button id="btn-play" class="voxel-btn voxel-btn-emerald px-6 py-3.5 rounded-lg pixel-font text-xs sm:text-sm flex-1">
                    ▶️ PLAY KOizi
                </button>
                <button id="btn-level-select" class="voxel-btn px-6 py-3.5 rounded-lg pixel-font text-xs sm:text-sm flex-1">
                    ⛰ SEVEN SUMMITS
                </button>
            </div>

            <!-- Controls Keybind Box -->
            <div class="bg-slate-900/90 border-2 border-slate-700 rounded-lg p-3.5 text-left grid grid-cols-2 sm:grid-cols-4 gap-2.5 text-xs">
                <div>
                    <div class="text-slate-400 font-bold text-[10px]">MOVE</div>
                    <div class="text-white font-bold">A / D or ◀️ ▶️</div>
                </div>
                <div>
                    <div class="text-slate-400 font-bold text-[10px]">JUMP</div>
                    <div class="text-cyan-300 font-bold">SPACE / W</div>
                </div>
                <div>
                    <div class="text-slate-400 font-bold text-[10px]">SHOOT</div>
                    <div class="text-amber-300 font-bold">J / CLICK</div>
                </div>
                <div>
                    <div class="text-slate-400 font-bold text-[10px]">PAUSE / CAM</div>
                    <div class="text-rose-300 font-bold">ESC / C</div>
                </div>
            </div>
        </div>
    </div>

    <!-- LEVEL SELECTION SCREEN -->
    <div id="menu-levels" class="absolute inset-0 z-30 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm hidden">
        <div class="voxel-box max-w-3xl w-full rounded-xl p-5 sm:p-7 max-h-[92vh] overflow-y-auto">
            <div class="flex flex-wrap items-center justify-between gap-2 mb-5">
                <div>
                    <div class="pixel-font text-[10px] text-sky-400 mb-1">KOizi EXPEDITION MAP</div>
                    <h2 class="pixel-font text-base sm:text-xl text-amber-300">SELECT MOUNTAIN SUMMIT</h2>
                </div>
                <button id="btn-unlock-all" class="voxel-btn-amber px-3 py-2 rounded text-[10px] font-bold">
                    🔓 UNLOCK ALL (DEV)
                </button>
            </div>

            <div id="levels-grid" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 mb-6">
                <!-- Populated dynamically via JS -->
            </div>

            <div class="flex justify-end">
                <button id="btn-levels-back" class="voxel-btn-slate px-5 py-2.5 rounded-lg pixel-font text-xs">
                    ◀️ BACK TO MENU
                </button>
            </div>
        </div>
    </div>

    <!-- PAUSE MENU -->
    <div id="menu-pause" class="absolute inset-0 z-30 flex items-center justify-center p-4 bg-slate-950/75 backdrop-blur-sm hidden">
        <div class="voxel-box max-w-sm w-full rounded-xl p-6 text-center">
            <div class="pixel-font text-[10px] text-sky-400 mb-1">KOizi</div>
            <h2 class="pixel-font text-xl text-amber-300 mb-2">PAUSED</h2>
            <p id="pause-level-name" class="text-xs text-slate-300 mb-6">Level 1 — Green Highlands</p>

            <div class="flex flex-col gap-3">
                <button id="btn-resume" class="voxel-btn voxel-btn-emerald py-3 rounded-lg pixel-font text-xs">
                    ▶️ RESUME
                </button>
                <button id="btn-pause-restart" class="voxel-btn voxel-btn-amber py-3 rounded-lg pixel-font text-xs">
                    ↻ RESTART SUMMIT
                </button>
                <button id="btn-pause-levels" class="voxel-btn py-3 rounded-lg pixel-font text-xs">
                    ⛰ LEVEL SELECT
                </button>
                <button id="btn-pause-home" class="voxel-btn-slate py-3 rounded-lg pixel-font text-xs">
                    🏠 MAIN MENU
                </button>
            </div>
        </div>
    </div>

    <!-- GAME OVER SCREEN -->
    <div id="menu-gameover" class="absolute inset-0 z-30 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm hidden">
        <div class="voxel-box max-w-md w-full rounded-xl p-6 sm:p-8 text-center border-rose-400">
            <div class="pixel-font text-[10px] text-slate-400 mb-1">KOizi — SEVEN SUMMITS</div>
            <h2 class="pixel-font text-2xl text-rose-400 mb-3">FALLEN ON THE RIDGE</h2>
            <p id="gameover-reason" class="text-slate-300 text-xs sm:text-sm mb-6">
                Your climber ran out of health before reaching the summit.
            </p>
            <div class="flex flex-col gap-3">
                <button id="btn-retry" class="voxel-btn voxel-btn-rose py-3.5 rounded-lg pixel-font text-xs">
                    ↻ RETRY SUMMIT
                </button>
                <button id="btn-gameover-levels" class="voxel-btn py-3 rounded-lg pixel-font text-xs">
                    ⛰ LEVEL SELECT
                </button>
                <button id="btn-gameover-home" class="voxel-btn-slate py-3 rounded-lg pixel-font text-xs">
                    🏠 MAIN MENU
                </button>
            </div>
        </div>
    </div>

    <!-- LEVEL COMPLETED SCREEN -->
    <div id="menu-complete" class="absolute inset-0 z-30 flex items-center justify-center p-4 bg-slate-950/75 backdrop-blur-sm hidden">
        <div class="voxel-box max-w-md w-full rounded-xl p-6 sm:p-8 text-center border-emerald-400">
            <div class="inline-block px-3 py-1 mb-2 bg-emerald-950 border border-emerald-400 text-emerald-300 pixel-font text-[10px]">
                KOizi // SUMMIT REACHED!
            </div>
            <h2 id="complete-title" class="pixel-font text-lg sm:text-xl text-white mb-4">GREEN HIGHLANDS CLEARED</h2>

            <div class="bg-slate-900 border-2 border-slate-700 rounded-lg p-4 mb-6 flex justify-around text-xs">
                <div>
                    <div class="text-slate-400">FOES DEFEATED</div>
                    <div id="complete-kills" class="pixel-font text-sm text-cyan-300 mt-1">0 / 0</div>
                </div>
                <div>
                    <div class="text-slate-400">CLEAR TIME</div>
                    <div id="complete-time" class="pixel-font text-sm text-amber-300 mt-1">00.0s</div>
                </div>
            </div>

            <div class="flex flex-col gap-3">
                <button id="btn-next-level" class="voxel-btn voxel-btn-emerald py-3.5 rounded-lg pixel-font text-xs">
                    NEXT SUMMIT ▶️
                </button>
                <button id="btn-complete-levels" class="voxel-btn-slate py-3 rounded-lg pixel-font text-xs">
                    ⛰ LEVEL SELECT
                </button>
            </div>
        </div>
    </div>

    <!-- FINAL VICTORY SCREEN (AFTER LEVEL 7 BOSS) -->
    <div id="menu-victory" class="absolute inset-0 z-30 flex items-center justify-center p-4 bg-slate-950/75 backdrop-blur-sm hidden">
        <div class="voxel-box max-w-lg w-full rounded-xl p-6 sm:p-8 text-center border-amber-400">
            <div class="pixel-font text-xs text-amber-300 mb-2">★ ALL SEVEN SUMMITS CONQUERED ★</div>
            <h2 class="pixel-font text-2xl sm:text-3xl text-white mb-4 drop-shadow-[0_3px_0_#b45309]">
                KOizi CONQUERED!
            </h2>
            <p class="text-slate-200 text-xs sm:text-sm mb-6 leading-relaxed">
                You defeated the <span class="text-rose-400 font-bold">Summit Overlord</span> atop the Seventh Peak and mastered every mountain realm in <span class="text-sky-300 font-bold">KOizi</span>!
            </p>
            <div class="bg-slate-900 border-2 border-amber-500/50 rounded-lg p-4 mb-6">
                <div class="text-xs text-slate-400">TOTAL GUARDIANS VANQUISHED</div>
                <div id="victory-total-kills" class="pixel-font text-lg text-amber-300 mt-1">0</div>
            </div>
            <div class="flex flex-col sm:flex-row gap-3">
                <button id="btn-victory-replay" class="voxel-btn voxel-btn-emerald py-3.5 px-5 rounded-lg pixel-font text-xs flex-1">
                    ↻ PLAY AGAIN
                </button>
                <button id="btn-victory-home" class="voxel-btn-slate py-3.5 px-5 rounded-lg pixel-font text-xs flex-1">
                    🏠 MAIN MENU
                </button>
            </div>
        </div>
    </div>

    <!-- MOBILE / TOUCH CONTROLS -->
    <div id="touch-ui" class="absolute bottom-4 left-4 right-4 z-20 flex items-end justify-between pointer-events-none md:hidden hidden">
        <div class="flex gap-3 pointer-events-auto">
            <button id="t-left" class="touch-pad w-16 h-16 rounded-xl flex items-center justify-center text-white pixel-font text-base">◀️</button>
            <button id="t-right" class="touch-pad w-16 h-16 rounded-xl flex items-center justify-center text-white pixel-font text-base">▶️</button>
        </div>
        <div class="flex gap-3 pointer-events-auto">
            <button id="t-shoot" class="touch-pad w-16 h-16 rounded-xl flex items-center justify-center text-amber-300 pixel-font text-[10px]">FIRE</button>
            <button id="t-jump" class="touch-pad w-16 h-16 rounded-xl flex items-center justify-center text-cyan-300 pixel-font text-[10px]">JUMP</button>
        </div>
    </div>
</div>

<script>
/**
 * KOizi — SEVEN SUMMITS (3D Edition)
 * Complete 3D Side-Scrolling Action-Platformer Mountain Shooter built with Three.js
 * - 3D Low-Poly / Voxel Mountain Ridges, Layered Parallax Peaks, Clouds, Trees, Crystals & Lava
 * - Articulated 3D Climber Hero with animated limbs, scarf, energy rifle & muzzle flash
 * - 7 Progressive Summits culminating in the 3D Summit Overlord Boss Fight on Peak 7
 */

// ============================================================================
// 1. RETRO WEB AUDIO SYNTHESIZER (Zero External Audio Dependencies)
// ============================================================================
class RetroAudio {
    constructor() {
        this.ctx = null;
        this.muted = false;
    }

    init() {
        if (!this.ctx) {
            const AudioCtx = window.AudioContext || window.webkitAudioContext;
            this.ctx = new AudioCtx();
        }
        if (this.ctx.state === 'suspended') {
            this.ctx.resume();
        }
    }

    toggleMute() {
        this.muted = !this.muted;
        return this.muted;
    }

    tone(freqStart, freqEnd, duration, type = 'square', volume = 0.12, delay = 0) {
        if (this.muted || !this.ctx) return;
        const now = this.ctx.currentTime + delay;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = type;
        osc.frequency.setValueAtTime(freqStart, now);
        osc.frequency.exponentialRampToValueAtTime(Math.max(20, freqEnd), now + duration);

        gain.gain.setValueAtTime(volume, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + duration);

        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start(now);
        osc.stop(now + duration + 0.01);
    }

    shoot() { this.tone(740, 220, 0.11, 'square', 0.1); }
    jump() { this.tone(215, 540, 0.14, 'square', 0.1); }
    enemyHit() { this.tone(270, 125, 0.09, 'sawtooth', 0.12); }
    enemyDie() {
        this.tone(330, 95, 0.18, 'square', 0.14, 0);
        this.tone(185, 55, 0.22, 'sawtooth', 0.14, 0.06);
    }
    playerHurt() {
        this.tone(195, 58, 0.28, 'sawtooth', 0.18, 0);
    }
    portalUnlock() {
        [440, 554, 659, 880].forEach((f, i) => this.tone(f, f * 1.05, 0.18, 'triangle', 0.12, i * 0.07));
    }
    bossSlam() {
        this.tone(115, 32, 0.36, 'sawtooth', 0.22, 0);
    }
    victory() {
        [523, 659, 784, 1046, 784, 1046].forEach((f, i) => this.tone(f, f, 0.22, 'square', 0.12, i * 0.11));
    }
}

const sfx = new RetroAudio();

// ============================================================================
// 2. SEVEN SUMMITS 3D LEVEL DEFINITIONS
// ============================================================================
// 3D World Coordinate System:
// +X = Right along mountain ridge, +Y = Upward altitude, Z = 0 is the main 2.5D gameplay plane.
// 1 World Unit ≈ 1 meter. Player height = 1.6 units.
const SUMMITS = [
    // ------------------------------------------------------------------------
    // LEVEL 1: GREEN HIGHLANDS
    // ------------------------------------------------------------------------
    {
        id: 1,
        name: "Green Highlands",
        subtitle: "Lush 3D grass ridges & basic scouts",
        worldWidth: 105,
        friction: 85,
        theme: {
            skyColor: 0x3b82f6,
            fogColor: 0x60a5fa,
            sunColor: 0xfffbeb,
            farMountain: 0x1e40af,
            nearMountain: 0x15803d,
            groundFill: 0x5c4033,
            groundTop: 0x22c55e,
            accent: 0xbbf7d0,
            decorType: "pine",
            weather: "clouds"
        },
        spawn: { x: 4, y: 4 },
        portal: { x: 99, y: 12 },
        platforms: [
            { x: 0, y: 0, w: 26, h: 4, d: 6 },
            { x: 22, y: 3, w: 16, h: 7, d: 6 },
            { x: 35, y: 6, w: 15, h: 10, d: 6 },
            { x: 53, y: 4, w: 13, h: 8, d: 6 },
            { x: 68, y: 8, w: 14, h: 12, d: 6 },
            { x: 84, y: 12, w: 21, h: 16, d: 6 },
            // Elevated ledges
            { x: 11, y: 6.5, w: 6.5, h: 1.0, d: 4.5 },
            { x: 56, y: 9.5, w: 6.5, h: 1.0, d: 4.5 }
        ],
        hazards: [],
        enemies: [
            { type: "scout", x: 27, y: 3, minX: 23, maxX: 36, hp: 2, speed: 3.4 },
            { type: "scout", x: 41, y: 6, minX: 36, maxX: 48, hp: 2, speed: 3.8 },
            { type: "scout", x: 73, y: 8, minX: 69, maxX: 80, hp: 2, speed: 4.0 },
            { type: "scout", x: 91, y: 12, minX: 86, maxX: 96, hp: 2, speed: 4.2 }
        ]
    },

    // ------------------------------------------------------------------------
    // LEVEL 2: AUTUMN PEAKS
    // ------------------------------------------------------------------------
    {
        id: 2,
        name: "Autumn Peaks",
        subtitle: "Amber 3D peaks & ridge snipers",
        worldWidth: 114,
        friction: 85,
        theme: {
            skyColor: 0xb45309,
            fogColor: 0xd97706,
            sunColor: 0xfef3c7,
            farMountain: 0x7c2d12,
            nearMountain: 0x9a3412,
            groundFill: 0x451a03,
            groundTop: 0xf97316,
            accent: 0xfde047,
            decorType: "autumn",
            weather: "leaves"
        },
        spawn: { x: 4, y: 4 },
        portal: { x: 108, y: 13 },
        platforms: [
            { x: 0, y: 0, w: 22, h: 4, d: 6 },
            { x: 25, y: 3, w: 15, h: 7, d: 6 },
            { x: 43, y: 6, w: 16, h: 10, d: 6 },
            { x: 62, y: 3, w: 14, h: 7, d: 6 },
            { x: 79, y: 8, w: 15, h: 12, d: 6 },
            { x: 96, y: 13, w: 18, h: 17, d: 6 },
            // Sniper perches
            { x: 29, y: 8.5, w: 7, h: 1.0, d: 4.5 },
            { x: 65, y: 8.5, w: 7, h: 1.0, d: 4.5 }
        ],
        hazards: [],
        enemies: [
            { type: "scout", x: 28, y: 3, minX: 26, maxX: 38, hp: 2, speed: 4.2 },
            { type: "sniper", x: 32, y: 8.5, minX: 32, maxX: 32, hp: 3, speed: 0 },
            { type: "scout", x: 49, y: 6, minX: 44, maxX: 57, hp: 3, speed: 4.5 },
            { type: "sniper", x: 68, y: 8.5, minX: 68, maxX: 68, hp: 3, speed: 0 },
            { type: "scout", x: 84, y: 8, minX: 80, maxX: 92, hp: 3, speed: 4.8 },
            { type: "sniper", x: 102, y: 13, minX: 102, maxX: 102, hp: 3, speed: 0 }
        ]
    },

    // ------------------------------------------------------------------------
    // LEVEL 3: ROCKY CANYON
    // ------------------------------------------------------------------------
    {
        id: 3,
        name: "Rocky Canyon",
        subtitle: "Narrow 3D cliffs & armored golems",
        worldWidth: 120,
        friction: 85,
        theme: {
            skyColor: 0x57534e,
            fogColor: 0x78716c,
            sunColor: 0xfef08a,
            farMountain: 0x44403c,
            nearMountain: 0x7c2d12,
            groundFill: 0x292524,
            groundTop: 0xa8a29e,
            accent: 0xe7e5e4,
            decorType: "rock",
            weather: "dust"
        },
        spawn: { x: 4, y: 4 },
        portal: { x: 114, y: 13 },
        platforms: [
            { x: 0, y: 0, w: 18, h: 4, d: 6 },
            { x: 21, y: 3.5, w: 8, h: 1.2, d: 4.5 },
            { x: 32, y: 7, w: 8, h: 1.2, d: 4.5 },
            { x: 43, y: 10, w: 14, h: 14, d: 6 },
            { x: 61, y: 5, w: 8.5, h: 1.2, d: 4.5 },
            { x: 73, y: 8.5, w: 8.5, h: 1.2, d: 4.5 },
            { x: 85, y: 11.5, w: 14, h: 15.5, d: 6 },
            { x: 102, y: 13, w: 18, h: 17, d: 6 }
        ],
        hazards: [],
        enemies: [
            { type: "golem", x: 48, y: 10, minX: 44, maxX: 55, hp: 4, speed: 3.8 },
            { type: "sniper", x: 77, y: 8.5, minX: 77, maxX: 77, hp: 3, speed: 0 },
            { type: "golem", x: 90, y: 11.5, minX: 86, maxX: 97, hp: 4, speed: 4.2 },
            { type: "scout", x: 106, y: 13, minX: 103, maxX: 112, hp: 3, speed: 5.2 },
            { type: "sniper", x: 111, y: 13, minX: 111, maxX: 111, hp: 3, speed: 0 }
        ]
    },

    // ------------------------------------------------------------------------
    // LEVEL 4: FROZEN RIDGE
    // ------------------------------------------------------------------------
    {
        id: 4,
        name: "Frozen Ridge",
        subtitle: "Slippery 3D ice peaks & fast stalkers",
        worldWidth: 122,
        friction: 24, // Slippery icy deceleration!
        theme: {
            skyColor: 0x0369a1,
            fogColor: 0x38bdf8,
            sunColor: 0xffffff,
            farMountain: 0x0c4a6e,
            nearMountain: 0x0284c7,
            groundFill: 0x1e3a8a,
            groundTop: 0xe0f2fe,
            accent: 0x7dd3fc,
            decorType: "snowpine",
            weather: "snow"
        },
        spawn: { x: 4, y: 4 },
        portal: { x: 116, y: 13.5 },
        platforms: [
            { x: 0, y: 0, w: 20, h: 4, d: 6 },
            { x: 23, y: 3.5, w: 16, h: 7.5, d: 6 },
            { x: 42, y: 7, w: 12, h: 1.2, d: 5 },
            { x: 57, y: 10.5, w: 16, h: 14.5, d: 6 },
            { x: 76, y: 6, w: 13, h: 10, d: 6 },
            { x: 92, y: 10, w: 12, h: 1.2, d: 5 },
            { x: 106, y: 13.5, w: 16, h: 17.5, d: 6 }
        ],
        hazards: [],
        enemies: [
            { type: "scout", x: 29, y: 3.5, minX: 24, maxX: 37, hp: 4, speed: 6.4 },
            { type: "sniper", x: 48, y: 7, minX: 48, maxX: 48, hp: 4, speed: 0 },
            { type: "scout", x: 63, y: 10.5, minX: 58, maxX: 71, hp: 4, speed: 6.8 },
            { type: "golem", x: 81, y: 6, minX: 77, maxX: 87, hp: 5, speed: 5.0 },
            { type: "scout", x: 110, y: 13.5, minX: 107, maxX: 114, hp: 4, speed: 7.0 }
        ]
    },

    // ------------------------------------------------------------------------
    // LEVEL 5: CRYSTAL MOUNTAINS
    // ------------------------------------------------------------------------
    {
        id: 5,
        name: "Crystal Mountains",
        subtitle: "Glowing 3D caverns & crystal sentinels",
        worldWidth: 124,
        friction: 85,
        theme: {
            skyColor: 0x1e1b4b,
            fogColor: 0x311042,
            sunColor: 0xe879f9,
            farMountain: 0x2e1065,
            nearMountain: 0x581c87,
            groundFill: 0x170f2e,
            groundTop: 0xa855f7,
            accent: 0x22d3ee,
            decorType: "crystal",
            weather: "sparkles"
        },
        spawn: { x: 4, y: 4 },
        portal: { x: 118, y: 14 },
        platforms: [
            { x: 0, y: 0, w: 18, h: 4, d: 6 },
            { x: 21, y: 4, w: 10, h: 1.2, d: 4.8 },
            { x: 34, y: 8, w: 10, h: 1.2, d: 4.8 },
            { x: 47, y: 3, w: 17, h: 7, d: 6 },
            { x: 52, y: 9, w: 8, h: 1.2, d: 4.5 },
            { x: 67, y: 6.5, w: 14, h: 10.5, d: 6 },
            { x: 84, y: 10.5, w: 11, h: 1.2, d: 4.8 },
            { x: 98, y: 14, w: 26, h: 18, d: 6 }
        ],
        hazards: [],
        enemies: [
            { type: "sniper", x: 39, y: 8, minX: 39, maxX: 39, hp: 5, speed: 0 },
            { type: "golem", x: 53, y: 3, minX: 48, maxX: 62, hp: 5, speed: 5.2 },
            { type: "sniper", x: 56, y: 9, minX: 56, maxX: 56, hp: 5, speed: 0 },
            { type: "scout", x: 72, y: 6.5, minX: 68, maxX: 79, hp: 5, speed: 6.8 },
            { type: "golem", x: 104, y: 14, minX: 100, maxX: 114, hp: 5, speed: 5.6 },
            { type: "sniper", x: 113, y: 14, minX: 113, maxX: 113, hp: 5, speed: 0 }
        ]
    },

    // ------------------------------------------------------------------------
    // LEVEL 6: EMBER SUMMIT
    // ------------------------------------------------------------------------
    {
        id: 6,
        name: "Ember Summit",
        subtitle: "Volcanic 3D ridges, lava & magma brutes",
        worldWidth: 126,
        friction: 85,
        theme: {
            skyColor: 0x450a0a,
            fogColor: 0x7f1d1d,
            sunColor: 0xfbbf24,
            farMountain: 0x2a0808,
            nearMountain: 0x991b1b,
            groundFill: 0x1c1917,
            groundTop: 0xea580c,
            accent: 0xfacc15,
            decorType: "volcano",
            weather: "embers"
        },
        spawn: { x: 4, y: 4 },
        portal: { x: 120, y: 13 },
        platforms: [
            { x: 0, y: 0, w: 18, h: 4, d: 6 },
            { x: 23, y: 3.5, w: 14, h: 7.5, d: 6 },
            { x: 42, y: 6.5, w: 13, h: 10.5, d: 6 },
            { x: 60, y: 3.5, w: 15, h: 7.5, d: 6 },
            { x: 64, y: 9.5, w: 8, h: 1.2, d: 4.5 },
            { x: 80, y: 7.5, w: 14, h: 11.5, d: 6 },
            { x: 99, y: 13, w: 27, h: 17, d: 6 }
        ],
        // Glowing 3D molten lava pools in the gaps
        hazards: [
            { x: 18, y: -1.2, w: 5, h: 2.5, d: 6.5 },
            { x: 37, y: -1.2, w: 5, h: 2.5, d: 6.5 },
            { x: 55, y: -1.2, w: 5, h: 2.5, d: 6.5 },
            { x: 75, y: -1.2, w: 5, h: 2.5, d: 6.5 },
            { x: 94, y: -1.2, w: 5, h: 2.5, d: 6.5 }
        ],
        enemies: [
            { type: "golem", x: 28, y: 3.5, minX: 24, maxX: 35, hp: 6, speed: 5.2 },
            { type: "sniper", x: 48, y: 6.5, minX: 48, maxX: 48, hp: 5, speed: 0 },
            { type: "golem", x: 66, y: 3.5, minX: 61, maxX: 73, hp: 6, speed: 5.5 },
            { type: "sniper", x: 68, y: 9.5, minX: 68, maxX: 68, hp: 5, speed: 0 },
            { type: "scout", x: 85, y: 7.5, minX: 81, maxX: 92, hp: 5, speed: 7.2 },
            { type: "golem", x: 106, y: 13, minX: 101, maxX: 116, hp: 6, speed: 6.0 }
        ]
    },

    // ------------------------------------------------------------------------
    // LEVEL 7: THE FINAL SUMMIT (3D BOSS ARENA)
    // ------------------------------------------------------------------------
    {
        id: 7,
        name: "The Final Summit",
        subtitle: "Defeat the 3D Summit Overlord!",
        worldWidth: 46,
        isBossLevel: true,
        friction: 90,
        theme: {
            skyColor: 0x140726,
            fogColor: 0x2e1065,
            sunColor: 0xfef08a,
            farMountain: 0x1e0b36,
            nearMountain: 0x4c1d95,
            groundFill: 0x18181b,
            groundTop: 0xf59e0b,
            accent: 0xfef08a,
            decorType: "crown",
            weather: "embers"
        },
        spawn: { x: 5, y: 4 },
        portal: { x: 23, y: 0 },
        platforms: [
            // Grand Summit Altar Arena Floor
            { x: 0, y: 0, w: 46, h: 6, d: 8 },
            // Left, Center & Right Tactical 3D Ridges
            { x: 4, y: 5.5, w: 8.5, h: 1.1, d: 5 },
            { x: 33.5, y: 5.5, w: 8.5, h: 1.1, d: 5 },
            { x: 18, y: 10, w: 10, h: 1.1, d: 5 }
        ],
        hazards: [],
        enemies: [],
        bossConfig: {
            x: 34,
            y: 0,
            w: 3.8,
            h: 4.8,
            maxHp: 65
        }
    }
];

// ============================================================================
// 3. THREE.JS 3D SCENE, LIGHTING & RENDERER SETUP
// ============================================================================
const mountEl = document.getElementById('three-mount');
const scene = new THREE.Scene();

const camera = new THREE.PerspectiveCamera(46, window.innerWidth / window.innerHeight, 0.1, 350);
let cameraTiltMode = true; // Slightly angled 3D perspective vs straight 2.5D side view

const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
mountEl.appendChild(renderer.domElement);

// Three-Point Lighting Setup
const ambientLight = new THREE.AmbientLight(0xffffff, 0.58);
scene.add(ambientLight);

const dirLight = new THREE.DirectionalLight(0xfffbeb, 0.95);
dirLight.position.set(30, 55, 42);
dirLight.castShadow = true;
dirLight.shadow.mapSize.width = 2048;
dirLight.shadow.mapSize.height = 2048;
dirLight.shadow.camera.near = 5;
dirLight.shadow.camera.far = 200;
const dShadow = 55;
dirLight.shadow.camera.left = -dShadow;
dirLight.shadow.camera.right = dShadow;
dirLight.shadow.camera.top = dShadow;
dirLight.shadow.camera.bottom = -dShadow;
scene.add(dirLight);
scene.add(dirLight.target);

const rimLight = new THREE.DirectionalLight(0x38bdf8, 0.35);
rimLight.position.set(-20, 20, -30);
scene.add(rimLight);

// Groups for clean level rebuilding
const worldGroup = new THREE.Group();
const dynamicGroup = new THREE.Group();
scene.add(worldGroup);
scene.add(dynamicGroup);

// Shared Box Geometry for Voxel Efficiency
const unitBoxGeo = new THREE.BoxGeometry(1, 1, 1);

// ============================================================================
// 4. 3D CHARACTER & ENTITY BUILDERS
// ============================================================================
function createPlayerMesh() {
    const group = new THREE.Group();

    const suitMat = new THREE.MeshStandardMaterial({ color: 0x0284c7, roughness: 0.4 });
    const skinMat = new THREE.MeshStandardMaterial({ color: 0xfde68a, roughness: 0.5 });
    const hoodMat = new THREE.MeshStandardMaterial({ color: 0x38bdf8, roughness: 0.3 });
    const scarfMat = new THREE.MeshStandardMaterial({ color: 0xf43f5e, roughness: 0.5 });
    const bootMat = new THREE.MeshStandardMaterial({ color: 0x1e293b, roughness: 0.7 });
    const gunMat = new THREE.MeshStandardMaterial({ color: 0xe2e8f0, metalness: 0.6, roughness: 0.25 });

    // Legs (pivoted for walking animation)
    const leftLeg = new THREE.Mesh(unitBoxGeo, bootMat);
    leftLeg.scale.set(0.32, 0.55, 0.36);
    leftLeg.position.set(0, 0.275, 0.2);
    leftLeg.castShadow = true;
    group.add(leftLeg);

    const rightLeg = new THREE.Mesh(unitBoxGeo, bootMat);
    rightLeg.scale.set(0.32, 0.55, 0.36);
    rightLeg.position.set(0, 0.275, -0.2);
    rightLeg.castShadow = true;
    group.add(rightLeg);

    // Torso Jacket
    const torso = new THREE.Mesh(unitBoxGeo, suitMat);
    torso.scale.set(0.55, 0.65, 0.68);
    torso.position.set(0, 0.85, 0);
    torso.castShadow = true;
    group.add(torso);

    // Backpack Jet/Gear Pack
    const pack = new THREE.Mesh(unitBoxGeo, bootMat);
    pack.scale.set(0.28, 0.5, 0.52);
    pack.position.set(-0.36, 0.88, 0);
    pack.castShadow = true;
    group.add(pack);

    // Flowing Crimson Scarf
    const scarf = new THREE.Mesh(unitBoxGeo, scarfMat);
    scarf.scale.set(0.55, 0.22, 0.45);
    scarf.position.set(-0.42, 1.12, 0);
    group.add(scarf);

    // Head & Hood
    const head = new THREE.Mesh(unitBoxGeo, skinMat);
    head.scale.set(0.52, 0.48, 0.54);
    head.position.set(0.02, 1.4, 0);
    head.castShadow = true;
    group.add(head);

    const hood = new THREE.Mesh(unitBoxGeo, hoodMat);
    hood.scale.set(0.58, 0.2, 0.6);
    hood.position.set(0, 1.62, 0);
    group.add(hood);

    // Visor Eyes
    const eyeMat = new THREE.MeshBasicMaterial({ color: 0x0f172a });
    const eye = new THREE.Mesh(unitBoxGeo, eyeMat);
    eye.scale.set(0.08, 0.14, 0.38);
    eye.position.set(0.28, 1.42, 0);
    group.add(eye);

    // Energy Blaster Rifle
    const gun = new THREE.Mesh(unitBoxGeo, gunMat);
    gun.scale.set(0.85, 0.2, 0.18);
    gun.position.set(0.45, 0.88, 0.36);
    gun.castShadow = true;
    group.add(gun);

    // Muzzle Flash Glow Sphere
    const flashMat = new THREE.MeshBasicMaterial({ color: 0xfef08a });
    const flash = new THREE.Mesh(new THREE.OctahedronGeometry(0.24, 0), flashMat);
    flash.position.set(0.95, 0.88, 0.36);
    flash.visible = false;
    group.add(flash);

    group.userData = { leftLeg, rightLeg, scarf, flash };
    return group;
}

function createEnemyMesh(type) {
    const group = new THREE.Group();

    if (type === 'scout') {
        const bodyMat = new THREE.MeshStandardMaterial({ color: 0xe11d48, roughness: 0.35 });
        const topMat = new THREE.MeshStandardMaterial({ color: 0xfb7185, roughness: 0.3 });
        const body = new THREE.Mesh(unitBoxGeo, bodyMat);
        body.scale.set(1.15, 0.9, 1.15);
        body.position.y = 0.45;
        body.castShadow = true;
        group.add(body);

        const crest = new THREE.Mesh(unitBoxGeo, topMat);
        crest.scale.set(0.85, 0.3, 0.85);
        crest.position.y = 1.02;
        group.add(crest);

        const eye = new THREE.Mesh(unitBoxGeo, new THREE.MeshBasicMaterial({ color: 0xffffff }));
        eye.scale.set(0.1, 0.22, 0.65);
        eye.position.set(0.58, 0.55, 0);
        group.add(eye);
    } else if (type === 'sniper') {
        const towerMat = new THREE.MeshStandardMaterial({ color: 0x7c3aed, roughness: 0.4 });
        const headMat = new THREE.MeshStandardMaterial({ color: 0xc4b5fd, roughness: 0.3 });
        const barrelMat = new THREE.MeshStandardMaterial({ color: 0xf59e0b, metalness: 0.6, roughness: 0.2 });

        const base = new THREE.Mesh(unitBoxGeo, towerMat);
        base.scale.set(0.95, 1.35, 0.95);
        base.position.y = 0.675;
        base.castShadow = true;
        group.add(base);

        const turret = new THREE.Mesh(unitBoxGeo, headMat);
        turret.scale.set(1.05, 0.42, 1.05);
        turret.position.y = 1.35;
        group.add(turret);

        const barrel = new THREE.Mesh(unitBoxGeo, barrelMat);
        barrel.scale.set(0.75, 0.24, 0.24);
        barrel.position.set(0.65, 1.35, 0);
        group.add(barrel);
    } else if (type === 'golem') {
        const armorMat = new THREE.MeshStandardMaterial({ color: 0x475569, metalness: 0.4, roughness: 0.6 });
        const plateMat = new THREE.MeshStandardMaterial({ color: 0x94a3b8, roughness: 0.5 });
        const coreMat = new THREE.MeshBasicMaterial({ color: 0xf97316 });

        const torso = new THREE.Mesh(unitBoxGeo, armorMat);
        torso.scale.set(1.45, 1.65, 1.45);
        torso.position.y = 0.825;
        torso.castShadow = true;
        group.add(torso);

        const shoulders = new THREE.Mesh(unitBoxGeo, plateMat);
        shoulders.scale.set(1.6, 0.45, 1.65);
        shoulders.position.y = 1.45;
        group.add(shoulders);

        const visor = new THREE.Mesh(unitBoxGeo, coreMat);
        visor.scale.set(0.12, 0.22, 0.9);
        visor.position.set(0.74, 1.25, 0);
        group.add(visor);
    }

    return group;
}

function createBossMesh() {
    const group = new THREE.Group();

    const armorMat = new THREE.MeshStandardMaterial({ color: 0x3b0764, metalness: 0.35, roughness: 0.45 });
    const goldMat = new THREE.MeshStandardMaterial({ color: 0xf59e0b, metalness: 0.7, roughness: 0.25 });
    const coreMat = new THREE.MeshBasicMaterial({ color: 0xf43f5e });
    const eyeMat = new THREE.MeshBasicMaterial({ color: 0x38bdf8 });
    const cannonMat = new THREE.MeshStandardMaterial({ color: 0x64748b, metalness: 0.6, roughness: 0.3 });

    // Massive Armored Body
    const body = new THREE.Mesh(unitBoxGeo, armorMat);
    body.scale.set(3.2, 3.8, 2.8);
    body.position.y = 1.9;
    body.castShadow = true;
    group.add(body);

    // Golden Crown & Horns
    const crown = new THREE.Mesh(unitBoxGeo, goldMat);
    crown.scale.set(2.6, 0.65, 2.5);
    crown.position.y = 4.05;
    group.add(crown);

    [-0.9, 0, 0.9].forEach((zOff, idx) => {
        const horn = new THREE.Mesh(new THREE.ConeGeometry(0.35, idx === 1 ? 1.1 : 0.8, 4), goldMat);
        horn.position.set(0, 4.65, zOff);
        group.add(horn);
    });

    // Glowing Reactor Core on Chest
    const core = new THREE.Mesh(unitBoxGeo, coreMat);
    core.scale.set(0.3, 1.1, 1.2);
    core.position.set(1.55, 2.0, 0);
    group.add(core);

    // Cyan Visor
    const visor = new THREE.Mesh(unitBoxGeo, eyeMat);
    visor.scale.set(0.25, 0.35, 1.8);
    visor.position.set(1.58, 3.25, 0);
    group.add(visor);

    // Twin Shoulder Siege Cannons
    [-1.65, 1.65].forEach(zSide => {
        const cannon = new THREE.Mesh(unitBoxGeo, cannonMat);
        cannon.scale.set(2.2, 0.75, 0.75);
        cannon.position.set(0.6, 2.75, zSide);
        cannon.castShadow = true;
        group.add(cannon);
    });

    return group;
}

// ============================================================================
// 5. GAME STATE & PERSISTENCE
// ============================================================================
let unlockedLevel = parseInt(localStorage.getItem('koizi_unlocked') || '1', 10);
let completedLevels = JSON.parse(localStorage.getItem('koizi_completed') || '[]');

function saveProgress() {
    localStorage.setItem('koizi_unlocked', String(unlockedLevel));
    localStorage.setItem('koizi_completed', JSON.stringify(completedLevels));
}

let state = 'MENU'; // MENU, PLAYING, PAUSED, GAMEOVER, COMPLETE, VICTORY
let currentLevelIdx = 0;
let levelTimer = 0;
let totalKillsSession = 0;
let levelKills = 0;
let levelTotalEnemies = 0;
let screenShake = 0;
let camCurrentX = 12;
let camCurrentY = 7;

// Active Entities
let platforms = [];
let hazards = [];
let enemies = [];
let playerBullets = [];
let enemyBullets = [];
let particles3D = [];
let portalObj = null;
let boss = null;
let weatherMeshPoints = null;

// Player Physics & Mesh
const playerMesh = createPlayerMesh();
dynamicGroup.add(playerMesh);

const player = {
    x: 4,
    y: 4,
    w: 0.9,
    h: 1.65,
    vx: 0,
    vy: 0,
    speed: 11.2,
    accel: 92,
    jumpForce: 21.5,
    gravity: 54,
    onGround: false,
    coyoteTimer: 0,
    facing: 1,
    hp: 5,
    maxHp: 5,
    invuln: 0,
    shootCooldown: 0,
    muzzleFlash: 0,
    animTimer: 0
};

const input = {
    left: false,
    right: false,
    jumpPressed: false,
    shootHeld: false
};

// ============================================================================
// 6. UI & MENU CONTROLLERS
// ============================================================================
const menus = {
    main: document.getElementById('menu-main'),
    levels: document.getElementById('menu-levels'),
    pause: document.getElementById('menu-pause'),
    gameover: document.getElementById('menu-gameover'),
    complete: document.getElementById('menu-complete'),
    victory: document.getElementById('menu-victory')
};

const hudEl = document.getElementById('hud');
const bossHudEl = document.getElementById('boss-hud');
const touchUiEl = document.getElementById('touch-ui');

function showOnlyMenu(menuKey) {
    Object.values(menus).forEach(m => m.classList.add('hidden'));
    if (menuKey && menus[menuKey]) {
        menus[menuKey].classList.remove('hidden');
    }
    const isPlaying = (menuKey === null);
    hudEl.classList.toggle('hidden', !isPlaying);
    touchUiEl.classList.toggle('hidden', !isPlaying);
}

function showToast(msg) {
    const toast = document.getElementById('toast-banner');
    document.getElementById('toast-text').textContent = msg;
    toast.classList.remove('opacity-0', 'scale-95');
    toast.classList.add('opacity-100', 'scale-100');
    setTimeout(() => {
        toast.classList.remove('opacity-100', 'scale-100');
        toast.classList.add('opacity-0', 'scale-95');
    }, 2400);
}

function hexToCss(hexNum) {
    return '#' + hexNum.toString(16).padStart(6, '0');
}

function renderLevelSelectGrid() {
    const grid = document.getElementById('levels-grid');
    grid.innerHTML = '';

    SUMMITS.forEach((lvl, idx) => {
        const isUnlocked = lvl.id <= unlockedLevel;
        const isCompleted = completedLevels.includes(lvl.id);

        const card = document.createElement('button');
        card.disabled = !isUnlocked;
        card.className = `text-left p-3.5 rounded-lg border-2 transition flex flex-col justify-between ${
            isUnlocked
                ? 'bg-slate-900/95 border-slate-400 hover:border-amber-300 hover:-translate-y-0.5 cursor-pointer'
                : 'bg-slate-950/70 border-slate-800 opacity-55 cursor-not-allowed'
        }`;

        const c1 = hexToCss(lvl.theme.skyColor);
        const c2 = hexToCss(lvl.theme.groundTop);
        const c3 = hexToCss(lvl.theme.accent);

        card.innerHTML = `
            <div>
                <div class="flex items-center justify-between mb-2">
                    <span class="pixel-font text-[10px] text-amber-300">SUMMIT 0${lvl.id}</span>
                    <span class="text-xs font-bold px-2 py-0.5 rounded ${
                        isCompleted
                            ? 'bg-emerald-950 text-emerald-300 border border-emerald-500/40'
                            : isUnlocked
                            ? 'bg-sky-950 text-sky-300 border border-sky-500/40'
                            : 'bg-slate-900 text-slate-500'
                    }">
                        ${isCompleted ? '★ CLEARED' : isUnlocked ? 'OPEN' : '🔒 LOCKED'}
                    </span>
                </div>
                <div class="w-full h-3 rounded mb-2 border border-white/20" style="background: linear-gradient(90deg, ${c1}, ${c2}, ${c3})"></div>
                <div class="pixel-font text-xs text-white mb-1">${lvl.name}</div>
                <div class="text-[11px] text-slate-400 leading-snug">${lvl.subtitle}</div>
            </div>
        `;

        if (isUnlocked) {
            card.addEventListener('click', () => {
                sfx.init();
                startLevel(idx);
            });
        }
        grid.appendChild(card);
    });
}

function updateHUD() {
    const lvl = SUMMITS[currentLevelIdx];
    document.getElementById('hud-level-title').textContent = `LVL ${lvl.id}: ${lvl.name.toUpperCase()}`;

    const heartsDiv = document.getElementById('hud-hearts');
    heartsDiv.innerHTML = '';
    for (let i = 0; i < player.maxHp; i++) {
        const full = i < player.hp;
        heartsDiv.innerHTML += `<span class="text-sm sm:text-base ${full ? 'text-rose-500' : 'text-slate-700'}">♥️</span>`;
    }

    if (lvl.isBossLevel) {
        document.getElementById('hud-enemy-box').classList.add('hidden');
        bossHudEl.classList.remove('hidden');
        bossHudEl.classList.add('flex');
        if (boss) {
            const pct = Math.max(0, (boss.hp / boss.maxHp) * 100);
            document.getElementById('boss-hp-fill').style.width = `${pct}%`;
            document.getElementById('boss-hp-text').textContent = `${Math.max(0, boss.hp)}/${boss.maxHp}`;
        }
    } else {
        document.getElementById('hud-enemy-box').classList.remove('hidden');
        bossHudEl.classList.add('hidden');
        bossHudEl.classList.remove('flex');
        const remaining = enemies.filter(e => e.hp > 0).length;
        const statusColor = remaining === 0 ? 'text-emerald-300' : 'text-cyan-300';
        const el = document.getElementById('hud-enemies');
        el.className = `pixel-font text-[10px] sm:text-xs ${statusColor}`;
        el.textContent = remaining === 0 ? 'PORTAL OPEN!' : `FOES: ${remaining}/${levelTotalEnemies}`;
    }
}

// ============================================================================
// 7. 3D WORLD BUILDER & LEVEL INITIALIZATION
// ============================================================================
function clearGroup(grp) {
    while (grp.children.length > 0) {
        grp.remove(grp.children[0]);
    }
}

function build3DEnvironment(lvl) {
    clearGroup(worldGroup);

    // Sky & Atmospheric Fog
    scene.background = new THREE.Color(lvl.theme.skyColor);
    scene.fog = new THREE.Fog(lvl.theme.fogColor, 32, 135);
    dirLight.color.setHex(lvl.theme.sunColor);

    // 1. Background 3D Mountain Peaks (Far & Near Layers in -Z depth)
    const farMat = new THREE.MeshStandardMaterial({ color: lvl.theme.farMountain, roughness: 0.9, flatShading: true });
    const nearMat = new THREE.MeshStandardMaterial({ color: lvl.theme.nearMountain, roughness: 0.85, flatShading: true });
    const snowCapMat = new THREE.MeshStandardMaterial({ color: 0xf8fafc, roughness: 0.6, flatShading: true });

    for (let mx = -25; mx <= lvl.worldWidth + 35; mx += 16) {
        const hFar = 22 + Math.abs(Math.sin(mx * 0.13)) * 18;
        const coneFar = new THREE.Mesh(new THREE.ConeGeometry(15, hFar, 5), farMat);
        coneFar.position.set(mx, hFar * 0.5 - 6, -34);
        worldGroup.add(coneFar);

        if (lvl.id === 4 || lvl.id === 7) {
            const cap = new THREE.Mesh(new THREE.ConeGeometry(5.5, hFar * 0.35, 5), snowCapMat);
            cap.position.set(mx, hFar * 0.82 - 6, -34);
            worldGroup.add(cap);
        }
    }

    for (let mx = -15; mx <= lvl.worldWidth + 25; mx += 12) {
        const hNear = 15 + Math.abs(Math.cos(mx * 0.21)) * 13;
        const coneNear = new THREE.Mesh(new THREE.ConeGeometry(11, hNear, 5), nearMat);
        coneNear.position.set(mx + 5, hNear * 0.5 - 5, -17);
        worldGroup.add(coneNear);
    }

    // 2. Drifting Low-Poly 3D Clouds
    const cloudMat = new THREE.MeshStandardMaterial({
        color: lvl.id === 6 ? 0x44403c : 0xffffff,
        roughness: 0.9,
        transparent: true,
        opacity: 0.85
    });
    for (let cx = 0; cx <= lvl.worldWidth + 20; cx += 18) {
        const cloudGroup = new THREE.Group();
        const c1 = new THREE.Mesh(unitBoxGeo, cloudMat);
        c1.scale.set(4.5, 1.1, 2.2);
        const c2 = new THREE.Mesh(unitBoxGeo, cloudMat);
        c2.scale.set(2.6, 1.3, 1.8);
        c2.position.set(0.6, 0.6, 0);
        cloudGroup.add(c1, c2);
        cloudGroup.position.set(cx, 19 + (cx % 7), -12 - (cx % 9));
        worldGroup.add(cloudGroup);
    }

    // 3. 3D Platforms & Mountain Ridges
    const rockBodyMat = new THREE.MeshStandardMaterial({ color: lvl.theme.groundFill, roughness: 0.85 });
    const topTurfMat = new THREE.MeshStandardMaterial({ color: lvl.theme.groundTop, roughness: 0.65 });
    const trimMat = new THREE.MeshStandardMaterial({ color: lvl.theme.accent, roughness: 0.5 });

    platforms.forEach(p => {
        // Main mountain block
        const block = new THREE.Mesh(unitBoxGeo, rockBodyMat);
        block.scale.set(p.w, p.h, p.d);
        block.position.set(p.x + p.w * 0.5, p.y - p.h * 0.5, 0);
        block.receiveShadow = true;
        block.castShadow = true;
        worldGroup.add(block);

        // Top surface layer (Grass / Snow / Obsidian Crust)
        const topLayer = new THREE.Mesh(unitBoxGeo, topTurfMat);
        topLayer.scale.set(p.w + 0.12, 0.38, p.d + 0.15);
        topLayer.position.set(p.x + p.w * 0.5, p.y - 0.15, 0);
        topLayer.receiveShadow = true;
        worldGroup.add(topLayer);

        // Subtle front highlight trim
        const trim = new THREE.Mesh(unitBoxGeo, trimMat);
        trim.scale.set(p.w + 0.14, 0.1, 0.12);
        trim.position.set(p.x + p.w * 0.5, p.y - 0.02, p.d * 0.5 + 0.05);
        worldGroup.add(trim);

        // 4. 3D Environmental Props along the back edge (-Z) of wide ridges
        if (p.w >= 7) {
            for (let dx = p.x + 2; dx <= p.x + p.w - 2; dx += 5.5) {
                const propZ = -p.d * 0.34;
                if (lvl.theme.decorType === 'pine' || lvl.theme.decorType === 'snowpine') {
                    const trunk = new THREE.Mesh(unitBoxGeo, new THREE.MeshStandardMaterial({ color: 0x451a03 }));
                    trunk.scale.set(0.35, 1.0, 0.35);
                    trunk.position.set(dx, p.y + 0.5, propZ);
                    worldGroup.add(trunk);

                    const leavesColor = lvl.theme.decorType === 'snowpine' ? 0x1e3a8a : 0x166534;
                    const leaves = new THREE.Mesh(new THREE.ConeGeometry(1.1, 2.5, 5), new THREE.MeshStandardMaterial({ color: leavesColor, flatShading: true }));
                    leaves.position.set(dx, p.y + 2.1, propZ);
                    leaves.castShadow = true;
                    worldGroup.add(leaves);

                    if (lvl.theme.decorType === 'snowpine') {
                        const snowTop = new THREE.Mesh(new THREE.ConeGeometry(0.6, 1.0, 5), snowCapMat);
                        snowTop.position.set(dx, p.y + 2.85, propZ);
                        worldGroup.add(snowTop);
                    }
                } else if (lvl.theme.decorType === 'autumn') {
                    const trunk = new THREE.Mesh(unitBoxGeo, new THREE.MeshStandardMaterial({ color: 0x451a03 }));
                    trunk.scale.set(0.35, 1.1, 0.35);
                    trunk.position.set(dx, p.y + 0.55, propZ);
                    worldGroup.add(trunk);

                    const crownCol = Math.floor(dx) % 2 === 0 ? 0xea580c : 0xdc2626;
                    const canopy = new THREE.Mesh(unitBoxGeo, new THREE.MeshStandardMaterial({ color: crownCol }));
                    canopy.scale.set(1.7, 1.5, 1.7);
                    canopy.position.set(dx, p.y + 1.8, propZ);
                    canopy.castShadow = true;
                    worldGroup.add(canopy);
                } else if (lvl.theme.decorType === 'crystal') {
                    const crysMat = new THREE.MeshStandardMaterial({
                        color: 0x22d3ee,
                        emissive: 0x0891b2,
                        emissiveIntensity: 0.7,
                        roughness: 0.2
                    });
                    const spire = new THREE.Mesh(new THREE.OctahedronGeometry(0.75, 0), crysMat);
                    spire.scale.set(0.65, 1.8, 0.65);
                    spire.position.set(dx, p.y + 0.9, propZ);
                    worldGroup.add(spire);
                } else if (lvl.theme.decorType === 'rock' || lvl.theme.decorType === 'volcano') {
                    const boulder = new THREE.Mesh(new THREE.DodecahedronGeometry(0.75, 0), rockBodyMat);
                    boulder.position.set(dx, p.y + 0.45, propZ);
                    boulder.castShadow = true;
                    worldGroup.add(boulder);
                }
            }
        }
    });

    // 5. Glowing 3D Molten Lava Pools (Level 6)
    const lavaMat = new THREE.MeshStandardMaterial({
        color: 0xdc2626,
        emissive: 0xea580c,
        emissiveIntensity: 0.95,
        roughness: 0.3
    });
    hazards.forEach(h => {
        const lava = new THREE.Mesh(unitBoxGeo, lavaMat);
        lava.scale.set(h.w, h.h, h.d);
        lava.position.set(h.x + h.w * 0.5, h.y + h.h * 0.5, 0);
        worldGroup.add(lava);
    });

    // 6. Spawn Base Camp Flag
    const pole = new THREE.Mesh(unitBoxGeo, new THREE.MeshStandardMaterial({ color: 0xf8fafc }));
    pole.scale.set(0.14, 2.6, 0.14);
    pole.position.set(lvl.spawn.x - 1.2, lvl.spawn.y + 1.3, -1.2);
    worldGroup.add(pole);

    const flag = new THREE.Mesh(unitBoxGeo, new THREE.MeshStandardMaterial({ color: 0x38bdf8, emissive: 0x0284c7, emissiveIntensity: 0.4 }));
    flag.scale.set(1.0, 0.6, 0.08);
    flag.position.set(lvl.spawn.x - 0.65, lvl.spawn.y + 2.2, -1.2);
    worldGroup.add(flag);

    // 7. 3D Summit Exit Portal Archway
    const portalGroup = new THREE.Group();
    const archMat = new THREE.MeshStandardMaterial({ color: 0x475569, metalness: 0.5, roughness: 0.4 });
    const leftPillar = new THREE.Mesh(unitBoxGeo, archMat);
    leftPillar.scale.set(0.5, 3.2, 0.7);
    leftPillar.position.set(-1.3, 1.6, 0);

    const rightPillar = new THREE.Mesh(unitBoxGeo, archMat);
    rightPillar.scale.set(0.5, 3.2, 0.7);
    rightPillar.position.set(1.3, 1.6, 0);

    const lintel = new THREE.Mesh(unitBoxGeo, archMat);
    lintel.scale.set(3.4, 0.5, 0.85);
    lintel.position.set(0, 3.35, 0);

    const coreMat = new THREE.MeshStandardMaterial({
        color: 0x64748b,
        emissive: 0x000000,
        transparent: true,
        opacity: 0.85
    });
    const core = new THREE.Mesh(unitBoxGeo, coreMat);
    core.scale.set(2.1, 3.0, 0.25);
    core.position.set(0, 1.55, 0);

    portalGroup.add(leftPillar, rightPillar, lintel, core);
    portalGroup.position.set(lvl.portal.x, lvl.portal.y, 0);
    if (lvl.isBossLevel) portalGroup.visible = false;
    worldGroup.add(portalGroup);

    portalObj = {
        group: portalGroup,
        coreMat,
        x: lvl.portal.x,
        y: lvl.portal.y,
        unlocked: (!lvl.isBossLevel && enemies.length === 0)
    };
    updatePortalVisuals();

    // 8. Ambient 3D Weather Particle Field
    const pCount = 160;
    const pGeo = new THREE.BufferGeometry();
    const positions = new Float32Array(pCount * 3);
    for (let i = 0; i < pCount; i++) {
        positions[i * 3] = Math.random() * (lvl.worldWidth + 20) - 10;
        positions[i * 3 + 1] = Math.random() * 26;
        positions[i * 3 + 2] = (Math.random() - 0.5) * 24;
    }
    pGeo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    const wColor = lvl.theme.weather === 'embers' ? 0xfb923c :
                   lvl.theme.weather === 'leaves' ? 0xf59e0b :
                   lvl.theme.weather === 'sparkles' ? 0x22d3ee : 0xffffff;
    const pMat = new THREE.PointsMaterial({ color: wColor, size: 0.28, transparent: true, opacity: 0.75 });
    weatherMeshPoints = new THREE.Points(pGeo, pMat);
    worldGroup.add(weatherMeshPoints);
}

function updatePortalVisuals() {
    if (!portalObj) return;
    if (portalObj.unlocked) {
        portalObj.coreMat.color.setHex(0x10b981);
        portalObj.coreMat.emissive.setHex(0x059669);
        portalObj.coreMat.emissiveIntensity = 1.2;
    } else {
        portalObj.coreMat.color.setHex(0x475569);
        portalObj.coreMat.emissive.setHex(0x000000);
    }
}

function startLevel(idx) {
    currentLevelIdx = idx;
    const lvl = SUMMITS[idx];

    // Clear previous dynamic entities (keep playerMesh)
    while (dynamicGroup.children.length > 0) {
        dynamicGroup.remove(dynamicGroup.children[0]);
    }
    dynamicGroup.add(playerMesh);

    platforms = lvl.platforms.map(p => ({ ...p }));
    hazards = lvl.hazards.map(h => ({ ...h }));

    enemies = lvl.enemies.map(e => {
        const mesh = createEnemyMesh(e.type);
        mesh.position.set(e.x, e.y, 0);
        dynamicGroup.add(mesh);
        return {
            ...e,
            mesh,
            w: e.type === 'golem' ? 1.45 : 1.1,
            h: e.type === 'golem' ? 1.65 : 1.35,
            maxHp: e.hp,
            dir: 1,
            shootTimer: 1.3 + Math.random() * 1.1,
            hitFlash: 0
        };
    });

    levelTotalEnemies = enemies.length;
    levelKills = 0;
    levelTimer = 0;
    playerBullets = [];
    enemyBullets = [];
    particles3D = [];

    // Reset Player
    player.x = lvl.spawn.x;
    player.y = lvl.spawn.y + 0.5;
    player.vx = 0;
    player.vy = 0;
    player.hp = player.maxHp;
    player.invuln = 0;
    player.facing = 1;
    player.onGround = false;
    playerMesh.position.set(player.x, player.y, 0);
    playerMesh.rotation.y = 0;

    build3DEnvironment(lvl);

    // Setup Final Boss on Level 7
    if (lvl.isBossLevel && lvl.bossConfig) {
        const bc = lvl.bossConfig;
        const bMesh = createBossMesh();
        bMesh.position.set(bc.x, bc.y, 0);
        bMesh.rotation.y = Math.PI;
        dynamicGroup.add(bMesh);

        boss = {
            mesh: bMesh,
            x: bc.x,
            y: bc.y,
            w: bc.w,
            h: bc.h,
            vx: 0,
            vy: 0,
            hp: bc.maxHp,
            maxHp: bc.maxHp,
            facing: -1,
            stateTimer: 1.5,
            attackIndex: 0,
            hitFlash: 0,
            onGround: true,
            defeated: false
        };
    } else {
        boss = null;
    }

    camCurrentX = player.x + 5;
    camCurrentY = player.y + 4;
    state = 'PLAYING';
    showOnlyMenu(null);
    updateHUD();
    showToast(`KOizi // SUMMIT ${lvl.id}: ${lvl.name.toUpperCase()}`);
}

// ============================================================================
// 8. 3D PARTICLES, PROJECTILES & COMBAT
// ============================================================================
function spawnParticles3D(x, y, z, colorHex, count = 10, speed = 8) {
    const mat = new THREE.MeshBasicMaterial({ color: colorHex });
    for (let i = 0; i < count; i++) {
        const mesh = new THREE.Mesh(unitBoxGeo, mat);
        const sz = 0.16 + Math.random() * 0.22;
        mesh.scale.set(sz, sz, sz);
        mesh.position.set(x, y, z);
        dynamicGroup.add(mesh);

        const theta = Math.random() * Math.PI * 2;
        const phi = Math.random() * Math.PI;
        const spd = (0.35 + Math.random() * 0.65) * speed;

        particles3D.push({
            mesh,
            vx: Math.sin(phi) * Math.cos(theta) * spd,
            vy: Math.abs(Math.cos(phi)) * spd + 2.5,
            vz: Math.sin(phi) * Math.sin(theta) * spd,
            life: 0.35 + Math.random() * 0.3
        });
    }
}

function firePlayerBullet() {
    if (player.shootCooldown > 0) return;
    player.shootCooldown = 0.21;
    player.muzzleFlash = 0.08;
    sfx.shoot();

    const bx = player.x + player.facing * 0.95;
    const by = player.y + 0.9;

    const bulletMat = new THREE.MeshBasicMaterial({ color: 0x38bdf8 });
    const mesh = new THREE.Mesh(unitBoxGeo, bulletMat);
    mesh.scale.set(0.65, 0.24, 0.24);
    mesh.position.set(bx, by, 0);
    dynamicGroup.add(mesh);

    playerBullets.push({
        mesh,
        x: bx,
        y: by,
        w: 0.65,
        h: 0.3,
        vx: player.facing * 26,
        life: 1.15
    });
}

function spawnEnemyBullet(x, y, vx, vy, colorHex = 0xf43f5e, size = 0.45) {
    const mesh = new THREE.Mesh(new THREE.OctahedronGeometry(size * 0.65, 0), new THREE.MeshBasicMaterial({ color: colorHex }));
    mesh.position.set(x, y, 0);
    dynamicGroup.add(mesh);

    enemyBullets.push({
        mesh,
        x,
        y,
        w: size,
        h: size,
        vx,
        vy,
        life: 2.6
    });
}

function damagePlayer(amount = 1, knockbackDir = 0, reasonText = null) {
    if (player.invuln > 0 || state !== 'PLAYING') return;

    player.hp = Math.max(0, player.hp - amount);
    player.invuln = 1.1;
    screenShake = 0.65;
    sfx.playerHurt();
    spawnParticles3D(player.x, player.y + 0.8, 0, 0xf43f5e, 16, 9);

    if (knockbackDir !== 0) {
        player.vx = knockbackDir * 11;
        player.vy = 11;
    }

    updateHUD();

    if (player.hp <= 0) {
        state = 'GAMEOVER';
        document.getElementById('gameover-reason').textContent =
            reasonText || `Defeated on Summit ${SUMMITS[currentLevelIdx].id} (${SUMMITS[currentLevelIdx].name}).`;
        showOnlyMenu('gameover');
    }
}

// 2D AABB in X/Y gameplay plane (center-bottom X, bottom Y)
function overlapXY(a, b) {
    const aMinX = a.x - a.w * 0.5;
    const aMaxX = a.x + a.w * 0.5;
    const aMinY = a.y;
    const aMaxY = a.y + a.h;

    const bMinX = b.x - b.w * 0.5;
    const bMaxX = b.x + b.w * 0.5;
    const bMinY = b.y;
    const bMaxY = b.y + b.h;

    return aMinX < bMaxX && aMaxX > bMinX && aMinY < bMaxY && aMaxY > bMinY;
}

// ============================================================================
// 9. PHYSICS & AI UPDATE LOOP
// ============================================================================
function update(dt) {
    // Animate ambient weather particles even on menu backdrop
    if (weatherMeshPoints) {
        const pos = weatherMeshPoints.geometry.attributes.position.array;
        for (let i = 0; i < pos.length; i += 3) {
            pos[i] -= 1.4 * dt;
            pos[i + 1] -= 2.2 * dt;
            if (pos[i + 1] < -2) pos[i + 1] = 24;
        }
        weatherMeshPoints.geometry.attributes.position.needsUpdate = true;
    }

    if (state !== 'PLAYING') return;

    const lvl = SUMMITS[currentLevelIdx];
    levelTimer += dt;
    if (screenShake > 0) screenShake = Math.max(0, screenShake - dt * 2.4);
    if (player.invuln > 0) player.invuln = Math.max(0, player.invuln - dt);
    if (player.shootCooldown > 0) player.shootCooldown = Math.max(0, player.shootCooldown - dt);
    if (player.muzzleFlash > 0) player.muzzleFlash = Math.max(0, player.muzzleFlash - dt);

    // 1. Player Horizontal Movement
    const dir = (input.right ? 1 : 0) - (input.left ? 1 : 0);
    if (dir !== 0) {
        player.facing = dir;
        player.vx += dir * player.accel * dt;
        if (Math.abs(player.vx) > player.speed) {
            player.vx = Math.si