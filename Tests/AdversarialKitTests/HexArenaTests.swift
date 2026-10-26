import Testing
@testable import AdversarialKit

@Suite struct HexArenaTests {
    @Test func monteCarloPlaysAgainstMinimaxOnHex() async {
        let monteCarlo = MonteCarloStrategist<HexModel>(iterations: 2_000, seed: 1)
        let minimax = MinimaxStrategist<HexModel>(maxDepth: 2)

        var game = HexModel(size: 5)
        var moveNumber = 0

        print("Hex 5x5: Monte Carlo (X) vs minimax depth 2 (O)\n")
        print(game, terminator: "\n\n")

        while !game.isTerminal {
            let isMonteCarlo = game.activePlayer == .first
            let move = isMonteCarlo ? await monteCarlo.bestMove(for: game) : await minimax.bestMove(for: game)
            guard let move else { break }
            game = game.applying(move)
            moveNumber += 1
            print("Move \(moveNumber): \(isMonteCarlo ? "X (Monte Carlo)" : "O (minimax)") -> cell \(move.index)")
            print(game, terminator: "\n\n")
        }

        // Hex can't end in a draw, so one side has connected its edges.
        guard case .win(let winner) = game.outcome else {
            Issue.record("Hex ended without a winner")
            return
        }
        print("Winner: \(winner == .first ? "Monte Carlo (X)" : "minimax (O)")")
        // 2,000 seeded playouts per move beat a two-ply search.
        #expect(winner == .first)
    }

    @Test func arenaMatchNeverDraws() async {
        let result = await Arena<HexModel>().match(
            MonteCarloStrategist<HexModel>(iterations: 500, seed: 1),
            against: MinimaxStrategist<HexModel>(maxDepth: 2),
            rounds: 4,
            startingFrom: HexModel(size: 4)
        )
        #expect(result.draws == 0)
        #expect(result.firstWins + result.secondWins == 4)
    }
}
