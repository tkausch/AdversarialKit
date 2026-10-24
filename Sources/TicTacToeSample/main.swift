import AdversarialKit

// Two perfect minimax players: Tic-Tac-Toe is a draw with optimal play.
let strategist = AKMinMaxStrategist<AKTicTacToeModel>()
var game = AKTicTacToeModel()

print(game, "\n")
while let move = strategist.bestMove(for: game) {
    print("\(game.activePlayer) plays \(move.index)")
    game = game.applying(move)
    print(game, "\n")
}

switch game.outcome {
case .win(let player)?: print("\(player) wins")
default: print("Draw")
}
