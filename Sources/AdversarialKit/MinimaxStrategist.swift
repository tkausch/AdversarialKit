/// A strategist that plays with minimax search and alpha-beta pruning.
///
/// Minimax assumes that both players play as well as they can. It looks ahead
/// through the game tree, assumes that the opponent picks the reply that is
/// worst for you, and chooses the move that leaves you best off. Alpha-beta
/// pruning skips branches that can't change the result, which gives the same
/// answer as a full search in much less time.
///
/// ## Searching to the end of the game
///
/// With no depth limit the strategist plays perfectly. This is practical for
/// small games such as Tic-Tac-Toe:
///
/// ```swift
/// let strategist = MinimaxStrategist<MyGame>()
/// let move = await strategist.bestMove(for: game)
/// ```
///
/// ## Limiting the depth
///
/// Most games are too large to search to the end. Set ``maxDepth`` and let the
/// model rate the positions where the search stops by implementing
/// ``GameModel/heuristicValue(for:)``:
///
/// ```swift
/// let strategist = MinimaxStrategist<MyGame>(maxDepth: 6)
/// ```
///
/// To override the model's heuristic, or to supply one for a model that has
/// none, pass an ``evaluate`` closure:
///
/// ```swift
/// let strategist = MinimaxStrategist<MyGame>(maxDepth: 6) { game, player in
///     game.material(for: player) - game.material(for: player.opponent)
/// }
/// ```
///
/// Without either, every unfinished position scores 0, so a depth-limited
/// strategist can only find forced wins and losses within its horizon.
///
/// ## How scores work
///
/// Scores are from the point of view of the player who is active at the root of
/// the search. A win scores ``winScore`` minus the number of plies it takes, and
/// a loss scores the negative of that. The strategist therefore prefers faster
/// wins and slower losses. A draw scores 0.
///
/// When several moves have the same score, the one that ``GameModel/legalMoves()``
/// returns first is chosen.
///
/// ## Topics
///
/// ### Creating a Strategist
/// - ``init(maxDepth:evaluate:)``
///
/// ### Configuring the Search
/// - ``maxDepth``
/// - ``evaluate``
/// - ``winScore``
///
/// ### Choosing a Move
/// - `bestMove(for:)`
/// - `bestMove(for:)`
public struct MinimaxStrategist<Model: GameModel>: Strategist {
    /// The score of a win that takes no moves.
    ///
    /// Real wins score slightly less, by one point per ply, and losses score the
    /// negative. Heuristic scores returned by ``evaluate`` should stay well
    /// below this value so that a real win always beats a good-looking position.
    public static var winScore: Int { 1_000_000 }

    /// The maximum search depth in plies, where one ply is one move by one player.
    ///
    /// `nil` searches to the end of the game. A value of 1 looks only at the
    /// strategist's own moves.
    public let maxDepth: Int?

    /// A heuristic that overrides ``GameModel/heuristicValue(for:)`` when the depth limit is reached.
    ///
    /// The closure receives the position and the player the score is for, and
    /// returns a higher number for a better position for that player. It is only
    /// called when ``maxDepth`` is not `nil`. When it is `nil`, the model's own
    /// heuristic is used, and 0 if the model has none.
    public let evaluate: (@Sendable (Model, ModelPlayer) -> Int)?

    /// Creates a strategist.
    ///
    /// - Parameters:
    ///   - maxDepth: The maximum search depth in plies, or `nil` to search to
    ///     the end of the game. The default is `nil`.
    ///   - evaluate: A heuristic that rates positions at the depth limit. The
    ///     default `nil` uses ``GameModel/heuristicValue(for:)``.
    public init(
        maxDepth: Int? = nil,
        evaluate: (@Sendable (Model, ModelPlayer) -> Int)? = nil
    ) {
        self.maxDepth = maxDepth
        self.evaluate = evaluate
    }

    /// Returns the best move for the active player of `model`.
    ///
    /// The search always runs concurrently, off the caller's executor, so the
    /// caller is never blocked while it thinks. It can't be cancelled: it runs
    /// to completion even if the surrounding task is cancelled, so use
    /// ``maxDepth`` to bound how long it takes.
    ///
    /// - Parameter model: The current state of the game.
    /// - Returns: The best move, or `nil` if the game is over.
    /// - Complexity: O(*b*<sup>*d*</sup>) in the worst case, where *b* is the
    ///   number of legal moves per position and *d* is the search depth.
    ///   Alpha-beta pruning reduces this to about O(*b*<sup>*d*/2</sup>) when
    ///   the best moves are listed first.
    public func bestMove(for model: Model) async -> Model.Move? {
        await Task.detached { bestMove(searching: model) }.value
    }

    private func bestMove(searching model: Model) -> Model.Move? {
        let player = model.activePlayer
        var best: Model.Move?
        var alpha = Int.min
        for move in model.legalMoves() {
            let score = search(model.applying(move), root: player, depth: 1, alpha: alpha, beta: Int.max)
            if best == nil || score > alpha {
                best = move
                alpha = max(alpha, score)
            }
        }
        return best
    }

    private func search(_ model: Model, root: ModelPlayer, depth: Int, alpha: Int, beta: Int) -> Int {
        if let outcome = model.outcome {
            switch outcome {
            case .draw: return 0
            case .win(let winner): return winner == root ? Self.winScore - depth : depth - Self.winScore
            }
        }
        if let maxDepth, depth >= maxDepth { return evaluate?(model, root) ?? model.heuristicValue(for: root) ?? 0 }

        var alpha = alpha, beta = beta
        if model.activePlayer == root {
            var value = Int.min
            for move in model.legalMoves() {
                value = max(value, search(model.applying(move), root: root, depth: depth + 1, alpha: alpha, beta: beta))
                alpha = max(alpha, value)
                if alpha >= beta { break }
            }
            return value
        } else {
            var value = Int.max
            for move in model.legalMoves() {
                value = min(value, search(model.applying(move), root: root, depth: depth + 1, alpha: alpha, beta: beta))
                beta = min(beta, value)
                if alpha >= beta { break }
            }
            return value
        }
    }
}
