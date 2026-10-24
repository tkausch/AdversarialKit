/// The final result of a finished game.
///
/// ``GameModel/outcome`` is `nil` while a game is still running and holds an
/// `Outcome` once it is over.
///
/// ```swift
/// switch game.outcome {
/// case .win(let player)?: print("\(player) wins")
/// case .draw?:            print("Draw")
/// case nil:               print("Still playing")
/// }
/// ```
public enum Outcome: Hashable, Sendable {
    /// The given player won.
    case win(ModelPlayer)

    /// Nobody won and no moves are left.
    case draw
}
