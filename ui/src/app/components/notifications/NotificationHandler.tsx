import { NotificationBattleDisplay } from "../beast/BattleDisplay";
import { DiscoveryDisplay } from "../actions/DiscoveryDisplay";
import { GameData } from "../GameData";
import {
  processBeastName,
  getRandomElement,
  chunkArray,
} from "../../lib/utils";
import {
  Adventurer,
  Battle,
  Discovery,
  NullAdventurer,
  Notification,
} from "@/app/types";

const processAnimation = (
  type: string,
  notificationData: any,
  adventurer: Adventurer
) => {
  const gameData = new GameData();
  if (type == "Flee") {
    if (
      Array.isArray(notificationData?.data) &&
      notificationData.data.some((data: any) => data.fled)
    ) {
      return gameData.ADVENTURER_ANIMATIONS["Flee"];
    } else if (
      Array.isArray(notificationData?.data) &&
      notificationData.data.some(
        (data: Battle) => data.attacker == "Beast" && data.adventurerHealth == 0
      )
    ) {
      return gameData.ADVENTURER_ANIMATIONS["Dead"];
    } else if (
      Array.isArray(notificationData?.data) &&
      notificationData.data.some(
        (data: Battle) =>
          data.attacker == "Beast" && (data.adventurerHealth ?? 0) > 0
      )
    ) {
      return gameData.ADVENTURER_ANIMATIONS["HitByBeast"];
    }
  } else if (type == "Attack") {
    if (
      Array.isArray(notificationData?.data) &&
      notificationData.data.some(
        (data: Battle) => data.attacker == "Beast" && data.adventurerHealth == 0
      )
    ) {
      return gameData.ADVENTURER_ANIMATIONS["Dead"];
    } else if (
      Array.isArray(notificationData?.data) &&
      notificationData.data.some(
        (data: Battle) => data.attacker == "Adventurer" && data.beastHealth == 0
      )
    ) {
      return getRandomElement([
        gameData.ADVENTURER_ANIMATIONS["Attack1"],
        gameData.ADVENTURER_ANIMATIONS["Attack2"],
        gameData.ADVENTURER_ANIMATIONS["Attack3"],
      ]);
    } else {
      return getRandomElement([
        gameData.ADVENTURER_ANIMATIONS["Attack1"],
        gameData.ADVENTURER_ANIMATIONS["Attack2"],
        gameData.ADVENTURER_ANIMATIONS["Attack3"],
      ]);
    }
  } else if (type == "Explore") {
    if (notificationData?.discoveryType == "Beast") {
      if (
        notificationData?.data?.some(
          (data: Discovery) => data.ambushed && (data.adventurerHealth ?? 0) > 0
        )
      ) {
        return gameData.ADVENTURER_ANIMATIONS["Ambush"];
      } else if (
        notificationData?.data?.some(
          (data: Discovery) =>
            data.ambushed && (data.adventurerHealth ?? 0) == 0
        )
      ) {
        return gameData.ADVENTURER_ANIMATIONS["Dead"];
      } else {
        return gameData.ADVENTURER_ANIMATIONS["DiscoverBeast"];
      }
    } else if (notificationData?.discoveryType == "Obstacle") {
      if (notificationData?.dodgedObstacle == 0) {
        if (notificationData?.adventurerHealth == 0) {
          return gameData.ADVENTURER_ANIMATIONS["Dead"];
        } else {
          return gameData.ADVENTURER_ANIMATIONS["HitByObstacle"];
        }
      } else {
        return getRandomElement([
          gameData.ADVENTURER_ANIMATIONS["AvoidObstacle1"],
          gameData.ADVENTURER_ANIMATIONS["AvoidObstacle2"],
        ]);
      }
    } else if (notificationData?.discoveryType == "Item") {
      return gameData.ADVENTURER_ANIMATIONS["DiscoverItem"];
    } else if (!notificationData?.discoveryType) {
      if (notificationData?.adventurerHealth == 0) {
        return gameData.ADVENTURER_ANIMATIONS["IdleDamagePenaltyDead"];
      } else {
        return gameData.ADVENTURER_ANIMATIONS["IdleDamagePenalty"];
      }
    }
  } else if (type == "Multicall") {
    if ((adventurer.beastHealth ?? 0) > 0) {
      return gameData.ADVENTURER_ANIMATIONS["HitByBeast"];
    } else {
      return gameData.ADVENTURER_ANIMATIONS[type];
    }
  } else {
    return gameData.ADVENTURER_ANIMATIONS[type];
  }
};

