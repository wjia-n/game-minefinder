# Mine Finder — RULES.md
_The authoritative rules. Implementation must match this document._

## 1. Objective
Clear the entire minefield without detonating a mine. Reveal every safe tile; mark suspected mines with flags. Finish as fast as possible.

## 2. Setup
- Choose a difficulty: **Cozy Dig** 9×9/10 mines, **Deep Dig** 12×12/25 mines (FREE); **Gold Rush** 16×16/45 mines, **Abyss** 20×20/90 mines (PRO).
- **Daily Challenge** (everyone): the same 12×12/25 field for all players that day, generated from the calendar date as the seed.
- Your first tap is ALWAYS safe: mines are placed only after the first reveal tap, and the tapped tile plus its 8 neighbors never contain mines.

## 3. Turn order
- Single-player, real-time. No turns, no opponents.

## 4. Legal moves
- **Tap** an unopened, unflagged tile → reveal it. If it is empty (0 neighboring mines), its safe neighbors cascade open automatically.
- **Long-press** an unopened tile → plant or remove a flag 🚩.
- **Chord**: tap an already-revealed number when the number of adjacent flags equals that number → reveal all other adjacent unflagged tiles.
- **Hint** (💡 button): the game pulses one guaranteed-safe unopened tile for ~1.6s. Free: 3 hints per game. PRO: unlimited.

## 5. Illegal moves
- Tapping a flagged tile does nothing (invalid sound).
- Flagging an already-revealed tile does nothing.
- Tapping a revealed number with the wrong flag count does nothing (no chord).
- Any input while the game is paused or over is ignored.

## 6. Captures
- N/A (no captures in Mine Finder).

## 7. Special rules
- **First tap safety**: mines are placed after the first reveal, excluding the 3×3 around it (RULES §2).
- **Chord risk**: chording with wrongly placed flags can detonate a mine — flags are the player's responsibility.
- **Hints are honest**: a hint cell is guaranteed safe (a neighbor fully accounted for by flags, or any unmined cell).

## 8. Scoring
- The score is your time: seconds from the first reveal tap to clearing the field (or BOOM).
- Best times are kept per difficulty. Beating your best shows a NEW BEST TIME celebration.
- Daily Challenge clears are recorded per calendar date.

## 9. Winning conditions
- All safe tiles revealed (every non-mine tile open). Win is checked logically at move time; the victory flag wave then plants flags on mines one by one (animated, never instant) before the celebration dialog.

## 10. Draw conditions
- N/A — every game ends in a win or a BOOM.

## 11. AI strategy
- N/A — single-player puzzle, no opponents. The hint system uses: (a) numbers whose remaining mines are fully covered by flags → a safe closed neighbor; (b) fallback: any unopened non-mine tile.

## 12. Edge cases
- **Mine placement impossibility**: if the board is too small for mines after the 3×3 exclusion (not possible with shipped difficulties), mines fill all remaining spots.
- **Win during cascade**: win is detected when `openCount == total − mines`, regardless of animation state; the flag wave drains after.
- **Chord into a mine**: detonates exactly like tapping the mine.
- **Pause**: freezes the game clock and all reveal animations; resume re-arms them via the watchdog.
- **App backgrounding**: clock and music pause; everything resumes on return.
- **Restart mid-cascade**: clears queues and timers before rebuilding the board.

## 13. Test cases
1. First tap never detonates (any difficulty, any cell, including daily seed).
2. Flood cascade opens the full connected empty region.
3. Flag count HUD decreases/increases correctly; mines-left never goes negative below −(mines).
4. Chord with correct flags opens exactly the remaining neighbors.
5. Chord with a wrong flag detonates (BOOM + minefield reveal, one mine at a time).
6. Win requires every safe tile open; flag wave animates before the dialog.
7. Timer freezes on pause and resumes on unpause.
8. Best time only updates on a strictly faster clear.
9. Daily Challenge produces the same layout for the same date.
10. Hints: free players get exactly 3 per game; the hinted cell is always safe.
11. No input during `animating` loses a tap (logical state applies immediately).
12. Restart at any moment leaves no orphan timers (watchdog idle).
