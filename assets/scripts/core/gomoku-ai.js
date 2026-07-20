import {
  BLACK,
  DIRECTIONS,
  EMPTY,
  WHITE,
  cloneBoard,
  countLine,
  describeMove,
  isInside,
  isValidMove,
} from "./gomoku-rules.js";

const PATTERN_SCORES = {
  five: 1000000,
  "open-four": 100000,
  four: 12000,
  "open-three": 5000,
  "open-two": 800,
};

const CENTER_BONUS = 36;

function opponentOf(player) {
  return player === BLACK ? WHITE : BLACK;
}

function moveKey(row, col) {
  return `${row}:${col}`;
}

function collectCandidates(board) {
  const candidates = [];
  const size = board.length;
  const occupied = [];

  for (let row = 0; row < size; row += 1) {
    for (let col = 0; col < size; col += 1) {
      if (board[row][col] !== EMPTY) {
        occupied.push([row, col]);
      }
    }
  }

  if (occupied.length === 0) {
    const center = Math.floor(size / 2);
    return [[center, center]];
  }

  const keys = new Set();
  for (const [row, col] of occupied) {
    for (let deltaRow = -2; deltaRow <= 2; deltaRow += 1) {
      for (let deltaCol = -2; deltaCol <= 2; deltaCol += 1) {
        const candidateRow = row + deltaRow;
        const candidateCol = col + deltaCol;
        if (
          isValidMove(board, candidateRow, candidateCol) &&
          !keys.has(moveKey(candidateRow, candidateCol))
        ) {
          keys.add(moveKey(candidateRow, candidateCol));
          candidates.push([candidateRow, candidateCol]);
        }
      }
    }
  }

  return candidates;
}

function scoreDirection(board, row, col, player, deltaRow, deltaCol) {
  const { count, openEnds } = countLine(board, row, col, player, deltaRow, deltaCol);
  if (count >= 5) return PATTERN_SCORES.five;
  if (count === 4 && openEnds === 2) return PATTERN_SCORES["open-four"];
  if (count === 4 && openEnds === 1) return PATTERN_SCORES.four;
  if (count === 3 && openEnds === 2) return PATTERN_SCORES["open-three"];
  if (count === 3 && openEnds === 1) return 900;
  if (count === 2 && openEnds === 2) return PATTERN_SCORES["open-two"];
  if (count === 2 && openEnds === 1) return 180;
  if (count === 1 && openEnds === 2) return 40;
  return 0;
}

function scoreMove(board, row, col, player) {
  if (!isValidMove(board, row, col)) return -Infinity;

  board[row][col] = player;
  let score = 0;
  for (const [deltaRow, deltaCol] of DIRECTIONS) {
    score += scoreDirection(board, row, col, player, deltaRow, deltaCol);
  }
  const center = Math.floor(board.length / 2);
  score += Math.max(0, 8 - Math.abs(row - center) - Math.abs(col - center)) * CENTER_BONUS;
  board[row][col] = EMPTY;
  return score;
}

function findWinningMoves(board, player, candidates) {
  return candidates.filter(([row, col]) => {
    board[row][col] = player;
    const winning = DIRECTIONS.some(([deltaRow, deltaCol]) => {
      return countLine(board, row, col, player, deltaRow, deltaCol).count >= 5;
    });
    board[row][col] = EMPTY;
    return winning;
  });
}

function findCriticalMoves(board, player, candidates) {
  return candidates
    .map(([row, col]) => {
      const pattern = describeMove(board, row, col, player);
      return { row, col, pattern };
    })
    .filter(({ pattern }) => pattern.type === "open-four" || pattern.type === "four")
    .sort((a, b) => b.pattern.score - a.pattern.score)
    .map(({ row, col }) => [row, col]);
}

function tacticalMove(board, player, candidates) {
  const ownWins = findWinningMoves(board, player, candidates);
  if (ownWins.length > 0) return ownWins[0];

  const opponent = opponentOf(player);
  const opponentWins = findWinningMoves(board, opponent, candidates);
  if (opponentWins.length > 0) return opponentWins[0];

  const ownCritical = findCriticalMoves(board, player, candidates);
  if (ownCritical.length > 0) return ownCritical[0];

  const opponentCritical = findCriticalMoves(board, opponent, candidates);
  if (opponentCritical.length > 0) return opponentCritical[0];

  return null;
}

function minimaxLite(board, player, candidates) {
  const opponent = opponentOf(player);
  let bestMove = null;
  let bestScore = -Infinity;

  for (const [row, col] of candidates) {
    const attack = scoreMove(board, row, col, player);
    const defense = scoreMove(board, row, col, opponent) * 0.92;
    const score = attack + defense;
    if (score > bestScore) {
      bestScore = score;
      bestMove = [row, col];
    }
  }

  return bestMove;
}

export function chooseBestMove(board, player = WHITE) {
  const candidates = collectCandidates(board);
  const tactical = tacticalMove(board, player, candidates);
  if (tactical) return tactical;
  return minimaxLite(board, player, candidates);
}

export function rankMoves(board, player = WHITE) {
  const candidates = collectCandidates(board);
  return candidates
    .map(([row, col]) => ({
      row,
      col,
      attack: scoreMove(board, row, col, player),
      defense: scoreMove(board, row, col, opponentOf(player)),
    }))
    .sort((a, b) => b.attack + b.defense - (a.attack + a.defense));
}

export function getCandidateMoves(board) {
  return collectCandidates(cloneBoard(board));
}
