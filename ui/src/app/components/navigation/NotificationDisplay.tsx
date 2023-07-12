import { NotificationBattleDisplay } from "../beast/BattleDisplay";
import { DiscoveryDisplay } from "../actions/DiscoveryDisplay";
import SpriteAnimation from "./SpriteAnimation";
import { GameData } from "../GameData";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import { soundSelector, useUiSounds } from "../../hooks/useUiSound";
import { useCallback, useEffect, useState } from "react";
import { useQueriesStore } from "../../hooks/useQueryStore";
import { processBeastName, getRandomElement } from "../../lib/utils";
import { Adventurer, Battle, Discovery, NullAdventurer } from "@/app/types";

interface NotificationDisplayProps {
  type: string;
  notificationData: any;
  hasBeast: boolean;
}

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
        (data: Battle) =>
          data.attacker == "Beast" && (data.beastHealth ?? 0) > 0
      )
    ) {
      return gameData.ADVENTURER_ANIMATIONS["HitByBeast"];
    } else if (
      Array.isArray(notificationData?.data) &&
      notificationData.data.some(
        (data: Battle) => data.attacker == "Beast" && data.beastHealth == 0
      )
    ) {
      return gameData.ADVENTURER_ANIMATIONS["Dead"];
    }
  } else if (type == "Attack") {
    if (
      Array.isArray(notificationData?.data) &&
      notificationData.data.some(
        (data: Battle) => data.attacker == "Beast" && data.beastHealth == 0
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
          (data: Discovery) => data.ambushed && (adventurer.health ?? 0) > 0
        )
      ) {
        return gameData.ADVENTURER_ANIMATIONS["Ambush"];
      } else if (
        notificationData.data?.some(
          (data: Discovery) => data.ambushed && adventurer.health == 0
        )
      ) {
        return gameData.ADVENTURER_ANIMATIONS["Dead"];
      } else {
        return gameData.ADVENTURER_ANIMATIONS["DiscoverBeast"];
      }
    } else if (notificationData?.discoveryType == "Obstacle") {
      if (notificationData?.damageTaken > 0) {
        if (adventurer?.health === 0) {
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

export const processNotification = (
  type: string,
  notificationData: any,
  battles: Battle[],
  hasBeast: boolean
) => {
  const beastName = processBeastName(
    battles[0]?.beast ?? "",
    battles[0]?.special2 ?? "",
    battles[0]?.special3 ?? ""
  );
  if (type == "Attack" || type == "Flee") {
    return (
      <NotificationBattleDisplay
        battleData={notificationData?.data ? notificationData?.data : []}
        type={type}
      />
    );
  } else if (type == "Explore") {
    return <DiscoveryDisplay discoveryData={notificationData} />;
  } else if (notificationData == "Rejected") {
    return (
      <p className="text-lg">
        OH NO! The transaction was rejected! Please refresh and try again incase
        of wallet issues.
      </p>
    );
  } else if (type == "Multicall") {
    return (
      <div className="flex flex-col">
        {(notificationData as string[])?.map((noti: any, index: number) => {
          if (hasBeast) {
            if (
              noti.startsWith("You equipped") &&
              battles[0]?.attacker == "Beast" &&
              battles[0]?.beastHealth == 0
            ) {
              return (
                <p key={index} className="text-lg">
                  You were slaughtered by the beast after trying to equip an
                  item!
                </p>
              );
            } else if (
              noti.startsWith("You equipped") &&
              battles[0]?.attacker == "Beast" &&
              (battles[0]?.beastHealth ?? 0) > 0 &&
              (battles[0]?.beastHealth ?? 0) > 0
            ) {
              return (
                <p key={index} className="text-lg">
                  OUCH! You were attacked by the {beastName} after equipping an
                  item taking {battles[0].damageTaken}!
                </p>
              );
            } else if (
              noti.startsWith("You equipped") &&
              battles[0]?.attacker == "Beast" &&
              (battles[0]?.beastHealth ?? 0) > 0 &&
              (battles[0]?.beastHealth ?? 0) == 0
            ) {
              return (
                <p key={index} className="text-lg">
                  You were attacked by the {beastName} after equipping an item
                  but defended it!
                </p>
              );
            }
          }
          return (
            <p key={index} className="text-lg">
              {noti}
            </p>
          );
        })}
      </div>
    );
  } else {
    return <p className="text-lg">{notificationData?.toString()}</p>;
  }
};

export const NotificationDisplay = ({
  type,
  notificationData,
  hasBeast,
}: NotificationDisplayProps) => {
  const gameData = new GameData();

  const { adventurer } = useAdventurerStore();
  const { data } = useQueriesStore();
  const battles = data.lastBeastBattleQuery
    ? data.lastBeastBattleQuery.battles
    : [];
  const animation = processAnimation(
    type,
    notificationData,
    adventurer ?? NullAdventurer
  );
  // const animation = "attack2";
  const notification = processNotification(
    type,
    notificationData,
    battles,
    hasBeast
  );

  const [setSound, setSoundState] = useState(soundSelector.click);

  const { play } = useUiSounds(setSound);

  const playSound = useCallback(() => {
    play();
  }, [play]);

  useEffect(() => {
    if (animation) {
      const animationKey = Object.keys(gameData.ADVENTURER_ANIMATIONS).find(
        (key) => gameData.ADVENTURER_ANIMATIONS[key] === animation
      );
      if (animationKey && gameData.ADVENTURER_SOUNDS[animationKey]) {
        setSoundState(gameData.ADVENTURER_SOUNDS[animationKey]);
      }
      playSound();
    }
  }, [
    animation,
    gameData.ADVENTURER_ANIMATIONS,
    gameData.ADVENTURER_SOUNDS,
    playSound,
  ]);

  return (
    <div className="z-10 flex flex-row w-full gap-5 sm:p-2">
      <div className="w-1/6 sm:w-1/4">
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
            { name: "attack2", startFrame: 47, frameCount: 6 },
            { name: "attack3", startFrame: 53, frameCount: 8 },
            { name: "damage", startFrame: 59, frameCount: 4 },
            { name: "die", startFrame: 64, frameCount: 9 },
            { name: "drawSword", startFrame: 70, frameCount: 5 },
            { name: "discoverItem", startFrame: 85, frameCount: 6 },
            { name: "slide", startFrame: 24, frameCount: 5 },
          ]}
          currentAnimation={animation ?? ""}
        />
      </div>
      <div className="w-5/6 sm:w-3/4 m-auto">{notification}</div>
    </div>
  );
};
