import Testing
@testable import AdversarialKit

@Suite struct ArenaTests {
    let arena = Arena<NimModel>()

    @Test func playGameEndsInATerminalState() async {
        let final = await arena.playGame(
            MinimaxStrategist<NimModel>(),
            against: MinimaxStrategist<NimModel>(),
            startingFrom: NimModel(stones: 10)
        )
        #expect(final.isTerminal)
        #expect(final.outcome == .win(.first))
    }

    @Test func perfectPlayersAlwaysDrawTicTacToe() async {
        let final = await Arena<TicTacToeModel>().playGame(
            MinimaxStrategist<TicTacToeModel>(),
            against: MinimaxStrategist<TicTacToeModel>(),
            startingFrom: TicTacToeModel()
        )
        #expect(final.outcome == .draw)
    }

    @Test func matchTalliesAllRounds() async {
        let result = await arena.match(
            MinimaxStrategist<NimModel>(),
            against: MinimaxStrategist<NimModel>(),
            rounds: 5,
            startingFrom: NimModel(stones: 10)
        )
        #expect(result.firstWins + result.secondWins + result.draws == 5)
    }

    @Test func alternatingStartGivesEachSideAWin() async {
        // With perfect play from 10 stones, whoever starts wins Nim, and the
        // strategists swap who starts each round.
        let result = await arena.match(
            MinimaxStrategist<NimModel>(),
            against: MinimaxStrategist<NimModel>(),
            rounds: 2,
            startingFrom: NimModel(stones: 10)
        )
        #expect(result.firstWins == 1)
        #expect(result.secondWins == 1)
    }
}
