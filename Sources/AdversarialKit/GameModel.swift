/// The rules and current state of a turn-based game for two or more players.
///
/// Conform a value type, usually a struct, to describe your game. A strategist
/// such as ``MinimaxStrategist`` explores the game by repeatedly calling
/// ``applying(_:)`` on copies of the state, so the model must never change
/// shared state. Keep the stored state small so that copies stay cheap.
///
/// ## Conforming to GameModel
///
/// Provide a move type and four members:
///
/// ```swift
/// struct Nim: GameModel {
///     struct Take: ModelMove { let count: Int }
///
///     var stones = 10
///     var activePlayer = ModelPlayer.first
///
///     var outcome: Outcome? {
///         // Whoever takes the last stone wins.
///         stones == 0 ? .win(activePlayer.opponent) : nil
///     }
///
///     func legalMoves() -> [Take] {
///         (1...min(3, stones)).map(Take.init)
///     }
///
///     func applying(_ move: Take) -> Nim {
///         var next = self
///         next.stones -= move.count
///         next.activePlayer = activePlayer.opponent
///         return next
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Associated Types
/// - ``Move``
/// - ``Moves``
///
/// ### Reading the State
/// - ``activePlayer``
/// - ``outcome``
/// - ``isTerminal``
///
/// ### Playing the Game
/// - ``legalMoves()``
/// - ``applying(_:)``
///
/// ### Guiding a Depth-Limited Search
/// - ``heuristicValue(for:)``
public protocol GameModel: Sendable {
    /// The type that describes a single action.
    associatedtype Move: ModelMove

    /// The sequence returned by ``legalMoves()``.
    ///
    /// Returning an array is fine. For games with many moves per position,
    /// return a lazy sequence instead, which avoids allocating a new array at
    /// every node of the search.
    associatedtype Moves: Sequence where Moves.Element == Move

    /// The player whose turn it is.
    var activePlayer: ModelPlayer { get }

    /// The final result, or `nil` while the game is still running.
    ///
    /// Return a non-`nil` value as soon as the game can't continue, for example
    /// when a player has won or the board is full.
    var outcome: Outcome? { get }

    /// All moves that `activePlayer` may play in the current state.
    ///
    /// The result is empty if and only if the game is over, that is, if
    /// ``outcome`` is not `nil`. A game where a player may have to pass should
    /// model passing as a move.
    ///
    /// - Complexity: This is called at every node of the search, so keep it
    ///   cheap.
    func legalMoves() -> Moves

    /// Returns the state that results from playing `move`.
    ///
    /// The receiver must not change. The returned state has the next player
    /// as its ``activePlayer``.
    ///
    /// - Parameter move: A move taken from ``legalMoves()``. Passing any other
    ///   move is a programmer error.
    /// - Returns: A new state with `move` applied.
    func applying(_ move: Move) -> Self

    /// A rating of this unfinished position for `player`, or `nil` if the model offers none.
    ///
    /// A depth-limited ``MinimaxStrategist`` calls this where its search stops.
    /// Return a higher number for a position that is better for `player`, and
    /// the negation for the opponent. Keep the magnitude well below
    /// ``MinimaxStrategist/winScore`` so that a real win always beats a
    /// good-looking position.
    ///
    /// The default implementation returns `nil`. Implement it only for games
    /// that are too large to search to the end.
    ///
    /// - Parameter player: The player the rating is for.
    /// - Complexity: This is called at the leaves of the search, so keep it cheap.
    func heuristicValue(for player: ModelPlayer) -> Int?
}

extension GameModel {
    /// Offers no heuristic.
    public func heuristicValue(for player: ModelPlayer) -> Int? { nil }

    /// A Boolean value that indicates whether the game is over.
    ///
    /// This is `true` exactly when ``outcome`` is not `nil`.
    public var isTerminal: Bool { outcome != nil }
}
