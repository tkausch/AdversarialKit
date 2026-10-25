/// The tally of games played in an ``Arena/match(_:against:rounds:startingFrom:)``.
public struct MatchResult: Hashable, Sendable {
    /// The number of games the first strategist won.
    ///
    /// This counts wins regardless of whether the strategist moved first or
    /// second in a given game.
    public var firstWins = 0

    /// The number of games the second strategist won.
    public var secondWins = 0

    /// The number of games that ended in a draw.
    public var draws = 0
}
