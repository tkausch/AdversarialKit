/// One of the two participants in a game.
///
/// ``first`` is the player who moves first in a new game by convention, but a
/// ``GameModel`` is free to start with either player.
///
/// ```swift
/// let next = game.activePlayer.opponent
/// ```
///
/// - SeeAlso: ``GameModel/activePlayer``, ``Outcome``
public enum ModelPlayer: Hashable, Sendable, CaseIterable {
    /// The player who conventionally moves first.
    case first

    /// The player who conventionally moves second.
    case second

    /// The other player.
    public var opponent: ModelPlayer {
        switch self {
        case .first: .second
        case .second: .first
        }
    }
}
