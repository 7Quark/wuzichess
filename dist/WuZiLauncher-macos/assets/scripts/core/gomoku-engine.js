import {
  BLACK,
  BOARD_SIZE,
  EMPTY,
  WHITE,
  checkWin,
  cloneBoard,
  createBoard,
  isDraw,
  isValidMove,
} from "./gomoku-rules.js";
import { chooseBestMove } from "./gomoku-ai.js";

export const MODES = {
  HUMAN: "human",
  AI: "ai",
};

export class GomokuEngine {
  constructor(mode = MODES.HUMAN) {
    this.size = BOARD_SIZE;
    this.mode = mode;
    this.reset();
  }

  reset() {
    this.board = createBoard(this.size);
    this.currentPlayer = BLACK;
    this.status = "playing";
    this.winner = EMPTY;
    this.history = [];
    this.lastMove = null;
  }

  isAiTurn() {
    return this.mode === MODES.AI && this.currentPlayer === WHITE && this.status === "playing";
  }

  play(row, col) {
    if (this.status !== "playing" || !isValidMove(this.board, row, col)) {
      return { ok: false, reason: "invalid" };
    }

    const player = this.currentPlayer;
    this.board[row][col] = player;
    this.history.push({ row, col, player });
    this.lastMove = { row, col, player };

    if (checkWin(this.board, row, col, player)) {
      this.status = "won";
      this.winner = player;
    } else if (isDraw(this.board)) {
      this.status = "draw";
    } else {
      this.currentPlayer = player === BLACK ? WHITE : BLACK;
    }

    return {
      ok: true,
      move: { row, col, player },
      status: this.status,
      winner: this.winner,
    };
  }

  playAiTurn() {
    if (!this.isAiTurn()) return { ok: false, reason: "not-ai-turn" };
    const [row, col] = chooseBestMove(this.board, WHITE);
    return this.play(row, col);
  }

  undo() {
    if (this.history.length === 0) {
      return { ok: false, reason: "empty-history" };
    }

    const rollbackCount = this.mode === MODES.AI && this.history.length >= 2 ? 2 : 1;
    for (let index = 0; index < rollbackCount; index += 1) {
      const move = this.history.pop();
      if (!move) break;
      this.board[move.row][move.col] = EMPTY;
      this.currentPlayer = move.player;
    }

    this.status = "playing";
    this.winner = EMPTY;
    this.lastMove = this.history.length > 0 ? { ...this.history[this.history.length - 1] } : null;

    return {
      ok: true,
      currentPlayer: this.currentPlayer,
      history: this.history.slice(),
      lastMove: this.lastMove,
    };
  }

  getSnapshot() {
    return {
      board: cloneBoard(this.board),
      currentPlayer: this.currentPlayer,
      status: this.status,
      winner: this.winner,
      history: this.history.slice(),
      lastMove: this.lastMove ? { ...this.lastMove } : null,
    };
  }
}
