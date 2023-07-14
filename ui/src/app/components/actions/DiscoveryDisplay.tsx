import useAdventurerStore from "../../hooks/useAdventurerStore";
import { processBeastName } from "../../lib/utils";
import { HeartIcon, CoinIcon } from "../icons/Icons";
import { Discovery } from "@/app/types";

interface DiscoveryProps {
  discoveryData: Discovery;
}

export const DiscoveryDisplay = ({ discoveryData }: DiscoveryProps) => {
  const { adventurer } = useAdventurerStore();
  const beastName = processBeastName(
    discoveryData?.entity ?? "",
    discoveryData?.special2 ?? "",
    discoveryData?.special3 ?? ""
  );

  const renderDiscoveryMessage = () => {
    if (discoveryData?.discoveryType === "Beast") {
      if (discoveryData?.ambushed) {
        return <p>YIKES! You were ambushed by a {beastName}</p>;
      } else {
        return <p>OH NO! You discovered a {beastName}!</p>;
      }
    }

    if (discoveryData?.discoveryType === "Obstacle") {
      if (discoveryData?.dodgedObstacle) {
        return <p>PHEW! You avoided the {discoveryData?.obstacle} obstacle!</p>;
      } else if (adventurer?.health === 0) {
        return (
          <p>
            You discovered the {discoveryData?.obstacle} obstacle, it killed you
            with {discoveryData?.outputAmount} damage!
          </p>
        );
      } else {
        return (
          <p>
            OUCH! You were hit by the {discoveryData?.obstacle} obstacle, it did{" "}
            {discoveryData?.outputAmount} damage!
          </p>
        );
      }
    }

    if (discoveryData?.discoveryType === "Item") {
      if (discoveryData?.subDiscoveryType === "Gold") {
        return (
          <div className="flex self-center text-terminal-yellow">
            <p className="text-terminal-green">
              NICE! You discovered{" "}
              <span className="text-terminal-yellow">
                {discoveryData.outputAmount}
              </span>{" "}
            </p>
            <CoinIcon className="self-center w-5 h-5 fill-current" />
          </div>
        );
      }

      if (discoveryData?.subDiscoveryType === "Health") {
        return (
          <div className="flex self-center">
            <p>GREAT! You discovered {discoveryData.outputAmount} health! </p>
            <HeartIcon className="self-center w-5 h-5 fill-current" />
          </div>
        );
      }

      if (discoveryData?.subDiscoveryType === "XP") {
        return <p>NICE! You discovered {discoveryData.outputAmount} xp!</p>;
      }
    }

    if (!discoveryData?.discoveryType) {
      return <p>OOPS! You recieved the idle penalty of 80 damage!</p>;
    }

    return null;
  };

  return renderDiscoveryMessage();
};
