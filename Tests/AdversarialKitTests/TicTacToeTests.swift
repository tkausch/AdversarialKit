import Testing
@testable import AdversarialKit

@Suite struct MinimaxTicTacToeTests {
    let strategist = MinimaxStrategist<TicTacToeModel>()

    @Test func selfPlayIsDraw() async {
        var game = TicTacToeModel()
        while let move = await strategist.bestMove(for: game) { game = game.applying(move) }
        #expect(game.outcome == .draw)
    }

    @Test func takesWinningMove() async {
        var game = TicTacToeModel()
        for i in [0, 3, 1, 4] { game = game.applying(.init(index: i)) } // X: 0,1  O: 3,4
        #expect(await strategist.bestMove(for: game) == .init(index: 2))
    }

    @Test func blocksOpponent() async {
        var game = TicTacToeModel()
        for i in [0, 4, 1] { game = game.applying(.init(index: i)) } // X threatens 2
        #expect(await strategist.bestMove(for: game) == .init(index: 2))
    }

    @Test func noMoveWhenFinished() async {
        var game = TicTacToeModel()
        for i in [0, 3, 1, 4, 2] { game = game.applying(.init(index: i)) }
        #expect(game.outcome == .win(.first))
        #expect(await strategist.bestMove(for: game) == nil)
    }
}
