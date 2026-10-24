/// Chooses a move for the active player of a game model.
public protocol AKStrategist: Sendable {
    associatedtype Model: AKGameModel

    /// The best move for `model.activePlayer`, or `nil` if the game is over.
    func bestMove(for model: Model) -> Model.Move?
}
