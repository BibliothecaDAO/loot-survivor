import { GameData } from "./GameData";
import { getValueFromKey } from "../lib/utils";
import { useQuery } from "@apollo/client";
import { getItemsByTokenId } from "../hooks/graphql/queries";

interface DiscoveryProps {
  discoveryData: any;
}

export const DiscoveryDisplay = ({ discoveryData }: DiscoveryProps) => {
  const gameData = new GameData();
  const { data } = useQuery(getItemsByTokenId, {
    variables: { id: discoveryData.entityId },
  });

  const itemName = data ? data.items[0].item : "";

  return (
    <>
      {discoveryData.discoveryType == "Nothing" ? (
        <p>You discovered {discoveryData.outputAmount} xp!</p>
      ) : discoveryData.discoveryType == "Beast" ? (
        <p>You discovered a beast!</p>
      ) : discoveryData.discoveryType == "Obstacle" ? (
        discoveryData.outputAmount == 0 ? (
          <p>You avoided the {discoveryData.subDiscoveryType} obstacle!</p>
        ) : (
          <p>
            You discovered the {discoveryData.subDiscoveryType} obstacle, it did{" "}
            {discoveryData.outputAmount} damage!
          </p>
        )
      ) : discoveryData.discoveryType == "Item" ? (
        discoveryData.subDiscoveryType == "Gold" ? (
          <p>You discovered {discoveryData.amount} gold!</p>
        ) : discoveryData.subDiscoveryType == "Loot" ? (
          <p>You discovered {itemName}!</p>
        ) : discoveryData.subDiscoveryType == "Health" ? (
          <p>You discovered {discoveryData.outputAmount} health!</p>
        ) : null
      ) : null}
    </>
  );
};
