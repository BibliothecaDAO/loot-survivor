import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { NullAdventurer } from "@/app/types";
import NotificationComponent from "@/app/components/notifications/NotificationComponent";
import { Notification } from "@/app/types";
import { processNotifications } from "@/app/components/notifications/NotificationHandler";
import useLoadingStore from "@/app/hooks/useLoadingStore";

export const NotificationDisplay = () => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const hasBeast = useAdventurerStore((state) => state.computed.hasBeast);
  const { data } = useQueriesStore();
  const type = useLoadingStore((state) => state.type);
  const notificationData = useLoadingStore((state) => state.notificationData);
  const error = useLoadingStore((state) => state.error);
  const battles = data.lastBeastBattleQuery
    ? data.lastBeastBattleQuery.battles
    : [];
  const notifications: Notification[] = notificationData
    ? processNotifications(
        type,
        notificationData,
        adventurer ?? NullAdventurer,
        hasBeast,
        battles,
        error
      )
    : [];

  return <NotificationComponent notifications={notifications} />;
};
