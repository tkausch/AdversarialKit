/// A single action a player can take.
///
/// A move only needs to identify an action, such as a board position or a
/// pair of squares. It doesn't have to carry the whole game state, because
/// ``GameModel/applying(_:)`` takes care of that.
///
/// ```swift
/// struct Place: ModelMove { let index: Int }
/// ```
///
/// - SeeAlso: ``GameModel/legalMoves()``
public protocol ModelMove: Hashable, Sendable {}
