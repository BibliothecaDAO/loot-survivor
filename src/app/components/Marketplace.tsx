import { MarketItem } from "../types";
import { BidButton } from "./Bid";
import { Button } from "./Button";
import HorizontalKeyboardControl from "./HorizontalMenu";
import { useQuery } from "@apollo/client";
import { getMarketItems } from "../hooks/graphql/queries";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurerProps } from "../types";
import { useAccount } from "@starknet-react/core";

const Marketplace = () => {
  const { account } = useAccount();
  const { adventurer, handleUpdateAdventurer } = useAdventurer();
  const formatAdventurer = adventurer ? adventurer : NullAdventurerProps;

  const headings = [
    "Id",
    "Slot",
    "Type",
    "Material",
    "Rank",
    "Prefix_1",
    "Prefix_2",
    "Suffix",
    "Greatness",
    "CreatedBlock",
    "XP",
    "Adventurer",
    "Bidder",
    "Price",
    "Expiry",
    "Status",
    "Claimed Time",
    "Actions",
  ];

  const {
    loading: marketItemsLoading,
    error: marketItemsError,
    data: marketItemsData,
    refetch: marketItemsRefetch,
  } = useQuery(getMarketItems, {
    pollInterval: 5000,
  });

  const marketItems = marketItemsData ? marketItemsData.items : [];

  return (
    <div className="w-full">
      <div className="w-full">
        <table className="w-full border-terminal-green border">
          <thead>
            <tr className="p-3 border-b border-terminal-green">
              {headings.map((heading, index) => (
                <th key={index}>{heading}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {marketItems.map((item: any, index: number) => (
              <tr key={index}>
                <td className="p-2 text-center">{item.id}</td>
                <td className="p-2 text-center">{item.slot}</td>
                <td className="p-2 text-center">{item.type}</td>
                <td className="p-2 text-center">{item.material}</td>
                <td className="p-2 text-center">{item.rank}</td>
                <td className="p-2 text-center">{item.prefix_1}</td>
                <td className="p-2 text-center">{item.prefix_2}</td>
                <td className="p-2 text-center">{item.suffix}</td>
                <td className="p-2 text-center">{item.greatness}</td>
                <td className="p-2 text-center">{item.createdBlock}</td>
                <td className="p-2 text-center">{item.xp}</td>
                <td className="p-2 text-center">{item.adventurer}</td>
                <td className="p-2 text-center">{item.bidder}</td>
                <td className="p-2 text-center">{item.price}</td>
                <td className="p-2 text-center">{item.expiry}</td>
                <td className="p-2 text-center">{item.status}</td>
                <td className="p-2 text-center">{item.claimedTime}</td>
                <td className="p-2 text-center">
                  <BidButton />
                  <Button>CLAIM</Button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default Marketplace;
