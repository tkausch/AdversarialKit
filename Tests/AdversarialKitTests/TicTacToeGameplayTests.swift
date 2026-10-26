import Testing
@testable import AdversarialKit

@Suite struct TicTacToeGameplayTests {
    @Test func perfectPlayersPlayACompleteGameToStandardOutput() async {
        let strategist = MinimaxStrategist<TicTacToeModel>()
        var game = TicTacToeModel()
        var moveNumber = 0

        print("Tic-Tac-Toe: minimax (X) vs minimax (O)\n")
        print(game, terminator: "\n\n")

        while let move = await strategist.bestMove(for: game) {
            let player = game.activePlayer == .first ? "X" : "O"
            game = game.applying(move)
            moveNumber += 1
            print("Move \(moveNumber): \(player) -> cell \(move.index)")
            print(game, terminator: "\n\n")
        }

        print("Result: \(game.outcome == .draw ? "draw" : "win")")
        #expect(game.outcome == .draw)
        #expect(moveNumber == 9)
    }
}
