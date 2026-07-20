import test from "node:test";
import assert from "node:assert/strict";
import {
  BLACK,
  EMPTY,
  WHITE,
  createBoard,
  describeMove,
  isDraw,
} from "../assets/scripts/core/gomoku-rules.js";
import { chooseBestMove } from "../assets/scripts/core/gomoku-ai.js";
import { GomokuEngine, MODES } from "../assets/scripts/core/gomoku-engine.js";

test("engine detects a horizontal win", () => {
  const engine = new GomokuEngine();
  for (let col = 0; col < 4; col += 1) {
    engine.play(0, col);
    engine.play(1, col);
  }
  const result = engine.play(0, 4);
  assert.equal(result.ok, true);
  assert.equal(engine.status, "won");
  assert.equal(engine.winner, BLACK);
});

test("engine detects a draw when the board is full", () => {
  const board = createBoard();
  for (let row = 0; row < board.length; row += 1) {
    for (let col = 0; col < board.length; col += 1) {
      board[row][col] = (row + col) % 2 === 0 ? BLACK : WHITE;
    }
  }
  assert.equal(isDraw(board), true);
});

test("AI blocks an immediate opponent win", () => {
  const board = createBoard();
  for (let col = 0; col < 4; col += 1) board[7][col] = BLACK;
  board[6][7] = WHITE;
  assert.deepEqual(chooseBestMove(board, WHITE), [7, 4]);
});

test("AI takes its own immediate win before defending", () => {
  const board = createBoard();
  for (let col = 0; col < 4; col += 1) board[3][col] = WHITE;
  for (let col = 8; col < 12; col += 1) board[10][col] = BLACK;
  assert.deepEqual(chooseBestMove(board, WHITE), [3, 4]);
});

test("pattern detector labels an open three", () => {
  const board = createBoard();
  board[7][6] = BLACK;
  board[7][7] = BLACK;
  const pattern = describeMove(board, 7, 8, BLACK);
  assert.equal(pattern.type, "open-three");
});

test("AI mode lets black move first and white responds", () => {
  const engine = new GomokuEngine(MODES.AI);
  assert.equal(engine.currentPlayer, BLACK);
  engine.play(7, 7);
  assert.equal(engine.isAiTurn(), true);
  const result = engine.playAiTurn();
  assert.equal(result.ok, true);
  assert.equal(engine.history.length, 2);
  assert.equal(engine.history[1].player, WHITE);
});

test("undo removes one move in human mode", () => {
  const engine = new GomokuEngine(MODES.HUMAN);
  engine.play(7, 7);
  const result = engine.undo();
  assert.equal(result.ok, true);
  assert.equal(engine.history.length, 0);
  assert.equal(engine.currentPlayer, BLACK);
  assert.equal(engine.board[7][7], EMPTY);
});

test("undo removes both moves in AI mode", () => {
  const engine = new GomokuEngine(MODES.AI);
  engine.play(7, 7);
  engine.playAiTurn();
  const result = engine.undo();
  assert.equal(result.ok, true);
  assert.equal(engine.history.length, 0);
  assert.equal(engine.currentPlayer, BLACK);
  assert.equal(engine.board[7][7], EMPTY);
});
