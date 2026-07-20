import { _decorator, Component } from "cc";

const { ccclass, property } = _decorator;

/**
 * FGUI integration point for menus, result dialogs, and action buttons.
 * The board itself is intentionally rendered by GomokuGame.
 */
@ccclass("FairyGuiShell")
export class FairyGuiShell extends Component {
  @property
  packageName = "GomokuUI";

  @property
  menuComponent = "MainMenu";

  @property
  resultComponent = "ResultDialog";

  private fguiRoot: any = null;

  onLoad() {
    const runtime = globalThis as any;
    this.fguiRoot = runtime.fgui?.GRoot?.inst ?? null;
    if (!this.fguiRoot) {
      console.warn(
        "[FairyGuiShell] FGUI runtime not found. Add the FairyGUI Cocos Creator SDK and export the GomokuUI package.",
      );
    }
  }

  showMenu(onModeSelected: (mode: "human" | "ai") => void) {
    if (!this.fguiRoot) return;
    const runtime = globalThis as any;
    const packageApi = runtime.fgui?.UIPackage;
    packageApi?.createObject(this.packageName, this.menuComponent)?.makeFullScreen?.();
    // Keep callback wiring in one place when the exported FGUI package is present.
    this.fguiRoot.onKeyDown?.(onModeSelected);
  }

  showResult(title: string, onReset: () => void, onExit: () => void) {
    if (!this.fguiRoot) return;
    const runtime = globalThis as any;
    const dialog = runtime.fgui?.UIPackage?.createObject(
      this.packageName,
      this.resultComponent,
    );
    const titleView = dialog?.getChild?.("title");
    const resetView = dialog?.getChild?.("reset");
    const exitView = dialog?.getChild?.("exit");
    if (titleView) titleView.text = title;
    resetView?.onClick?.(onReset);
    exitView?.onClick?.(onExit);
    dialog?.center?.();
    this.fguiRoot.addChild?.(dialog);
  }
}
