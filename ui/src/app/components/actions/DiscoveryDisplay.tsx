import useAdventurerStore from "../../hooks/useAdventurerStore";
import { processBeastName } from "../../lib/utils";
import {
  HeartIcon,
  CoinIcon,
  GiBruteIcon,
  SkullCrossedBonesIcon,
  SpikedWallIcon,
  GiSandsOfTimeIcon,
  TwoCoinIcon,
  HealthPotionIcon,
  GiStarsStackIcon,
} from "../icons/Icons";
import { Discovery } from "@/app/types";

interface DiscoveryProps {
  discoveryData: Discovery;
}

export const DiscoveryDisplay = ({ discoveryData }: DiscoveryProps) => {
  const beastName = processBeastName(
    discoveryData?.entity ?? "",
    discoveryData?.special2 ?? "",
    discoveryData?.special3 ?? ""
  );

  const AdventurerHealthExists = (discoveryData?.adventurerHealth ?? 0) > 0;

  const renderDiscoveryMessage = () => {
    if (discoveryData?.discoveryType === "Beast") {
      if (discoveryData?.ambushed) {
        if (AdventurerHealthExists) {
          return (
            <span className="flex flex-row items-center justify-between">
              <p>YIKES! You were ambushed by a {beastName}</p>
              <GiBruteIcon />
            </span>
          );
        } else {
          return (
            <span className="flex flex-row items-center justify-between">
              <p>YIKES! You were killed from an ambush by a {beastName}</p>
              <SkullCrossedBonesIcon />
            </span>
          );
        }
      } else {
        return (
          <span className="flex flex-row items-center justify-between">
            <p>OH NO! You discovered a {beastName}!</p>
            <GiBruteIcon />
          </span>
        );
      }
    }

    if (discoveryData?.discoveryType === "Obstacle") {
      if (discoveryData?.dodgedObstacle) {
        return (
          <span className="flex flex-row items-center justify-between">
            <p>PHEW! You avoided the {discoveryData?.obstacle} obstacle!</p>
            <SpikedWallIcon />
          </span>
        );
      } else if (!AdventurerHealthExists) {
        return (
          <span className="flex flex-row items-center justify-between">
            <p>
              OUCH!{" "}
              {discoveryData?.obstacle?.endsWith("s")
                ? `A ${discoveryData?.obstacle}`
                : discoveryData?.obstacle}{" "}
              killed you with {discoveryData?.damageTaken} damage!
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
              inflicted {discoveryData?.damageTaken} damage!
            </p>
            <SpikedWallIcon />
          </span>
        );
      }
    }

    if (!discoveryData?.discoveryType) {
      return (
        <span className="flex flex-row items-center justify-between">
          <p>OOPS! You were killed by the idle death penalty!</p>
          <GiSandsOfTimeIcon />
        </span>
      );
    }

    if (discoveryData?.discoveryType === "Item") {
      if (discoveryData?.subDiscoveryType === "Gold") {
        return (
          <span className="flex flex-row items-center justify-between">
            <div className="flex flex-row gap-1 self-center items-center text-terminal-yellow">
              <p className="text-terminal-green">NICE! You discovered </p>
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
              <p>
                GREAT! You discovered {discoveryData?.outputAmount} health!{" "}
              </p>
              <HeartIcon className="mt-1 self-center w-5 h-5 fill-current" />
            </div>
            <HealthPotionIcon />
          </span>
        );
      }

      if (discoveryData?.subDiscoveryType === "XP") {
        return (
          <span className="flex flex-row items-center justify-between">
            <p>NICE! You discovered {discoveryData.outputAmount} XP!</p>
            <GiStarsStackIcon />
          </span>
        );
      }
    }

    return null;
  };

  return renderDiscoveryMessage();
};
