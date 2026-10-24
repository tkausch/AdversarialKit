import Testing
@testable import AdversarialKit

@Suite struct MinMaxTicTacToeTests {
    let strategist = AKMinMaxStrategist<AKTicTacToeModel>()

    @Test func selfPlayIsDraw() {
        var game = AKTicTacToeModel()
        while let move = strategist.bestMove(for: game) { game = game.applying(move) }
        #expect(game.outcome == .draw)
    }

    @Test func takesWinningMove() {
        var game = AKTicTacToeModel()
        for i in [0, 3, 1, 4] { game = game.applying(.init(index: i)) } // X: 0,1  O: 3,4
        #expect(strategist.bestMove(for: game) == .init(index: 2))
    }

    @Test func blocksOpponent() {
        var game = AKTicTacToeModel()
        for i in [0, 4, 1] { game = game.applying(.init(index: i)) } // X threatens 2
        #expect(strategist.bestMove(for: game) == .init(index: 2))
    }

    @Test func noMoveWhenFinished() {
        var game = AKTicTacToeModel()
        for i in [0, 3, 1, 4, 2] { game = game.applying(.init(index: i)) }
        #expect(game.outcome == .win(.x))
        #expect(strategist.bestMove(for: game) == nil)
    }
}
