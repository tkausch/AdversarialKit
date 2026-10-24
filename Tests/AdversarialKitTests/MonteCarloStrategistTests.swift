import Testing
@testable import AdversarialKit

@Suite struct MonteCarloStrategistTests {
    let strategist = MonteCarloStrategist<TicTacToeModel>(iterations: 3_000, seed: 42)

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
        #expect(await strategist.bestMove(for: game) == nil)
    }

    @Test func playsTheOnlyMove() async {
        let nim = MonteCarloStrategist<NimModel>(iterations: 10, seed: 1)
        #expect(await nim.bestMove(for: NimModel(stones: 1)) == .init(count: 1))
    }

    @Test func findsNimStrategy() async {
        // 6 stones with up to 3 per turn: take 2 to leave a multiple of 4.
        let nim = MonteCarloStrategist<NimModel>(iterations: 3_000, seed: 7)
        #expect(await nim.bestMove(for: NimModel(stones: 6)) == .init(count: 2))
    }

    @Test func sameSeedGivesSameMove() async {
        let game = TicTacToeModel()
        let a = MonteCarloStrategist<TicTacToeModel>(iterations: 500, seed: 1)
        let b = MonteCarloStrategist<TicTacToeModel>(iterations: 500, seed: 1)
        #expect(await a.bestMove(for: game) == b.bestMove(for: game))
    }

    @Test(arguments: [ModelPlayer.first, .second])
    func neverLosesToMinimax(monteCarloPlays side: ModelPlayer) async {
        let minimax = MinimaxStrategist<TicTacToeModel>()
        var game = TicTacToeModel()
        while game.outcome == nil {
            let move = game.activePlayer == side
                ? await strategist.bestMove(for: game)
                : await minimax.bestMove(for: game)
            game = game.applying(move!)
        }
        #expect(game.outcome != .win(side.opponent))
    }
}
