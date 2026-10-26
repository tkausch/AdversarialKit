/// A move in Hex: placing a stone on one cell of the board.
///
/// Cells are numbered row by row from the top left, so the cell at `row` and
/// `column` has the index `row * size + column`.
public struct HexMove: ModelMove {
    /// The cell index, 0..<size², in row-major order.
    public let index: Int

    /// Creates a move from a cell index.
    public init(index: Int) { self.index = index }

    /// Creates a move from a zero-based row and column on a board of the given size.
    public init(row: Int, column: Int, size: Int) { self.index = row * size + column }
}

/// A ready-made ``GameModel`` for Hex on a rhombus of hexagonal cells.
///
/// Players alternate placing one stone on any empty cell. The first player
/// wins by linking the top and bottom edges with an unbroken chain of
/// adjacent stones, the second player by linking the left and right edges.
/// Hex can't end in a draw: once the board is full, exactly one player has a
/// connection.
///
/// The board is stored as a grid in which cell (`row`, `column`) touches six
/// neighbors: (`row`, `column` ± 1), (`row` ± 1, `column`), (`row` − 1,
/// `column` + 1) and (`row` + 1, `column` − 1). Drawn as a rhombus, each row
/// is shifted half a cell to the right of the one above it.
///
/// ```swift
/// let strategist = MonteCarloStrategist<HexModel>()
/// var game = HexModel(size: 5)
/// while let move = await strategist.bestMove(for: game) {
///     game = game.applying(move)
/// }
/// print(game)
/// ```
///
/// The model doesn't implement the swap rule that is often used to offset the
/// first player's advantage.
public struct HexModel: GameModel {
    public typealias Move = HexMove

    /// The number of cells along each side of the board.
    public let size: Int

    /// The cells of the board in row-major order. `nil` marks an empty cell.
    public private(set) var board: [ModelPlayer?]

    /// The player who places the next stone.
    public private(set) var activePlayer: ModelPlayer

    /// The player who has connected their two edges, if any.
    private var winner: ModelPlayer?

    /// Creates an empty board.
    ///
    /// - Parameters:
    ///   - size: The number of cells along each side, at least 1. The default is 11.
    ///   - activePlayer: The player who moves first. The default is `first`.
    public init(size: Int = 11, activePlayer: ModelPlayer = .first) {
        precondition(size >= 1, "The board needs at least one cell")
        self.size = size
        self.board = Array(repeating: nil, count: size * size)
        self.activePlayer = activePlayer
    }

    /// A win for the player who connected their edges, or `nil` while the game continues.
    ///
    /// There is never a draw.
    public var outcome: Outcome? { winner.map(Outcome.win) }

    /// The empty cells, in index order. Empty once the game is over.
    public func legalMoves() -> LazyMapSequence<LazyFilterSequence<Range<Int>>, HexMove> {
        let indices = winner == nil ? board.indices : 0..<0
        return indices.lazy.filter { board[$0] == nil }.map { HexMove(index: $0) }
    }

    /// Returns the board after the active player places a stone on the cell of `move`.
    ///
    /// - Precondition: The cell of `move` exists and is empty.
    public func applying(_ move: HexMove) -> HexModel {
        precondition(winner == nil && board.indices.contains(move.index) && board[move.index] == nil, "Illegal move")
        var next = self
        next.board[move.index] = activePlayer
        if next.connects(activePlayer) { next.winner = activePlayer }
        next.activePlayer = activePlayer.opponent
        return next
    }

    /// The indices of the up to six cells adjacent to `index`.
    public func neighbors(of index: Int) -> [Int] {
        let (row, column) = index.quotientAndRemainder(dividingBy: size)
        return [(0, -1), (0, 1), (-1, 0), (1, 0), (-1, 1), (1, -1)].compactMap { dr, dc in
            let r = row + dr, c = column + dc
            return (0..<size).contains(r) && (0..<size).contains(c) ? r * size + c : nil
        }
    }

    /// Whether `player`'s stones link their two edges, found by flood fill from the starting edge.
    private func connects(_ player: ModelPlayer) -> Bool {
        // First player: top row to bottom row. Second player: left column to right column.
        let isFirst = player == .first
        let starts = (0..<size).map { isFirst ? $0 : $0 * size }
        var visited = Set<Int>()
        var stack = starts.filter { board[$0] == player }
        visited.formUnion(stack)
        while let cell = stack.popLast() {
            let (row, column) = cell.quotientAndRemainder(dividingBy: size)
            if (isFirst ? row : column) == size - 1 { return true }
            for n in neighbors(of: cell) where board[n] == player && visited.insert(n).inserted {
                stack.append(n)
            }
        }
        return false
    }
}

extension HexModel: CustomStringConvertible {
    /// The board as a rhombus, with `X` for the first player, `O` for the second, and `.` for an empty cell.
    public var description: String {
        (0..<size).map { row in
            String(repeating: " ", count: row) + (0..<size).map { column in
                switch board[row * size + column] {
                case .first: "X"
                case .second: "O"
                case nil: "."
                }
            }.joined(separator: " ")
        }.joined(separator: "\n")
    }
}
