import {
  _decorator,
  Color,
  Component,
  Graphics,
  Node,
  UITransform,
  Vec3,
} from "cc";
import { BLACK, BOARD_SIZE, EMPTY, WHITE } from "./core/gomoku-rules.js";
import { GomokuEngine, MODES } from "./core/gomoku-engine.js";
import { FairyGuiShell } from "./FairyGuiShell";

const { ccclass, property } = _decorator;

@ccclass("GomokuGame")
export class GomokuGame extends Component {
  @property(Node)
  boardRoot: Node | null = null;

  @property(FairyGuiShell)
  uiShell: FairyGuiShell | null = null;

  @property
  cellSize = 42;

  private engine = new GomokuEngine(MODES.HUMAN);
  private boardGraphics: Graphics | null = null;
  private stonesRoot: Node | null = null;

  onLoad() {
    this.ensureBoardNodes();
    this.renderBoard();
    this.uiShell?.showMenu((mode) => this.start(mode));
  }

  start(mode: "human" | "ai" = MODES.HUMAN) {
    this.engine.mode = mode;
    this.engine.reset();
    this.renderBoard();
  }

  reset() {
    this.start(this.engine.mode as "human" | "ai");
  }

  exitMatch() {
    this.start(MODES.HUMAN);
    this.uiShell?.showMenu((mode) => this.start(mode));
  }

  placeAt(row: number, col: number) {
    if (this.engine.status !== "playing" || this.engine.isAiTurn()) return;
    const result = this.engine.play(row, col);
    if (!result.ok) return;
    this.renderBoard();
    if (this.engine.isAiTurn()) {
      this.scheduleAiMove();
    }
    if (this.engine.status !== "playing") {
      this.uiShell?.showResult(
        this.engine.status === "draw"
          ? "和棋"
          : this.engine.winner === BLACK
            ? "黑方获胜"
            : "白方获胜",
        () => this.reset(),
        () => this.exitMatch(),
      );
    }
  }

  private scheduleAiMove() {
    this.scheduleOnce(() => {
      this.engine.playAiTurn();
      this.renderBoard();
    }, 0.35);
  }

  private ensureBoardNodes() {
    if (!this.boardRoot) {
      this.boardRoot = new Node("BoardRoot");
      this.node.addChild(this.boardRoot);
    }
    this.boardGraphics = this.boardRoot.getComponent(Graphics) ?? this.boardRoot.addComponent(Graphics);
    this.stonesRoot = new Node("Stones");
    this.boardRoot.addChild(this.stonesRoot);
    const transform = this.boardRoot.getComponent(UITransform) ?? this.boardRoot.addComponent(UITransform);
    transform.setContentSize(this.cellSize * (BOARD_SIZE - 1), this.cellSize * (BOARD_SIZE - 1));
  }

  private renderBoard() {
    if (!this.boardGraphics || !this.stonesRoot) return;
    const extent = this.cellSize * (BOARD_SIZE - 1);
    this.boardGraphics.clear();
    this.boardGraphics.strokeColor = new Color(91, 56, 28, 255);
    this.boardGraphics.lineWidth = 1;
    for (let index = 0; index < BOARD_SIZE; index += 1) {
      const offset = -extent / 2 + index * this.cellSize;
      this.boardGraphics.moveTo(-extent / 2, offset);
      this.boardGraphics.lineTo(extent / 2, offset);
      this.boardGraphics.moveTo(offset, -extent / 2);
      this.boardGraphics.lineTo(offset, extent / 2);
    }
    this.boardGraphics.stroke();

    this.stonesRoot.removeAllChildren();
    this.engine.board.forEach((row: number[], rowIndex: number) => {
      row.forEach((cell: number, colIndex: number) => {
        if (cell === EMPTY) return;
        const stone = new Node(cell === BLACK ? "BlackStone" : "WhiteStone");
        const graphics = stone.addComponent(Graphics);
        graphics.fillColor = cell === BLACK ? new Color(22, 28, 26, 255) : new Color(248, 245, 236, 255);
        graphics.circle(0, 0, this.cellSize * 0.38);
        graphics.fill();
        stone.setPosition(
          -extent / 2 + colIndex * this.cellSize,
          -extent / 2 + (BOARD_SIZE - 1 - rowIndex) * this.cellSize,
          0,
        );
        this.stonesRoot.addChild(stone);
      });
    });
  }
}
