/// The game itself. Implement as a struct: `applying(_:)` returns a new state,
/// so the search never mutates shared state and copies are cheap.
public protocol AKGameModel: Sendable {
    associatedtype Player: AKModelPlayer
    associatedtype Move: AKModelMove

    /// The player whose turn it is.
    var activePlayer: Player { get }

    /// `nil` while the game is running, otherwise the final result.
    var outcome: AKOutcome<Player>? { get }

    /// All legal moves for `activePlayer`. Empty only if the game is over.
    func legalMoves() -> [Move]

    /// The state after `move` has been played.
    func applying(_ move: Move) -> Self
}

extension AKGameModel {
    public var isTerminal: Bool { outcome != nil }
}
