import Testing
@testable import AdversarialKit

@Suite struct NimTests {
    let strategist = MinimaxStrategist<NimModel>()

    @Test func legalMovesAreCappedByPile() {
        #expect(NimModel(stones: 10).legalMoves().map(\.count) == [1, 2, 3])
        #expect(NimModel(stones: 2).legalMoves().map(\.count) == [1, 2])
        #expect(NimModel(stones: 0).legalMoves().isEmpty)
    }

    @Test func takingTheLastStoneWins() {
        let game = NimModel(stones: 2).applying(.init(count: 2))
        #expect(game.outcome == .win(.first))
        #expect(game.isTerminal)
    }

    @Test func firstPlayerWinsFromTen() async {
        var game = NimModel(stones: 10)
        while let move = await strategist.bestMove(for: game) { game = game.applying(move) }
        #expect(game.outcome == .win(.first))
    }

    @Test func secondPlayerWinsFromMultipleOfFour() async {
        var game = NimModel(stones: 12)
        while let move = await strategist.bestMove(for: game) { game = game.applying(move) }
        #expect(game.outcome == .win(.second))
    }

    @Test func leavesMultipleOfFour() async {
        // 6 stones: taking 2 leaves 4, a lost position for the opponent.
        #expect(await strategist.bestMove(for: NimModel(stones: 6)) == .init(count: 2))
    }

    @Test func respectsMaxTake() async {
        // With at most 2 per turn, 9 is a multiple of 3: take 1 and hope. 10 → take 1.
        #expect(await MinimaxStrategist<NimModel>().bestMove(for: NimModel(stones: 10, maxTake: 2)) == .init(count: 1))
    }
}
