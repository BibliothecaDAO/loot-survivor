import { GameData } from "./GameData";
import { getValueFromKey } from "../lib/utils";

interface DiscoveryProps {
  discoveryData: any;
}

export const DiscoveryDisplay = ({ discoveryData }: DiscoveryProps) => {
  const gameData = new GameData();

  console.log(discoveryData)
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
          <p>
            You discovered a{" "}
            {getValueFromKey(gameData.ITEMS, discoveryData.entityId)}!
          </p>
        ) : discoveryData.subDiscoveryType == "Health" ? (
          <p>You discovered {discoveryData.outputAmount} health!</p>
        ) : null
      ) : null}
    </>
  );
};
