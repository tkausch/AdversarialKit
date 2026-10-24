/// Depth-limited minimax search with alpha-beta pruning.
///
/// Scores are from the point of view of the player who is active at the root.
/// Terminal wins score `±winScore` (adjusted by depth so faster wins and slower
/// losses are preferred); draws score 0. At the depth limit, `evaluate` is used
/// to rate non-terminal positions.
public struct AKMinMaxStrategist<Model: AKGameModel>: AKStrategist {
    public static var winScore: Int { 1_000_000 }

    /// Maximum search depth in plies. `nil` searches to the end of the game.
    public let maxDepth: Int?

    /// Heuristic rating of a non-terminal position for `player`; higher is better.
    public let evaluate: @Sendable (Model, Model.Player) -> Int

    public init(
        maxDepth: Int? = nil,
        evaluate: @escaping @Sendable (Model, Model.Player) -> Int = { _, _ in 0 }
    ) {
        self.maxDepth = maxDepth
        self.evaluate = evaluate
    }

    public func bestMove(for model: Model) -> Model.Move? {
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

    private func search(_ model: Model, root: Model.Player, depth: Int, alpha: Int, beta: Int) -> Int {
        if let outcome = model.outcome {
            switch outcome {
            case .draw: return 0
            case .win(let winner): return winner == root ? Self.winScore - depth : depth - Self.winScore
            }
        }
        if let maxDepth, depth >= maxDepth { return evaluate(model, root) }

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
