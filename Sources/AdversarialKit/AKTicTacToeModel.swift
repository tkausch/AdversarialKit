public enum AKTicTacToePlayer: AKModelPlayer, CaseIterable {
    case x, o

    public var opponent: AKTicTacToePlayer { self == .x ? .o : .x }
}

/// A board cell index, 0...8, row-major.
public struct AKTicTacToeMove: AKModelMove {
    public let index: Int
    public init(index: Int) { self.index = index }
    public init(row: Int, column: Int) { self.index = row * 3 + column }
}

public struct AKTicTacToeModel: AKGameModel {
    public typealias Player = AKTicTacToePlayer
    public typealias Move = AKTicTacToeMove

    private static let lines = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6],
    ]

    public private(set) var board: [AKTicTacToePlayer?]
    public private(set) var activePlayer: AKTicTacToePlayer

    public init(activePlayer: AKTicTacToePlayer = .x) {
        self.board = Array(repeating: nil, count: 9)
        self.activePlayer = activePlayer
    }

    public var outcome: AKOutcome<AKTicTacToePlayer>? {
        for line in Self.lines {
            if let p = board[line[0]], board[line[1]] == p, board[line[2]] == p { return .win(p) }
        }
        return board.contains(where: { $0 == nil }) ? nil : .draw
    }

    public func legalMoves() -> [AKTicTacToeMove] {
        guard outcome == nil else { return [] }
        return board.indices.filter { board[$0] == nil }.map { AKTicTacToeMove(index: $0) }
    }

    public func applying(_ move: AKTicTacToeMove) -> AKTicTacToeModel {
        precondition(board.indices.contains(move.index) && board[move.index] == nil, "Illegal move")
        var next = self
        next.board[move.index] = activePlayer
        next.activePlayer = activePlayer.opponent
        return next
    }
}

extension AKTicTacToeModel: CustomStringConvertible {
    public var description: String {
        (0..<3).map { row in
            (0..<3).map { col in
                switch board[row * 3 + col] {
                case .x: "X"
                case .o: "O"
                case nil: "."
                }
            }.joined(separator: " ")
        }.joined(separator: "\n")
    }
}
