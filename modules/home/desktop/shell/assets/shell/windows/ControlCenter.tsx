// Quick settings slide-over (right side): wifi/bt/dnd, sliders, power.
import app from "ags/gtk4/app";
import { Astal } from "ags/gtk4";
import Gtk from "gi://Gtk?version=4.0";
import { createBinding } from "ags";
import { execAsync } from "ags/process";
import Wp from "gi://AstalWp";
import Network from "gi://AstalNetwork";
import Bluetooth from "gi://AstalBluetooth";
import PowerProfiles from "gi://AstalPowerProfiles";
import Notifd from "gi://AstalNotifd";

function VolumeSlider() {
  const wp = Wp.get_default().audio.defaultSpeaker;
  return (
    <box spacing={8} class="cc-row">
      <label label="󰕾" class="ico" widthRequest={24} />
      <slider
        hexpand
        min={0}
        max={1}
        value={createBinding(wp, "volume")}
        onChangeValue={({ value }) => (wp.volume = value)}
      />
      <label label={createBinding(wp, "volume")((v) => `${Math.round(v * 100)}%`)} widthRequest={48} />
    </box>
  );
}

function MicSlider() {
  try {
    const mic = Wp.get_default().audio.defaultMicrophone;
    return (
      <box spacing={8} class="cc-row">
        <label label="󰍬" class="ico" widthRequest={24} />
        <slider
          hexpand
          min={0}
          max={1}
          value={createBinding(mic, "volume")}
          onChangeValue={({ value }) => (mic.volume = value)}
        />
      </box>
    );
  } catch {
    return <box />;
  }
}

function BrightSlider() {
  return (
    <box spacing={8} class="cc-row">
      <label label="󰃞" class="ico" widthRequest={24} />
      <slider
        hexpand
        min={0.05}
        max={1}
        value={0.8}
        onChangeValue={({ value }) =>
          execAsync(["bash", "-c", `brightnessctl set '${Math.round(value * 100)}%'`]).catch(() => {})
        }
      />
    </box>
  );
}

export default function ControlCenter() {
  const { TOP, RIGHT, BOTTOM } = Astal.WindowAnchor;
  const notifd = Notifd.get_default();
  const dnd = createBinding(notifd, "dontDisturb");

  let wifiToggle: Gtk.Widget = <box />;
  try {
    const net = Network.get_default();
    const wifi = net.wifi;
    if (wifi) {
      const enabled = createBinding(wifi, "enabled");
      wifiToggle = (
        <button
          class={enabled((e) => (e ? "cc-toggle on" : "cc-toggle"))}
          onClicked={() => (wifi.enabled = !wifi.enabled)}
        >
          <box spacing={8}>
            <label label="󰖩" class="ico" />
            <label label="Wi-Fi" />
          </box>
        </button>
      );
    }
  } catch {
    /* no wifi */
  }

  let btToggle: Gtk.Widget = <box />;
  try {
    const bt = Bluetooth.get_default();
    const powered = createBinding(bt, "isPowered");
    btToggle = (
      <button
        class={powered((p) => (p ? "cc-toggle on" : "cc-toggle"))}
        onClicked={() => bt.toggle()}
      >
        <box spacing={8}>
          <label label="󰂯" class="ico" />
          <label label="Bluetooth" />
        </box>
      </button>
    );
  } catch {
    /* no bt */
  }

  let profiles: Gtk.Widget = <box />;
  try {
    const pp = PowerProfiles.get_default();
    const active = createBinding(pp, "activeProfile");
    profiles = (
      <box spacing={6} class="cc-row">
        {(pp.get_profiles() as { profile: string }[]).map((p) => (
          <togglebutton
            class="cc-toggle"
            label={p.profile}
            active={active((a) => a === p.profile)}
            onToggled={() => pp.set_active_profile(p.profile)}
          />
        ))}
      </box>
    );
  } catch {
    /* no powerprofiles */
  }

  return (
    <window
      name="onix-control"
      namespace="onix-control"
      class="Control"
      visible={false}
      anchor={TOP | RIGHT | BOTTOM}
      widthRequest={360}
      application={app}
    >
      <box orientation={Gtk.Orientation.VERTICAL} spacing={12} class="cc-inner">
        <label label="Quick settings" class="sheet-title" halign={Gtk.Align.START} />
        <box spacing={8}>
          {wifiToggle}
          {btToggle}
        </box>
        <VolumeSlider />
        <MicSlider />
        <BrightSlider />
        <togglebutton
          class="cc-toggle"
          label={dnd((d) => (d ? "Do not disturb: on" : "Do not disturb: off"))}
          active={dnd}
          onToggled={({ active }) => (notifd.set_dont_disturb(!active))}
        />
        {profiles}
        <box spacing={8}>
          <button class="cc-btn" label="󰒓 Settings" onClicked={() => execAsync(["bash", "-c", "ags request settings"])} />
          <button class="cc-btn" label="⏻ Power" onClicked={() => execAsync(["bash", "-c", "ags request powermenu"])} />
          <button class="cc-btn" label="󰖔 Wallpaper" onClicked={() => execAsync(["bash", "-c", "ags request wallpaper"])} />
        </box>
      </box>
    </window>
  );
}
