// OSD: volume / mic overlay (bottom-center, auto-hide).
import app from "ags/gtk4/app";
import { Astal } from "ags/gtk4";
import { createState, createComputed } from "ags";
import { createBinding } from "ags";
import Wp from "gi://AstalWp";
import GLib from "gi://GLib?version=2.0";

const [visible, setVisible] = createState(false);
let hideSrc = 0;

function poke() {
  setVisible(true);
  if (hideSrc) GLib.source_remove(hideSrc);
  hideSrc = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1600, () => {
    setVisible(false);
    hideSrc = 0;
    return GLib.SOURCE_REMOVE;
  });
}

export default function OSD() {
  const { BOTTOM } = Astal.WindowAnchor;
  const wp = Wp.get_default();
  const speaker = wp.audio.defaultSpeaker;
  const vol = createBinding(speaker, "volume");
  const mute = createBinding(speaker, "mute");

  // Reveal on any volume/mute change.
  vol.subscribe(() => poke());
  mute.subscribe(() => poke());

  const icon = createComputed(() =>
    mute() ? "󰝟 Muted" : vol() > 0.66 ? "󰕾" : vol() > 0.33 ? "󰖀" : "󰕿",
  );

  return (
    <window
      name="onix-osd"
      namespace="onix-osd"
      class="OSD"
      visible={visible}
      anchor={BOTTOM}
      layer={Astal.Layer.OVERLAY}
      exclusivity={Astal.Exclusivity.IGNORE}
      keymode={Astal.Keymode.NONE}
      application={app}
    >
      <box spacing={12} class="osd-inner">
        <label label={icon} class="ico" />
        <slider
          min={0}
          max={1}
          value={vol}
          widthRequest={260}
          onChangeValue={({ value }) => {
            // Guard: programmatic sets re-emit — only write on real change,
            // otherwise volume-notify → set → notify spins the main loop.
            if (Math.abs(speaker.volume - value) > 0.0005) speaker.volume = value;
          }}
        />
        <label label={vol((v) => `${Math.round(v * 100)}%`)} widthRequest={52} />
      </box>
    </window>
  );
}
