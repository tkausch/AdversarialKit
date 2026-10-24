/// A move in Nim: taking one or more stones from the pile.
public struct NimMove: ModelMove {
    /// The number of stones to take.
    public let count: Int

    /// Creates a move that takes `count` stones.
    public init(count: Int) { self.count = count }
}

/// A ready-made ``GameModel`` for the game of Nim with a single pile.
///
/// Players take turns removing between one and ``maxTake`` stones from the
/// pile. Whoever takes the last stone wins. The game is solved: the player to
/// move wins unless ``stones`` is a multiple of `maxTake + 1`, in which case
/// the opponent wins with correct play.
///
/// ```swift
/// let strategist = MinimaxStrategist<NimModel>()
/// var game = NimModel(stones: 10)
/// while let move = await strategist.bestMove(for: game) {
///     game = game.applying(move)
/// }
/// // game.outcome == .win(.first)
/// ```
public struct NimModel: GameModel {
    public typealias Move = NimMove

    /// The number of stones left in the pile.
    public private(set) var stones: Int

    /// The most stones a player may take in one turn.
    public let maxTake: Int

    /// The player who takes the next stones.
    public private(set) var activePlayer: ModelPlayer

    /// Creates a game.
    ///
    /// - Parameters:
    ///   - stones: The initial size of the pile, at least 0. The default is 10.
    ///   - maxTake: The most stones a player may take in one turn, at least 1.
    ///     The default is 3.
    ///   - activePlayer: The player who moves first. The default is `first`.
    public init(stones: Int = 10, maxTake: Int = 3, activePlayer: ModelPlayer = .first) {
        precondition(stones >= 0, "The pile can't have a negative number of stones")
        precondition(maxTake >= 1, "A player must be able to take at least one stone")
        self.stones = stones
        self.maxTake = maxTake
        self.activePlayer = activePlayer
    }

    /// A win for the player who took the last stone, or `nil` while stones remain.
    ///
    /// The player who took the last stone is the opponent of the active player,
    /// because the turn passes after every move.
    public var outcome: Outcome? {
        stones == 0 ? .win(activePlayer.opponent) : nil
    }

    /// Taking 1 up to `maxTake` stones, but never more than are left. Empty once
    /// the pile is gone.
    public func legalMoves() -> LazyMapSequence<Range<Int>, NimMove> {
        (1..<(min(maxTake, stones) + 1)).lazy.map(NimMove.init(count:))
    }

    /// Returns the game after the active player takes `move.count` stones.
    ///
    /// - Precondition: `move.count` is between 1 and `min(maxTake, stones)`.
    public func applying(_ move: NimMove) -> NimModel {
        precondition((1...max(1, min(maxTake, stones))).contains(move.count) && stones > 0, "Illegal move")
        var next = self
        next.stones -= move.count
        next.activePlayer = activePlayer.opponent
        return next
    }
}
