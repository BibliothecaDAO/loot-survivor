import { useQuery } from "@apollo/client";
import { getItemsByTokenId } from "../hooks/graphql/queries";
import Heart from "../../../public/heart.svg";
import Coin from "../../../public/coin.svg";
import ItemDisplay from "./LootIcon";
import useAdventurerStore from "../hooks/useAdventurerStore";
import { processBeastName } from "../lib/utils";
import { useQueriesStore } from "../hooks/useQueryStore";

interface DiscoveryProps {
  discoveryData: any;
}

export const DiscoveryDisplay = ({ discoveryData }: DiscoveryProps) => {
  const { adventurer } = useAdventurerStore();
  const { data } = useQueriesStore();
  const { data: itemData } = useQuery(getItemsByTokenId, {
    variables: { id: discoveryData?.entityId },
  });
  const beasts = data.beastsQuery ? data.beastsQuery.beasts : [];

  const renderDiscoveryMessage = () => {
    if (discoveryData?.discoveryType === "Nothing") {
      return <p>NICE! You discovered {discoveryData.outputAmount} xp!</p>;
    }

    if (discoveryData?.discoveryType === "Beast") {
      let beast = beasts.find(
        (beasts: any) => discoveryData.entityId === beasts.id
      );
      const beastName = processBeastName(beast, adventurer);
      return <p>OH NO! You discovered {beastName}!</p>;
    }

    if (discoveryData?.discoveryType === "Obstacle") {
      if (discoveryData.outputAmount === 0) {
        return (
          <p>
            PHEW! You avoided the{" "}
            {discoveryData?.subDiscoveryType == "Poision Dart"
              ? "Poison Dart"
              : discoveryData?.subDiscoveryType}{" "}
            obstacle!
          </p>
        );
      } else if (adventurer?.health === 0) {
        return (
          <p>
            You discovered the{" "}
            {discoveryData?.subDiscoveryType == "Poision Dart"
              ? "Poison Dart"
              : discoveryData?.subDiscoveryType}{" "}
            obstacle, it killed you with {discoveryData?.outputAmount} damage!
          </p>
        );
      } else {
        return (
          <p>
            OUCH! You discovered the {discoveryData?.subDiscoveryType} obstacle,
            it did {discoveryData?.outputAmount} damage!
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
            <Coin className="self-center w-5 h-5 fill-current" />
          </div>
        );
      }

      if (discoveryData?.subDiscoveryType === "Loot") {
        return itemData ? (
          <div className="flex self-center">
            <ItemDisplay className="mr-4 " type={itemData.items[0]?.slot} />
            <p>GREAT! You discovered a loot item, {itemData.items[0]?.item}!</p>
          </div>
        ) : (
          <></>
        );
      }

      if (discoveryData?.subDiscoveryType === "Health") {
        return (
          <div className="flex self-center">
            <p>GREAT! You discovered {discoveryData.outputAmount} health! </p>
            <Heart className="self-center w-5 h-5 fill-current" />
          </div>
        );
      }
    }

    return null;
  };

  return renderDiscoveryMessage();
};
