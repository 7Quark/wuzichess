export const BOARD_SIZE = 15;
export const EMPTY = 0;
export const BLACK = 1;
export const WHITE = 2;

export const DIRECTIONS = [
  [1, 0],
  [0, 1],
  [1, 1],
  [1, -1],
];

export function createBoard(size = BOARD_SIZE) {
  return Array.from({ length: size }, () => Array(size).fill(EMPTY));
}

export function isInside(board, row, col) {
  return row >= 0 && row < board.length && col >= 0 && col < board.length;
}

export function isValidMove(board, row, col) {
  return isInside(board, row, col) && board[row][col] === EMPTY;
}

export function cloneBoard(board) {
  return board.map((row) => row.slice());
}

export function countEmpty(board) {
  return board.reduce(
    (total, row) => total + row.filter((cell) => cell === EMPTY).length,
    0,
  );
}

export function countLine(board, row, col, player, deltaRow, deltaCol) {
  let count = 1;
  let openEnds = 0;

  let nextRow = row + deltaRow;
  let nextCol = col + deltaCol;
  while (isInside(board, nextRow, nextCol) && board[nextRow][nextCol] === player) {
    count += 1;
    nextRow += deltaRow;
    nextCol += deltaCol;
  }
  if (isInside(board, nextRow, nextCol) && board[nextRow][nextCol] === EMPTY) {
    openEnds += 1;
  }

  nextRow = row - deltaRow;
  nextCol = col - deltaCol;
  while (isInside(board, nextRow, nextCol) && board[nextRow][nextCol] === player) {
    count += 1;
    nextRow -= deltaRow;
    nextCol -= deltaCol;
  }
  if (isInside(board, nextRow, nextCol) && board[nextRow][nextCol] === EMPTY) {
    openEnds += 1;
  }

  return { count, openEnds };
}

export function checkWin(board, row, col, player) {
  return DIRECTIONS.some(([deltaRow, deltaCol]) => {
    return countLine(board, row, col, player, deltaRow, deltaCol).count >= 5;
  });
}

export function isDraw(board) {
  return countEmpty(board) === 0;
}

export function getWinnerAfterMove(board, row, col, player) {
  if (checkWin(board, row, col, player)) {
    return player;
  }
  return isDraw(board) ? 0 : null;
}

export function getPattern(board, row, col, player, deltaRow, deltaCol) {
  const cells = [];
  for (let offset = -4; offset <= 4; offset += 1) {
    const nextRow = row + offset * deltaRow;
    const nextCol = col + offset * deltaCol;
    if (!isInside(board, nextRow, nextCol)) {
      cells.push(3);
    } else {
      cells.push(board[nextRow][nextCol]);
    }
  }
  return cells;
}

export function describeMove(board, row, col, player) {
  if (!isValidMove(board, row, col)) {
    return { type: "invalid", score: 0 };
  }

  board[row][col] = player;
  let best = { type: "single", score: 0 };
  for (const [deltaRow, deltaCol] of DIRECTIONS) {
    const { count, openEnds } = countLine(board, row, col, player, deltaRow, deltaCol);
    const score = count * 100 + openEnds * 20;
    if (count >= 5) {
      best = { type: "five", count, openEnds, score: 100000 };
      break;
    }
    if (count === 4 && openEnds === 2 && best.type !== "five") {
      best = { type: "open-four", count, openEnds, score: 50000 };
    } else if (count === 4 && openEnds >= 1 && best.score < 12000) {
      best = { type: "four", count, openEnds, score: 12000 };
    } else if (count === 3 && openEnds === 2 && best.score < 3000) {
      best = { type: "open-three", count, openEnds, score: 3000 };
    } else if (count === 2 && openEnds === 2 && best.score < 500) {
      best = { type: "open-two", count, openEnds, score: 500 };
    }
  }
  board[row][col] = EMPTY;
  return best;
}
