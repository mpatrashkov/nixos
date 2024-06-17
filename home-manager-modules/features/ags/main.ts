import { BarWindow } from "bar/bar";
import { VolumeIndicatorWindow } from "./audio-indicator/audio-indicator";
import { ScreenCorners } from "screen-corners/screen-corners";
import { Search } from "search/search";

const scss = `${App.configDir}/style.scss`;
const css = `/tmp/ags-style.css`;
Utils.exec(`sassc ${scss} ${css}`);

Utils.monitorFile(scss, function () {
  Utils.exec(`sassc ${scss} ${css}`);
  App.resetCss();
  App.applyCss(css);
});

// const css = `${App.configDir}/style.css`;

App.config({
  style: css,
  windows: [
    Search(0),
    // VolumeIndicatorWindow(0),
    BarWindow(0),
    BarWindow(1),
    ScreenCorners(0),
    ScreenCorners(1),
  ],
});
