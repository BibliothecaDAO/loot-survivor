import { useQuery } from "@apollo/client";
import { getItemsByTokenId } from "../hooks/graphql/queries";
import ItemDisplay from "./LootIcon";

interface DiscoveryProps {
  discoveryData: any;
}

export const DiscoveryDisplay = ({ discoveryData }: DiscoveryProps) => {
  const { data } = useQuery(getItemsByTokenId, {
    variables: { id: discoveryData?.entityId },
  });

  const renderDiscoveryMessage = () => {
    if (discoveryData?.discoveryType === "Nothing") {
      return <p>You discovered {discoveryData.outputAmount} xp!</p>;
    }

    if (discoveryData?.discoveryType === "Beast") {
      return <p>You discovered a beast!</p>;
    }

    if (discoveryData?.discoveryType === "Obstacle") {
      if (discoveryData.outputAmount === 0) {
        return (
          <p>You avoided the {discoveryData.subDiscoveryType} obstacle!</p>
        );
      } else {
        return (
          <p>
            You discovered the {discoveryData.subDiscoveryType} obstacle, it did{" "}
            {discoveryData.outputAmount} damage!
          </p>
        );
      }
    }

    if (discoveryData?.discoveryType === "Item") {
      if (discoveryData.subDiscoveryType === "Gold") {
        return <p>You discovered {discoveryData.outputAmount} gold!</p>;
      }

      if (discoveryData.subDiscoveryType === "Loot") {
        return data ? (
          <div className="flex self-center">
            <ItemDisplay className="mr-4 " type={data.items[0]?.slot} />
            <p>You discovered a loot item, {data.items[0]?.item}!</p>
          </div>
        ) : (
          <></>
        );
      }

      if (discoveryData.subDiscoveryType === "Health") {
        return <p>You discovered {discoveryData.outputAmount} health!</p>;
      }
    }

    return null;
  };

  return renderDiscoveryMessage();
};
