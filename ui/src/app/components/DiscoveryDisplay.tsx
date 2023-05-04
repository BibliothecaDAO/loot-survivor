import { GameData } from "./GameData";
import { getValueFromKey } from "../lib/utils";
import { useQuery } from "@apollo/client";
import { getItemsByTokenId } from "../hooks/graphql/queries";
import Heart from "../../../public/heart.svg";
import Coin from "../../../public/coin.svg";

interface DiscoveryProps {
  discoveryData: any;
}

export const DiscoveryDisplay = ({ discoveryData }: DiscoveryProps) => {
  const gameData = new GameData();
  const { data } = useQuery(getItemsByTokenId, {
    variables: { id: discoveryData.entityId },
  });

  const itemName = data ? data.items[0]?.item : "";

  return (
    <>
      {discoveryData.discoveryType == "Nothing" ? (
        <p className="text-center">
          YES! You found some hidden {discoveryData.outputAmount} xp!
        </p>
      ) : discoveryData.discoveryType == "Beast" ? (
        <p className="text-center text-red-600">
          OH NO! You discovered a beast!
        </p>
      ) : discoveryData.discoveryType == "Obstacle" ? (
        discoveryData.outputAmount == 0 ? (
          <p className="text-center text-white">
            PHEW! You avoided the {discoveryData.subDiscoveryType} obstacle!
          </p>
        ) : (
          <p className="text-center">
            WATCH OUT! You discovered the {discoveryData.subDiscoveryType}{" "}
            obstacle, it did {discoveryData.outputAmount} damage!
          </p>
        )
      ) : discoveryData.discoveryType == "Item" ? (
        discoveryData.subDiscoveryType == "Gold" ? (
          <p className="text-center">
            <span className="flex text-terminal-yellow">
              NICE! You discovered {discoveryData.outputAmount}{" "}
              <Coin className="self-center w-4 h-4 fill-current" />
            </span>
          </p>
        ) : discoveryData.subDiscoveryType == "Loot" ? (
          <p className="text-center">YES! You discovered Loot {itemName}!</p>
        ) : discoveryData.subDiscoveryType == "Health" ? (
          <p className="text-center">
            NICE! You discovered {discoveryData.outputAmount}{" "}
            <Heart className="self-center w-2 h-2 fill-current" />
            health!
          </p>
        ) : null
      ) : null}
    </>
  );
};
