import Testing
@testable import AdversarialKit

@Suite struct MinimaxStrategistTests {
    let strategist = MinimaxStrategist<NimModel>()

    @Test func takesWinningMove() async {
        #expect(await strategist.bestMove(for: NimModel(stones: 3)) == .init(count: 3))
    }

    @Test func leavesMultipleOfFour() async {
        // 6 stones: taking 2 leaves 4, a lost position for the opponent.
        #expect(await strategist.bestMove(for: NimModel(stones: 6)) == .init(count: 2))
    }

    @Test func noMoveWhenFinished() async {
        let game = NimModel(stones: 0)
        #expect(game.isTerminal)
        #expect(await strategist.bestMove(for: game) == nil)
    }

    @Test func depthLimitUsesHeuristic() async {
        // At depth 1 nothing is decided, so the heuristic picks the move.
        let greedy = MinimaxStrategist<NimModel>(maxDepth: 1) { game, _ in -game.stones }
        #expect(await greedy.bestMove(for: NimModel(stones: 10)) == .init(count: 3))
    }

    @Test func ignoresCancellation() async {
        let task = Task { await strategist.bestMove(for: NimModel(stones: 12)) }
        task.cancel()
        // 12 is a lost position, so every move scores the same and the first one wins.
        #expect(await task.value == .init(count: 1))
    }
}
