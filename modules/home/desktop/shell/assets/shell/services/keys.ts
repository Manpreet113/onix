// Shared key handling for shell sheets.
import Gtk from "gi://Gtk?version=4.0";
import Gdk from "gi://Gdk?version=4.0";

type WindowLike = {
  add_controller(c: Gtk.EventController): void;
  hide(): void;
};

/** Run handler on every key press. Return true to swallow the key. */
export function onKeys(self: WindowLike, handler: (keyval: number) => boolean) {
  const ctl = new Gtk.EventControllerKey();
  ctl.connect("key-pressed", (_c, keyval: number) => handler(keyval));
  self.add_controller(ctl);
}

/** Hide the window on Escape. Use as `<window $={escToHide} ...>`. */
export function escToHide(self: WindowLike) {
  onKeys(self, (keyval) => {
    if (keyval === Gdk.KEY_Escape) {
      self.hide();
      return true;
    }
    return false;
  });
}

export { Gdk };
