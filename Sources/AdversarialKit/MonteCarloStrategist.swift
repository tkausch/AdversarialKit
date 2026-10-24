import Foundation

/// A strategist that plays with Monte Carlo tree search.
///
/// Instead of looking at every position like ``MinimaxStrategist``, this
/// strategist plays many random games and learns which first moves lead to wins
/// most often. It needs no heuristic evaluation function, which makes it a good
/// fit for games that are too large to search exhaustively and hard to score by
/// hand.
///
/// Each iteration of the search has four steps:
///
/// 1. **Selection.** Walk down the tree from the current position, always
///    choosing the child with the best UCT score, which balances moves that have
///    worked well against moves that have been tried rarely.
/// 2. **Expansion.** Add one new child for a move not tried yet.
/// 3. **Simulation.** Play random moves from the new position until the game ends.
/// 4. **Backpropagation.** Record the result for every position on the path.
///
/// After ``iterations`` rounds, the strategist plays the move that was visited
/// most often.
///
/// ```swift
/// let strategist = MonteCarloStrategist<TicTacToeModel>(iterations: 2_000)
/// if let move = await strategist.bestMove(for: game) {
///     game = game.applying(move)
/// }
/// ```
///
/// ## Strength and speed
///
/// More iterations make the strategist stronger and slower. The cost is linear
/// in ``iterations``, so unlike a minimax search, the time to think doesn't grow
/// exponentially with the size of the game. The result is a statistical
/// estimate, though, and the strategist can miss a forced win or loss that
/// ``MinimaxStrategist`` always finds.
///
/// ## Reproducible results
///
/// The simulations use random numbers, so two runs can choose different moves.
/// Pass a ``seed`` to get the same move every time, for example in tests.
///
/// ## Topics
///
/// ### Creating a Strategist
/// - ``init(iterations:explorationConstant:seed:)``
///
/// ### Configuring the Search
/// - ``iterations``
/// - ``explorationConstant``
/// - ``seed``
///
/// ### Choosing a Move
/// - `bestMove(for:)`
public struct MonteCarloStrategist<Model: GameModel>: Strategist {
    /// The number of search rounds. More rounds play stronger and take longer.
    public let iterations: Int

    /// The weight of exploration in the UCT formula.
    ///
    /// Higher values favour moves that have been tried rarely, and lower values
    /// favour the moves that have won most often so far. The default, √2, is the
    /// textbook value for results between 0 and 1.
    public let explorationConstant: Double

    /// The seed of the random number generator, or `nil` for a different seed on
    /// every search.
    public let seed: UInt64?

    /// Creates a strategist.
    ///
    /// - Parameters:
    ///   - iterations: The number of search rounds, at least 1. The default is 10,000.
    ///   - explorationConstant: The weight of exploration in the UCT formula. The
    ///     default is √2.
    ///   - seed: A seed that makes the search reproducible. The default, `nil`,
    ///     seeds the search randomly.
    public init(
        iterations: Int = 10_000,
        explorationConstant: Double = 2.0.squareRoot(),
        seed: UInt64? = nil
    ) {
        precondition(iterations >= 1, "At least one iteration is required")
        self.iterations = iterations
        self.explorationConstant = explorationConstant
        self.seed = seed
    }

    /// Returns the best move for the active player of `model`.
    ///
    /// The search always runs concurrently, off the caller's executor, and can't
    /// be cancelled. Use ``iterations`` to bound how long it takes.
    ///
    /// - Parameter model: The current state of the game.
    /// - Returns: The most visited move, or `nil` if the game is over.
    /// - Complexity: O(``iterations`` × *d*), where *d* is the length of a random
    ///   game, plus the memory for one tree node per iteration.
    public func bestMove(for model: Model) async -> Model.Move? {
        await Task.detached { bestMove(searching: model) }.value
    }

    /// One position in the search tree.
    private struct Node {
        let state: Model
        /// The move that led here from the parent, `nil` at the root.
        let move: Model.Move?
        /// The player who played `move`, `nil` at the root.
        let mover: ModelPlayer?
        let parent: Int?
        var children: [Int] = []
        var untried: [Model.Move]
        var visits = 0
        /// Sum of results for `mover`: 1 per win, 0.5 per draw.
        var reward = 0.0
    }

    private func bestMove(searching model: Model) -> Model.Move? {
        guard model.outcome == nil else { return nil }
        let rootMoves = Array(model.legalMoves())
        guard rootMoves.count > 1 else { return rootMoves.first }

        var random = SplitMix64(seed: seed ?? .random(in: .min ... .max))
        var nodes = [Node(state: model, move: nil, mover: nil, parent: nil, untried: rootMoves)]
        nodes.reserveCapacity(iterations + 1)

        for _ in 0..<iterations {
            // Selection: descend while every move of the node has been tried.
            var current = 0
            while nodes[current].untried.isEmpty, !nodes[current].children.isEmpty {
                current = selectChild(of: current, in: nodes)
            }

            // Expansion: try one new move.
            if !nodes[current].untried.isEmpty {
                let pick = Int.random(in: 0..<nodes[current].untried.count, using: &random)
                let move = nodes[current].untried.swapRemove(at: pick)
                let state = nodes[current].state.applying(move)
                nodes.append(Node(
                    state: state,
                    move: move,
                    mover: nodes[current].state.activePlayer,
                    parent: current,
                    untried: state.outcome == nil ? Array(state.legalMoves()) : []
                ))
                nodes[current].children.append(nodes.count - 1)
                current = nodes.count - 1
            }

            // Simulation and backpropagation.
            let outcome = playOut(nodes[current].state, using: &random)
            var cursor: Int? = current
            while let index = cursor {
                nodes[index].visits += 1
                if let mover = nodes[index].mover {
                    switch outcome {
                    case .win(let winner): nodes[index].reward += winner == mover ? 1 : 0
                    case .draw: nodes[index].reward += 0.5
                    }
                }
                cursor = nodes[index].parent
            }
        }

        // The most visited child is more robust than the one with the best average.
        var best: Int?
        for child in nodes[0].children where best == nil || nodes[child].visits > nodes[best!].visits {
            best = child
        }
        return best.flatMap { nodes[$0].move }
    }

    /// The child of `parent` with the highest UCT score.
    private func selectChild(of parent: Int, in nodes: [Node]) -> Int {
        let logVisits = log(Double(nodes[parent].visits))
        var best = nodes[parent].children[0]
        var bestScore = -Double.infinity
        for child in nodes[parent].children {
            let visits = Double(nodes[child].visits)
            let score = nodes[child].reward / visits + explorationConstant * (logVisits / visits).squareRoot()
            if score > bestScore {
                best = child
                bestScore = score
            }
        }
        return best
    }

    /// Plays uniformly random moves until the game ends.
    private func playOut(_ state: Model, using random: inout SplitMix64) -> Outcome {
        var state = state
        while state.outcome == nil {
            // Reservoir sampling picks a random move without allocating an array.
            var chosen: Model.Move?
            var seen = 0
            for move in state.legalMoves() {
                seen += 1
                if Int.random(in: 0..<seen, using: &random) == 0 { chosen = move }
            }
            guard let chosen else { return .draw }
            state = state.applying(chosen)
        }
        return state.outcome ?? .draw
    }
}

extension Array {
    /// Removes the element at `index` by swapping in the last element. O(1).
    fileprivate mutating func swapRemove(at index: Int) -> Element {
        swapAt(index, count - 1)
        return removeLast()
    }
}

/// A small, fast, seedable random number generator.
private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
