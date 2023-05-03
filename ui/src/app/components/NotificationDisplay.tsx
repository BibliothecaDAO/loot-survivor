import { NotificationBattleDisplay } from "./BattleDisplay";
import { DiscoveryDisplay } from "./DiscoveryDisplay";
import SpriteAnimation from "./SpriteAnimation";
import { GameData } from "./GameData";

interface NotificationDisplayProps {
  type: string;
  notificationData: any;
}

const processAnimation = (type: string, notificationData: any) => {
  const gameData = new GameData();
  if (type == "Flee") {
    if (notificationData.fled) {
      return gameData.ADVENTURER_ANIMATIONS["Flee"];
    } else if (
      Array.isArray(notificationData) &&
      notificationData.some((data: any) => {
        data.ambush == true && data.targetHealth == 0;
      })
    ) {
      return gameData.ADVENTURER_ANIMATIONS["Dead"];
    } else if (
      Array.isArray(notificationData) &&
      notificationData.some((data: any) => {
        data.ambush == true;
      })
    ) {
      return gameData.ADVENTURER_ANIMATIONS["Ambush"];
    }
  } else if (type == "Attack") {
    if (
      Array.isArray(notificationData) &&
      notificationData.some((data: any) => {
        data.attacker == "Beast" && data.targetHealth == 0;
      })
    ) {
      return gameData.ADVENTURER_ANIMATIONS["Dead"];
    } else if (
      Array.isArray(notificationData) &&
      notificationData.some((data: any) => {
        data.attacker == "Beast" && data.targetHealth == 0;
      })
    ) {
      return gameData.ADVENTURER_ANIMATIONS["attack2"];
    } else {
      return gameData.ADVENTURER_ANIMATIONS[type];
    }
  } else if (type == "Explore") {
    if (notificationData?.discoveryType == "Beast") {
      return gameData.ADVENTURER_ANIMATIONS["DiscoverBeast"];
    } else if (notificationData.discoveryType == "Obstacle") {
      if (notificationData?.outputAmount > 0) {
        return gameData.ADVENTURER_ANIMATIONS["HitByObstacle"];
      } else {
        return gameData.ADVENTURER_ANIMATIONS["AvoidObstacle"];
      }
    } else if (notificationData?.discoveryType == "Item") {
      return gameData.ADVENTURER_ANIMATIONS["DiscoverItem"];
    }
  } else {
    return gameData.ADVENTURER_ANIMATIONS[type];
  }
};

const proccessNotification = (type: string, notificationData: any) => {
  if (type == "Attack" || type == "Flee") {
    return (
      <NotificationBattleDisplay battleData={notificationData} beastName="" />
    );
  } else if (type == "Explore") {
    return <DiscoveryDisplay discoveryData={notificationData} />;
  } else {
    return <p className="text-lg">{notificationData}</p>;
  }
};

export const NotificationDisplay = ({
  type,
  notificationData,
}: NotificationDisplayProps) => {
  const gameData = new GameData();
  const animation = processAnimation(type, notificationData);
  const notification = proccessNotification(type, notificationData);
  return (
    <>
      <SpriteAnimation
        frameWidth={100}
        frameHeight={100}
        columns={7}
        rows={16}
        frameRate={5}
        animations={[
          { name: "idle", startFrame: 0, frameCount: 4 },
          { name: "run", startFrame: 9, frameCount: 5 },
          { name: "jump", startFrame: 11, frameCount: 7 },
          { name: "attack1", startFrame: 42, frameCount: 5 },
          { name: "attack2", startFrame: 47, frameCount: 4 },
          { name: "damage", startFrame: 58, frameCount: 6 },
          { name: "die", startFrame: 64, frameCount: 9 },
          { name: "drawSword", startFrame: 70, frameCount: 5 },
          { name: "discoverItem", startFrame: 85, frameCount: 6 },
        ]}
        currentAnimation={animation ?? ""}
      />
      <div className="m-auto">{notification}</div>
    </>
  );
};
