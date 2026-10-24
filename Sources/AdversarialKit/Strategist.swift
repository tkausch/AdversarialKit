/// A decision procedure that picks a move for the active player of a game.
///
/// Conform to `Strategist` to add your own way of choosing moves, such as a
/// Monte Carlo search or a hand-written opening book. ``MinimaxStrategist`` is
/// the strategist this package provides.
///
/// ```swift
/// let strategist = MinimaxStrategist<MyGame>()
/// if let move = await strategist.bestMove(for: game) {
///     game = game.applying(move)
/// }
/// ```
///
/// ## Topics
///
/// ### Choosing a Move
/// - `bestMove(for:)`
public protocol Strategist: Sendable {
    /// The game this strategist plays.
    associatedtype Model: GameModel

    /// Returns the best move for the active player of `model`.
    ///
    /// Strategists search concurrently, so the caller is never blocked while a
    /// move is being chosen. The search can't be cancelled.
    ///
    /// - Parameter model: The current state of the game.
    /// - Returns: The chosen move, or `nil` if the game is over and there is no
    ///   move to play.
    func bestMove(for model: Model) async -> Model.Move?
}
