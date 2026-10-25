/// Lets two strategists play against each other.
///
/// `Arena` drives a ``GameModel`` turn by turn, asking whichever ``Strategist``
/// owns the active player for its move, until the game ends.
///
/// ```swift
/// let arena = Arena<TicTacToeModel>()
/// let final = await arena.playGame(
///     MinimaxStrategist<TicTacToeModel>(),
///     against: MonteCarloStrategist<TicTacToeModel>(iterations: 1_000),
///     startingFrom: TicTacToeModel()
/// )
/// print(final.outcome!)
/// ```
///
/// ## Comparing strategists fairly
///
/// A single game can be decided by who happens to move first. Play a
/// ``match(_:against:rounds:startingFrom:)`` instead, which alternates who
/// starts and tallies the results:
///
/// ```swift
/// let result = await arena.match(
///     MinimaxStrategist<TicTacToeModel>(),
///     against: MonteCarloStrategist<TicTacToeModel>(iterations: 1_000),
///     rounds: 20,
///     startingFrom: TicTacToeModel()
/// )
/// print(result.firstWins, result.secondWins, result.draws)
/// ```
///
/// ## Topics
///
/// ### Creating an Arena
/// - ``init()``
///
/// ### Playing
/// - ``playGame(_:against:startingFrom:)``
/// - ``match(_:against:rounds:startingFrom:)``
/// - ``MatchResult``
public struct Arena<Model: GameModel>: Sendable {
    /// Creates an arena for `Model`.
    public init() {}

    /// Plays a single game to its conclusion.
    ///
    /// `first` moves whenever ``GameModel/activePlayer`` is ``ModelPlayer/first``,
    /// and `second` moves whenever it is ``ModelPlayer/second``. `model` need
    /// not have ``ModelPlayer/first`` to move first; play simply starts from
    /// whichever player it names.
    ///
    /// - Parameters:
    ///   - first: The strategist that moves for ``ModelPlayer/first``.
    ///   - second: The strategist that moves for ``ModelPlayer/second``.
    ///   - model: The state to start the game from.
    /// - Returns: The terminal state the game ended in.
    public func playGame<First: Strategist, Second: Strategist>(
        _ first: First,
        against second: Second,
        startingFrom model: Model
    ) async -> Model where First.Model == Model, Second.Model == Model {
        var game = model
        while let move = await (game.activePlayer == .first ? first : second).bestMove(for: game) {
            game = game.applying(move)
        }
        return game
    }

    /// Plays several games, alternating who starts, and tallies the results.
    ///
    /// Alternating cancels out the first-move advantage: over `rounds` games,
    /// `first` and `second` each start half of them. If `rounds` is odd,
    /// `first` starts one extra game.
    ///
    /// - Parameters:
    ///   - first: One of the two strategists being compared.
    ///   - second: The other strategist being compared.
    ///   - rounds: How many games to play. Must be positive.
    ///   - model: The state each game starts from, before swapping who moves first.
    /// - Returns: How many games `first` won, how many `second` won, and how many were drawn.
    public func match<First: Strategist, Second: Strategist>(
        _ first: First,
        against second: Second,
        rounds: Int,
        startingFrom model: Model
    ) async -> MatchResult where First.Model == Model, Second.Model == Model {
        var result = MatchResult()
        for round in 0..<rounds {
            let firstStarts = round.isMultiple(of: 2)
            let final = if firstStarts {
                await playGame(first, against: second, startingFrom: model)
            } else {
                await playGame(second, against: first, startingFrom: model)
            }
            switch final.outcome {
            case .win(let winner):
                if (winner == .first) == firstStarts {
                    result.firstWins += 1
                } else {
                    result.secondWins += 1
                }
            case .draw, nil:
                result.draws += 1
            }
        }
        return result
    }
}
