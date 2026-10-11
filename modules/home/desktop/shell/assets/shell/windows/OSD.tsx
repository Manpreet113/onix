// OSD: volume / mic overlay (bottom-center, auto-hide).
import app from "ags/gtk4/app";
import { Astal } from "ags/gtk4";
import { createState, createComputed } from "ags";
import { timeout } from "ags/time";
import { createBinding } from "ags";
import Wp from "gi://AstalWp";

const [visible, setVisible] = createState(false);

function poke() {
  setVisible(true);
  timeout(1600, () => setVisible(false));
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
