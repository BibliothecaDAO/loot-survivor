import { processBeastName } from "@/app/lib/utils";
import {
  CoinIcon,
  GiBruteIcon,
  SkullCrossedBonesIcon,
  SpikedWallIcon,
  TwoCoinIcon,
  HealthPotionIcon,
} from "@/app/components/icons/Icons";
import LootIcon from "@/app/components/icons/LootIcon";
import { Discovery } from "@/app/types";
import { GameData } from "@/app/lib/data/GameData";
import { getItemData } from "@/app/lib/utils";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";

interface DiscoveryProps {
  discoveryData: Discovery;
}

export const DiscoveryDisplay = ({ discoveryData }: DiscoveryProps) => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const beastName = processBeastName(
    discoveryData?.entity ?? "",
    discoveryData?.special2 ?? "",
    discoveryData?.special3 ?? ""
  );

  const AdventurerHealthExists = (discoveryData?.adventurerHealth ?? 0) > 0;

  const gameData = new GameData();

  const renderDiscoveryMessage = () => {
    if (discoveryData?.discoveryType === "Beast") {
      if (discoveryData?.ambushed) {
        if (AdventurerHealthExists) {
          return (
            <span className="flex flex-row items-center justify-between">
              <p>
                YIKES! Ambushed by a {beastName} for {discoveryData.damageTaken}{" "}
                damage to {discoveryData.damageLocation}!
              </p>
              <GiBruteIcon />
            </span>
          );
        } else {
          return (
            <span className="flex flex-row items-center justify-between">
              <p>
                YIKES! Killed by a {beastName} from an ambush of{" "}
                {discoveryData.damageTaken} damage to{" "}
                {discoveryData.damageLocation}!
              </p>
              <SkullCrossedBonesIcon />
            </span>
          );
        }
      } else {
        return (
          <span className="flex flex-row items-center justify-between">
            <p>OH NO! Discovered a {beastName}!</p>
            <GiBruteIcon />
          </span>
        );
      }
    }

    if (discoveryData?.discoveryType === "Obstacle") {
      if (discoveryData?.dodgedObstacle) {
        return (
          <span className="flex flex-row items-center justify-between">
            <p>
              PHEW! Avoided{" "}
              {discoveryData?.obstacle?.endsWith("s")
                ? discoveryData?.obstacle
                : `the ${discoveryData?.obstacle}`}
              !
            </p>
            <SpikedWallIcon />
          </span>
        );
      } else if (!AdventurerHealthExists) {
        return (
          <span className="flex flex-row items-center justify-between">
            <p>
              OUCH! Killed by{" "}
              {discoveryData?.obstacle?.endsWith("s")
                ? `a ${discoveryData?.obstacle}`
                : discoveryData?.obstacle}{" "}
              with {discoveryData?.damageTaken} damage to{" "}
              {discoveryData.damageLocation}!
            </p>
            <SkullCrossedBonesIcon />
          </span>
        );
      } else {
        return (
          <span className="flex flex-row items-center justify-between">
            <p>
              OUCH!{" "}
              {discoveryData?.obstacle?.endsWith("s")
                ? discoveryData?.obstacle
                : `A ${discoveryData?.obstacle}`}{" "}
              inflicted {discoveryData?.damageTaken} damage to{" "}
              {discoveryData.damageLocation}!
            </p>
            <SpikedWallIcon />
          </span>
        );
      }
    }

    if (discoveryData?.discoveryType === "Item") {
      if (discoveryData?.subDiscoveryType === "Gold") {
        return (
          <span className="flex flex-row items-center justify-between">
            <div className="flex flex-row gap-1 self-center items-center text-terminal-yellow">
              <p className="text-terminal-green">NICE! Discovered </p>
              <span className="flex flex-row items-center">
                <CoinIcon className="mt-1 self-center w-5 h-5 fill-current" />
                <span className="text-terminal-yellow">
                  {discoveryData?.outputAmount}
                </span>{" "}
              </span>
            </div>
            <TwoCoinIcon />
          </span>
        );
      }

      if (discoveryData?.subDiscoveryType === "Health") {
        return (
          <span className="flex flex-row items-center justify-between">
            <div className="flex self-center">
              <p>GREAT! Discovered {discoveryData?.outputAmount} health! </p>
            </div>
            <HealthPotionIcon />
          </span>
        );
      }

      if (discoveryData?.subDiscoveryType === "Loot") {
        const itemName = gameData.ITEMS[discoveryData?.outputAmount!];
        const { slot } = getItemData(itemName ?? "");
        const hasEquipped = adventurer![slot.toLowerCase()] == itemName;
        return (
          <span className="flex flex-row items-center justify-between">
            <div className="flex self-center">
              {!hasEquipped ? (
                <p>
                  WOW! Discovered {itemName}. Check your bag!
                  <LootIcon size={"w-5"} type={slot} />
                </p>
              ) : (
                <p>
                  WOW! Discovered and equipped {itemName}!
                  <LootIcon size={"w-5"} type={slot} />
                </p>
              )}
            </div>
          </span>
        );
      }
    }

    return null;
  };

  return renderDiscoveryMessage();
};
