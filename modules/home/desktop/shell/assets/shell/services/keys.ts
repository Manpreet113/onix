// Shared key handling for shell sheets.
import Gtk from "gi://Gtk?version=4.0";
import Gdk from "gi://Gdk?version=4.0";

/** Hide the window on Escape. Use as `<window $={escToHide} ...>`. */
export function escToHide(self: {
  add_controller(c: Gtk.EventController): void;
  hide(): void;
}) {
  const ctl = new Gtk.EventControllerKey();
  ctl.connect("key-pressed", (_c, keyval: number) => {
    if (keyval === Gdk.KEY_Escape) {
      self.hide();
      return true;
    }
    return false;
  });
  self.add_controller(ctl);
}
