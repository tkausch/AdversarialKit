/// The final result of a finished game.
public enum AKOutcome<Player: AKModelPlayer>: Hashable, Sendable {
    case win(Player)
    case draw
}
