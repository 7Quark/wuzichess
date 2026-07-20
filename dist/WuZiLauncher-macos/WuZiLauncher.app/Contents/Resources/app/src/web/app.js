import { BLACK, EMPTY } from "../../assets/scripts/core/gomoku-rules.js";
import { GomokuEngine, MODES } from "../../assets/scripts/core/gomoku-engine.js";

const app = document.querySelector("#app");
const engine = new GomokuEngine(MODES.HUMAN);

const state = {
  mode: MODES.HUMAN,
  aiThinking: false,
  message: "选择模式后即可开始对局。",
};

function playerName(player) {
  return player === BLACK ? "黑方" : "白方";
}

function statusText() {
  if (engine.status === "won") return `${playerName(engine.winner)}获胜`;
  if (engine.status === "draw") return "棋盘已满，和棋";
  if (state.aiThinking) return "白方 AI 正在计算...";
  return `${playerName(engine.currentPlayer)}落子`;
}

function renderBoard() {
  return engine.board
    .map((row, rowIndex) =>
      row
        .map((cell, colIndex) => {
          const isLast =
            engine.lastMove &&
            engine.lastMove.row === rowIndex &&
            engine.lastMove.col === colIndex;
          const stone =
            cell === EMPTY
              ? ""
              : `<span class="stone ${cell === BLACK ? "black" : "white"} ${isLast ? "last" : ""}"></span>`;
          const star =
            (rowIndex === 3 || rowIndex === 7 || rowIndex === 11) &&
            (colIndex === 3 || colIndex === 7 || colIndex === 11)
              ? '<span class="star"></span>'
              : "";
          return `<button class="cell" data-row="${rowIndex}" data-col="${colIndex}" aria-label="第 ${rowIndex + 1} 行，第 ${colIndex + 1} 列">${star}${stone}</button>`;
        })
        .join(""),
    )
    .join("");
}

function render() {
  app.innerHTML = `
    <main class="shell">
      <section class="hero">
        <div>
          <p class="eyebrow">LOCAL ARENA / 15 x 15</p>
          <h1>五子棋<span>·</span>棋局实验室</h1>
          <p class="subtitle">纯本地对弈，专注每一步的攻守判断。</p>
        </div>
        <div class="turn-card">
          <span class="turn-dot ${engine.currentPlayer === BLACK ? "black" : "white"}"></span>
          <div><small>当前回合</small><strong>${statusText()}</strong></div>
        </div>
      </section>

      <section class="game-layout">
        <div class="board-panel">
          <div class="board-head">
            <div><span class="board-label">GOMOKU BOARD</span><span class="board-size">15 x 15</span></div>
            <span class="match-mode">${state.mode === MODES.AI ? "人机对战" : "人人对战"}</span>
          </div>
          <div class="board-wrap">
            <div class="board" aria-label="五子棋棋盘">
              ${renderBoard()}
            </div>
          </div>
          <div class="board-foot">
            <span><i class="legend-stone black"></i>黑方先手</span>
            <span><i class="legend-stone white"></i>白方</span>
            <span>${engine.history.length} 手</span>
          </div>
        </div>

        <aside class="side-panel">
          <div class="panel-section mode-section">
            <span class="section-kicker">PLAY MODE</span>
            <h2>选择对手</h2>
            <div class="mode-tabs">
              <button class="${state.mode === MODES.HUMAN ? "active" : ""}" data-mode="${MODES.HUMAN}">人人对战</button>
              <button class="${state.mode === MODES.AI ? "active" : ""}" data-mode="${MODES.AI}">人机对战</button>
            </div>
            <p class="mode-copy">${state.mode === MODES.AI ? "AI 会优先处理成五、必防点、冲四与活三。" : "两位玩家轮流落子，黑方先行。"}</p>
          </div>
          <div class="panel-section">
            <span class="section-kicker">MATCH STATUS</span>
            <div class="status-line"><span>局面</span><strong>${engine.status === "playing" ? "进行中" : engine.status === "won" ? "已结束" : "和棋"}</strong></div>
            <div class="status-line"><span>手数</span><strong>${engine.history.length}</strong></div>
            <div class="status-line"><span>最后落子</span><strong>${engine.lastMove ? `${engine.lastMove.row + 1}, ${engine.lastMove.col + 1}` : "—"}</strong></div>
          </div>
          <div class="panel-actions">
            <button class="primary-action" id="reset">重新开始 <span>↻</span></button>
            <button class="quiet-action" id="undo" ${engine.history.length === 0 || state.aiThinking ? "disabled" : ""}>悔棋</button>
            <button class="quiet-action" id="exit">退出对局</button>
          </div>
          <div class="tip"><span>TIP</span>${state.message}</div>
        </aside>
      </section>
      <footer>WUZI / LOCAL ONLY <span>无需联网 · 无广告 · 只保留棋局</span></footer>
    </main>
  `;

  bindEvents();
}

function bindEvents() {
  document.querySelectorAll("[data-mode]").forEach((button) => {
    button.addEventListener("click", () => {
      state.mode = button.dataset.mode;
      engine.mode = state.mode;
      engine.reset();
      state.aiThinking = false;
      state.message =
        state.mode === MODES.AI
          ? "AI 会优先处理成五、必防点、冲四与活三。"
          : "人人对战模式已开启，黑方先手。";
      render();
    });
  });

  document.querySelectorAll(".cell").forEach((cell) => {
    cell.addEventListener("click", () => {
      if (state.aiThinking || engine.status !== "playing") return;
      const result = engine.play(Number(cell.dataset.row), Number(cell.dataset.col));
      if (!result.ok) return;
      state.message = `${playerName(result.move.player)}落子：第 ${result.move.row + 1} 行，第 ${result.move.col + 1} 列`;
      render();

      if (engine.isAiTurn()) {
        state.aiThinking = true;
        state.message = "AI 正在计算应对路线...";
        render();
        window.setTimeout(() => {
          const aiResult = engine.playAiTurn();
          state.aiThinking = false;
          if (aiResult.ok) {
            state.message = `白方 AI 落子：第 ${aiResult.move.row + 1} 行，第 ${aiResult.move.col + 1} 列`;
          }
          render();
        }, 420);
      }
    });
  });

  document.querySelector("#reset").addEventListener("click", () => {
    engine.reset();
    state.aiThinking = false;
    state.message = "棋局已重置。";
    render();
  });

  document.querySelector("#undo").addEventListener("click", () => {
    if (state.aiThinking) return;
    const result = engine.undo();
    if (!result.ok) return;
    state.message = state.mode === MODES.AI ? "已撤回上一轮双方落子。" : "已撤回上一步。";
    render();
  });

  document.querySelector("#exit").addEventListener("click", () => {
    engine.reset();
    state.mode = MODES.HUMAN;
    engine.mode = state.mode;
    state.aiThinking = false;
    state.message = "已退出上一局，准备开始新的对局。";
    render();
  });
}

render();
