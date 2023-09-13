import useAdventurerStore from "../../hooks/useAdventurerStore";
import { soundSelector, useUiSounds } from "../../hooks/useUiSound";
import { useCallback, useEffect, useState } from "react";
import { useQueriesStore } from "../../hooks/useQueryStore";
import { NullAdventurer } from "@/app/types";
import NotificationComponent from "./NotificationComponent";
import { Notification } from "@/app/types";
import { processNotifications } from "./NotificationHandler";
import useLoadingStore from "../../hooks/useLoadingStore";

export const NotificationDisplay = () => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const hasBeast = useAdventurerStore((state) => state.computed.hasBeast);
  const { data } = useQueriesStore();
  const type = useLoadingStore((state) => state.type);
  const notificationData = useLoadingStore((state) => state.notificationData);
  const battles = data.lastBeastBattleQuery
    ? data.lastBeastBattleQuery.battles
    : [];
  const notifications: Notification[] = notificationData
    ? processNotifications(
        type,
        notificationData,
        adventurer ?? NullAdventurer,
        hasBeast,
        battles
      )
    : [];

  const [setSound, setSoundState] = useState(soundSelector.click);

  const { play } = useUiSounds(setSound);

  const playSound = useCallback(() => {
    play();
  }, [play]);

  return <NotificationComponent notifications={notifications} />;
};
