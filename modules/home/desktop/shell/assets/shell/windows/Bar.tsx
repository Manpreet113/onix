// Top bar: workspaces | clock | tray | audio/net/bt/battery | powermenu.
// Lives on monitor 0 for v1 (multi-monitor: duplicate Bar(1)... later).
import app from "ags/gtk4/app";
import { Astal } from "ags/gtk4";
import Gtk from "gi://Gtk?version=4.0";
import { createBinding, createComputed, For } from "ags";
import { createPoll } from "ags/time";
import { execAsync } from "ags/process";
import Hyprland from "gi://AstalHyprland";
import Tray from "gi://AstalTray";
import Wp from "gi://AstalWp";
import Network from "gi://AstalNetwork";
import Bluetooth from "gi://AstalBluetooth";
import Battery from "gi://AstalBattery";

function Workspaces() {
  const hypr = Hyprland.get_default();
  const workspaces = createBinding(hypr, "workspaces")((list) =>
    [...list].sort((a, b) => a.id - b.id),
  );
  const focused = createBinding(hypr, "focusedWorkspace");

  return (
    <box class="ws" spacing={4}>
      <For each={workspaces}>
        {(ws) => {
          const active = createComputed(
            () => focused()?.id === ws.id && focused() !== null,
          );
          return (
            <button
              class={active((a) => (a ? "ws-btn active" : "ws-btn"))}
              onClicked={() => hypr.dispatch("workspace", `${ws.id}`)}
              label={ws.id.toString()}
            />
          );
        }}
      </For>
    </box>
  );
}

function Clock() {
  const time = createPoll("", 1000, () => {
    const d = new Date();
    const hh = d.getHours().toString().padStart(2, "0");
    const mm = d.getMinutes().toString().padStart(2, "0");
    const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return `${days[d.getDay()]} ${months[d.getMonth()]} ${d.getDate()}  ${hh}:${mm}`;
  });
  return <label class="clock" label={time} />;
}

function SysTray() {
  const tray = Tray.get_default();
  const items = createBinding(tray, "items");
  return (
    <box class="tray" spacing={2}>
      <For each={items}>
        {(item) => (
          <menubutton class="tray-btn" tooltipMarkup={createBinding(item, "tooltipMarkup")}>
            <image gicon={createBinding(item, "gicon")} pixelSize={16} />
            <popover>
              <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                <label label={createBinding(item, "title")} class="tray-title" />
                <button label="Open" onClicked={() => item.activate(0, 0)} />
                <button label="Menu" onClicked={() => item.aboutToShow()} />
              </box>
            </popover>
          </menubutton>
        )}
      </For>
    </box>
  );
}

function Audio() {
  const wp = Wp.get_default();
  const audio = wp.audio;
  const speaker = audio.defaultSpeaker;
  const vol = createBinding(speaker, "volume");
  const mute = createBinding(speaker, "mute");
  const icon = createComputed(
    () => (mute() ? "󰝟" : vol() > 0.66 ? "󰕾" : vol() > 0.33 ? "󰖀" : "󰕿"),
  );
  return (
    <button
      class="pill"
      onClicked={() => execAsync(["bash", "-c", "ags request -i onix control"])}
    >
      <box spacing={6}>
        <label label={icon} class="ico" />
        <label label={vol((v) => `${Math.round(v * 100)}%`)} />
      </box>
    </button>
  );
}

function NetBt() {
  try {
    const bt = Bluetooth.get_default();
    const btIcon = createBinding(bt, "isPowered")((p) => (p ? "󰂯" : "󰂲"));
    try {
      void Network.get_default();
    } catch {
      return (
        <box class="pill" spacing={8}>
          <label label="󰖪" class="ico" />
          <label label={btIcon} class="ico" />
        </box>
      );
    }
    return (
      <box class="pill" spacing={8}>
        <label label="󰖩" class="ico" />
        <label label={btIcon} class="ico" />
      </box>
    );
  } catch {
    return (
      <box class="pill" spacing={8}>
        <label label="󰖩" class="ico" />
      </box>
    );
  }
}

function Batt() {
  try {
    const bat = Battery.get_default();
    const pct = createBinding(bat, "percentage");
    const isCharging = createBinding(bat, "charging");
    return (
      <box class="pill" spacing={6}>
        <label label={isCharging((c) => (c ? "󰂄" : "󰁹"))} class="ico" />
        <label label={pct((p) => `${Math.round(p * 100)}%`)} />
      </box>
    );
  } catch {
    return <box />;
  }
}

function PowerBtn() {
  return (
    <button class="pill power" onClicked={() => execAsync(["bash", "-c", "ags request -i onix powermenu"])}>
      <label label="⏻" class="ico" />
    </button>
  );
}

export default function Bar(monitor = 0) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor;

  return (
    <window
      name="onix-bar"
      namespace="onix-bar"
      class="Bar"
      monitor={monitor}
      visible
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox class="bar-inner">
        <box $type="start" spacing={8}>
          <Workspaces />
          <button class="pill" onClicked={() => execAsync(["bash", "-c", "ags request -i onix launcher"])}>
            <label label="󰀻  Launcher" />
          </button>
        </box>
        <box $type="center" spacing={8}>
          <Clock />
        </box>
        <box $type="end" spacing={6} class="cluster">
          <SysTray />
          <Audio />
          <NetBt />
          <Batt />
          <button class="pill" onClicked={() => execAsync(["bash", "-c", "ags request -i onix notifications"])}>
            <label label="󰂚" class="ico" />
          </button>
          <button class="pill" onClicked={() => execAsync(["bash", "-c", "ags request -i onix control"])}>
            <label label="󰒓" class="ico" />
          </button>
          <PowerBtn />
        </box>
      </centerbox>
    </window>
  );
}
