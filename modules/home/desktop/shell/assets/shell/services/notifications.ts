// Notification list state driven by daemon signals.
// NOTE: binding the `notifications` property does NOT track removals
// (Notifd is Gio.ListModel-backed; item changes emit `items-changed`,
// not property notify), which left dismissed toasts stuck on screen.
// We maintain our own array from notified/resolved signals instead.
import { createState } from "ags";
import Notifd from "gi://AstalNotifd";

export function useNotifications() {
  const notifd = Notifd.get_default();
  const initial = notifd.get_notifications() as unknown as Notifd.Notification[];
  const [items, setItems] = createState<Notifd.Notification[]>([...initial]);

  notifd.connect("notified", (_self, id: number) => {
    console.log(`[onix] notifd notified id=${id}`);
    const n = notifd.get_notification(id) as unknown as Notifd.Notification | null;
    if (!n) return;
    setItems((prev) => [...prev.filter((x) => x.id !== id), n]);
  });

  notifd.connect("resolved", (_self, id: number) => {
    console.log(`[onix] notifd resolved id=${id}`);
    setItems((prev) => prev.filter((x) => x.id !== id));
  });

  return { notifd, items };
}