export const processNotifications = (
  type: string,
  notificationData: Discovery[] | Battle[] | string | string[],
  battles: Battle[],
  hasBeast: boolean,
  adventurer: Adventurer
) => {
  const notifications: Notification[] = [];
  const beastName = processBeastName(
    battles[0]?.beast ?? "",
    battles[0]?.special2 ?? "",
    battles[0]?.special3 ?? ""
  );
  const animation = processAnimation(
    type,
    notificationData,
    adventurer ?? NullAdventurer
  );
  if (type == "Attack" || type == "Flee") {
    const battleScenarios = chunkArray(notificationData as Battle[], 2);
    for (let i = 0; i < battleScenarios.length; i++) {
      notifications.push({
        animation: animation ?? "",
        message: (
          <NotificationBattleDisplay
            battleData={battleScenarios[i] as Battle[]}
            type={type}
          />
        ),
      });
    }
    return notifications;
  } else if (type == "Explore") {
    // Here every discovery item in the DB is a noti, so we can just loop
    for (let i = 0; i < notificationData.length; i++) {
      notifications.push({
        animation: animation ?? "",
        message: (
          <DiscoveryDisplay discoveryData={notificationData[i] as Discovery} />
        ),
      });
    }
    return notifications;
  } else if (notificationData == "Rejected") {
    notifications.push({
      message: (
        <p>
          OH NO! The transaction was rejected! Please refresh and try again
          incase of wallet issues.
        </p>
      ),
      animation: "damage",
    });
    return notifications;
  } else if (type == "Multicall") {
    for (let i = 0; i < notificationData.length; i++) {
      if (hasBeast) {
        if (
          (notificationData[i] as string).startsWith("You equipped") &&
          battles[0]?.attacker == "Beast" &&
          battles[0]?.adventurerHealth == 0
        ) {
          notifications.push({
            message: (
              <p>
                You were slaughtered by the beast after trying to equip an item!
              </p>
            ),
            animation: animation ?? "",
          });
        } else if (
          (notificationData[i] as string).startsWith("You equipped") &&
          battles[0]?.attacker == "Beast" &&
          (battles[0]?.beastHealth ?? 0) > 0 &&
          (battles[0]?.beastHealth ?? 0) > 0
        ) {
          notifications.push({
            message: (
              <p>
                OUCH! You were attacked by the {beastName} after equipping an
                item taking {battles[0].damageTaken}!
              </p>
            ),
            animation: animation ?? "",
          });
        } else if (
          (notificationData[i] as string).startsWith("You equipped") &&
          battles[0]?.attacker == "Beast" &&
          (battles[0]?.beastHealth ?? 0) > 0 &&
          (battles[0]?.beastHealth ?? 0) == 0
        ) {
          notifications.push({
            message: (
              <p>
                You were attacked by the {beastName} after equipping an item but
                defended it!
              </p>
            ),
            animation: animation ?? "",
          });
        } else {
          notifications.push({
            message: <p>{notificationData[i] as string}</p>,
            animation: animation ?? "",
          });
        }
      } else {
        notifications.push({
          message: <p>{notificationData[i] as string}</p>,
          animation: animation ?? "",
        });
      }
    }
  } else {
    notifications.push({
      message: <p>{notificationData as string}</p>,
      animation: animation ?? "",
    });
  }
  return notifications;
};
