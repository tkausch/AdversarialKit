# AdversarialKit

A small, pure-Swift toolkit for turn-based, two-player games. Describe your game as a value type, and AdversarialKit finds the best move with minimax search and alpha-beta pruning.

- Plain Swift, no dependencies, works on any platform Swift runs on
- Value-type game models: the search never mutates shared state
- Swift 6 ready (`Sendable` throughout)
- Includes ready-made Tic-Tac-Toe and Nim models

## Installation

Add the package in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tkausch/AdversarialKit.git", branch: "main")
],
targets: [
    .target(name: "MyGame", dependencies: ["AdversarialKit"])
]
```

## Usage

### 1. Describe your game

Conform to `GameModel` (a struct works best), with your own `ModelMove` type:

```swift
import AdversarialKit

struct Place: ModelMove { let index: Int }

struct MyGame: GameModel {
    var activePlayer: ModelPlayer { ... }   // .first or .second
    var outcome: Outcome? { ... }   // nil while running; .win(player) or .draw when over
    func legalMoves() -> [Place] { ... }   // any Sequence works; lazy ones avoid allocations
    func applying(_ move: Place) -> MyGame { ... }  // return a new state
}
```

### 2. Ask for the best move

```swift
let strategist = MinimaxStrategist<MyGame>()
if let move = await strategist.bestMove(for: game) {
    game = game.applying(move)
}
```

`bestMove(for:)` is `async`. The search always runs concurrently, off the calling executor, so it never blocks the caller. It can't be cancelled; use `maxDepth` (below) to bound how long it takes.

### 3. Limit depth for bigger games

For games too large to search to the end, set a depth limit and supply a heuristic:

```swift
let strategist = MinimaxStrategist<MyGame>(maxDepth: 6) { model, player in
    // Rate the position for `player`; higher is better.
    score(of: model, for: player)
}
```

### Monte Carlo tree search

For games that are too big to search exhaustively and hard to score with a heuristic, use `MonteCarloStrategist`. It plays many random games and picks the most promising move. More `iterations` play stronger and take longer. Set a `seed` for reproducible results.

```swift
let strategist = MonteCarloStrategist<MyGame>(iterations: 5_000)
let move = await strategist.bestMove(for: game)
```

## API overview

| Type | Purpose |
| --- | --- |
| `GameModel` | Your game: active player, outcome, legal moves, applying a move |
| `ModelPlayer` | The two players: `.first` and `.second` |
| `ModelMove` | A legal action (`Hashable`, `Sendable`) |
| `Outcome` | `.win(player)` or `.draw` |
| `Strategist` | Protocol for anything that picks a move |
| `MinimaxStrategist` | Minimax with alpha-beta pruning, optional depth limit and heuristic |
| `MonteCarloStrategist` | Monte Carlo tree search: plays random games, needs no heuristic |
| `TicTacToeModel`, `NimModel` | Ready-made games |

## Included games

`TicTacToeModel` and `NimModel` are ready-made games that double as references for writing your own. Two perfect players always draw at Tic-Tac-Toe:

```swift
let strategist = MinimaxStrategist<TicTacToeModel>()
var game = TicTacToeModel()
while let move = await strategist.bestMove(for: game) {
    game = game.applying(move)
}
// game.outcome == .draw
```

In Nim, players take 1 to `maxTake` stones from a pile and whoever takes the last stone wins:

```swift
var game = NimModel(stones: 10, maxTake: 3)
let move = await strategist.bestMove(for: game)   // take 2, leaving a multiple of 4
```

## Tests

```sh
swift test
```
