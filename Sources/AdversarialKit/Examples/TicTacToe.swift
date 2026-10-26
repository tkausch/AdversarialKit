/// A move in Tic-Tac-Toe: placing a mark on one cell of the board.
///
/// Cells are numbered 0 through 8, row by row from the top left.
public struct TicTacToeMove: ModelMove {
    /// The cell index, 0...8, in row-major order.
    public let index: Int

    /// Creates a move from a cell index.
    public init(index: Int) { self.index = index }

    /// Creates a move from a zero-based row and column, each in 0...2.
    public init(row: Int, column: Int) { self.index = row * 3 + column }
}

/// A ready-made ``GameModel`` for Tic-Tac-Toe on a 3×3 board.
///
/// Use it to try out ``MinimaxStrategist`` or as a reference for writing your own
/// model. With perfect play from both sides the game is always a draw:
///
/// ```swift
/// let strategist = MinimaxStrategist<TicTacToeModel>()
/// var game = TicTacToeModel()
/// while let move = await strategist.bestMove(for: game) {
///     game = game.applying(move)
/// }
/// print(game)
/// // Output: the final board, with game.outcome == .draw
/// ```
public struct TicTacToeModel: GameModel {
    public typealias Move = TicTacToeMove

    private static let lines = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6],
    ]

    /// The cells of the board in row-major order. `nil` marks an empty cell.
    public private(set) var board: [ModelPlayer?]

    /// The player who places the next mark.
    public private(set) var activePlayer: ModelPlayer

    /// Creates an empty board.
    ///
    /// - Parameter activePlayer: The player who moves first. The default is `first`.
    public init(activePlayer: ModelPlayer = .first) {
        self.board = Array(repeating: nil, count: 9)
        self.activePlayer = activePlayer
    }

    /// A win for the player who completed a line, a draw if the board is full, or
    /// `nil` while the game continues.
    public var outcome: Outcome? {
        for line in Self.lines {
            if let p = board[line[0]], board[line[1]] == p, board[line[2]] == p { return .win(p) }
        }
        return board.contains(where: { $0 == nil }) ? nil : .draw
    }

    /// The empty cells, in index order. Empty once the game is over.
    public func legalMoves() -> LazyMapSequence<LazyFilterSequence<Range<Int>>, TicTacToeMove> {
        let indices = outcome == nil ? board.indices : 0..<0
        return indices.lazy.filter { board[$0] == nil }.map { TicTacToeMove(index: $0) }
    }

    /// Returns the board after the active player marks the cell of `move`.
    ///
    /// - Precondition: The cell of `move` exists and is empty.
    public func applying(_ move: TicTacToeMove) -> TicTacToeModel {
        precondition(board.indices.contains(move.index) && board[move.index] == nil, "Illegal move")
        var next = self
        next.board[move.index] = activePlayer
        next.activePlayer = activePlayer.opponent
        return next
    }
}

extension TicTacToeModel: CustomStringConvertible {
    /// The board as three lines, with `X` for the first player, `O` for the second, and `.` for an empty cell.
    public var description: String {
        (0..<3).map { row in
            (0..<3).map { col in
                switch board[row * 3 + col] {
                case .first: "X"
                case .second: "O"
                case nil: "."
                }
            }.joined(separator: " ")
        }.joined(separator: "\n")
    }
}
