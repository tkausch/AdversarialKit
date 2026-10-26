import Testing
@testable import AdversarialKit

@Suite struct HexTests {
    private func play(_ game: HexModel, _ cells: [Int]) -> HexModel {
        cells.reduce(game) { $0.applying(.init(index: $1)) }
    }

    @Test func startsEmpty() {
        let game = HexModel(size: 4)
        #expect(game.outcome == nil)
        #expect(game.legalMoves().count == 16)
        #expect(game.activePlayer == .first)
    }

    @Test func neighborsFollowHexGeometry() {
        let game = HexModel(size: 3)
        #expect(Set(game.neighbors(of: 4)) == [3, 5, 1, 7, 2, 6])
        #expect(Set(game.neighbors(of: 0)) == [1, 3])
        #expect(Set(game.neighbors(of: 2)) == [1, 5, 4])
    }

    @Test func firstPlayerWinsTopToBottom() {
        // X fills column 0; O plays elsewhere in column 1.
        let game = play(HexModel(size: 3), [0, 1, 3, 4, 6])
        #expect(game.outcome == .win(.first))
        #expect(game.legalMoves().isEmpty)
    }

    @Test func secondPlayerWinsLeftToRight() {
        // O fills row 1; X plays row 0 and row 2 cells that don't connect.
        let game = play(HexModel(size: 3), [0, 3, 2, 4, 6, 5])
        #expect(game.outcome == .win(.second))
    }

    @Test func connectsThroughDiagonalNeighbor() {
        // X: 2 -> 4 -> 6 uses the (row-1, col+1) neighbor link.
        let game = play(HexModel(size: 3), [2, 0, 4, 1, 6])
        #expect(game.outcome == .win(.first))
    }

    @Test func oneCellBoardIsWonByFirstMove() {
        #expect(HexModel(size: 1).applying(.init(index: 0)).outcome == .win(.first))
    }

    @Test func neverDraws() {
        var game = HexModel(size: 5)
        while let move = game.legalMoves().randomElement() { game = game.applying(move) }
        #expect(game.outcome != nil && game.outcome != .draw)
    }

    @Test func applyingDoesNotMutateReceiver() {
        let game = HexModel(size: 3)
        _ = game.applying(.init(index: 4))
        #expect(game.board.allSatisfy { $0 == nil })
    }

    @Test func heuristicIsZeroOnAnEmptyBoardAndFavorsTheLeader() {
        let empty = HexModel(size: 5)
        #expect(empty.heuristicValue(for: .first) == 0)

        // X has three stones down column 0 and O has two on the far edge, so X leads.
        let ahead = play(empty, [0, 4, 5, 9, 10])
        #expect(ahead.heuristicValue(for: .first)! > 0)
        #expect(ahead.heuristicValue(for: .second) == -ahead.heuristicValue(for: .first)!)
    }

    @Test func nimOffersNoHeuristic() {
        #expect(NimModel(stones: 5).heuristicValue(for: .first) == nil)
    }
}
