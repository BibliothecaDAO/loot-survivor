import { MarketItem } from "../types";
import { BidButton } from "./Bid";
import { Button } from "./Button";
import { useQuery } from "@apollo/client";
import { getItemsByMarketId } from "../hooks/graphql/queries";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurerProps } from "../types";
import { useAccount } from "@starknet-react/core";

const Marketplace = () => {
  const { account } = useAccount();
  // const formatAdventurer = adventurer ? adventurer : NullAdventurerProps;

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
    "Bag",
    "Bid",
  ];

  const {
    loading: itemsByMarketIdLoading,
    error: itemsByMarketIdError,
    data: itemsByMarketIdData,
    refetch: itemsByMarketIdRefetch,
  } = useQuery(getItemsByMarketId, {
    pollInterval: 5000,
  });

  const items = itemsByMarketIdData
    ? itemsByMarketIdData.getItemsByMarketId
    : [];

  const { handleUpdateAdventurer } = useAdventurer();
  const marketItems = [];

  for (let i = 0; i < items.length; i++) {
    marketItems.push({
      Id: items[i].id,
      MarketId: items[i].marketId,
      Slot: items[i].slot,
      Type: items[i].type,
      Material: items[i].material,
      Rank: items[i].rank,
      Prefix_1: items[i].prefix_1,
      Prefix_2: items[i].prefix_2,
      Suffix: items[i].suffix,
      Greatness: items[i].greatness,
      XP: items[i].xp,
      Bidder: items[i].bidder,
      Price: items[i].price,
      Status: items[i].status,
      Expiry: items[i].expiry,
      ClaimedTime: items[i].claimedTime,
      LastUpdated: items[i].lastUpdated,
      Bid: items[i].bid,
      id: i + 1,
      label: items[i].id,
    });
  }

  return (
    <div className="w-full">
      <div className="w-full">
        <table className="w-full border-terminal-green border">
          <thead>
            <tr className="p-3 border-b border-terminal-green">
              {headings.map((heading, index) => (
                <th key={index}>{heading}</th>
              ))}
              <th>Bid</th>
            </tr>
          </thead>
          <tbody>
            {marketItems.map((item, index) => (
              <tr key={index}>
                {Object.values(item).map((value, index) => (
                  <td className="p-2 text-center" key={index}>
                    {value}
                  </td>
                ))}
                <td className="p-2 text-center">
                  <BidButton />
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

// import { MarketItem } from "../types";
// import { BidButton } from "./Bid";
// import { Button } from "./Button";
// import { useQuery } from "@apollo/client";
// import { getItemsByMarketId } from "../hooks/graphql/queries";
// import { useAdventurer } from "../context/AdventurerProvider";

// const Marketplace = () => {
//   const headings = [
//     "Id",
//     "Slot",
//     "Type",
//     "Material",
//     "Rank",
//     "Prefix_1",
//     "Prefix_2",
//     "Suffix",
//     "Greatness",
//     "CreatedBlock",
//     "XP",
//     "Adventurer",
//     "Bag",
//     "Bid",
//   ];

//   const {
//     loading: itemsByMarketIdLoading,
//     error: itemsByMarketIdError,
//     data: itemsByMarketIdData,
//     refetch: itemsByMarketIdrRefetch,
//   } = useQuery(getItemsByMarketId, {
//     variables: {
//     },
//     pollInterval: 5000,
//   });

//   const marketItems = itemsByMarketIdData
//     ? itemsByMarketIdData.items
//     : [];
//   const { handleUpdateAdventurer } = useAdventurer();
//   const marketItems = MarketItem[];
//   for (let i = 0; i < marketItems.length; i++) {
//     marketItems.push({
//       Id: {items[i].id},
//       MarketId: {items[i].marketId},
//       Slot: {items[i].slot},
//       Type: {items[i].type},
//       Material: {items[i].material},
//       Rank: {items[i].rank},
//       Prefix_1: {items[i].prefix_1},
//       Prefix_2: {items[i].prefix_2},
//       Suffix: {items[i].suffix},
//       Greatness: {items[i].greatness},
//       XP: {items[i].xp},
//       Bidder: {items[i].bidder},
//       Price: {items[i].price},
//       Status: {items[i].status},
//       Expiry: {items[i].expiry},
//       ClaimedTime: {items[i].claimedTime},
//       LastUpdated: {items[i].lastUpdated},
//       Bid: {items[i].bid},
//       id: i + 1,
//       label: items[i].id,
//       action: () => handleUpdateItems(items[i].id),
//        });
//     }

//   // const marketItems: MarketItem[] = items;
//   // for (let i = 0; i < items.length; i++) {
//   //   marketitems.push({
//   //     Id: {items[i].id},
//   //     MarketId: {items[i].marketId},
//   //     Slot: {items[i].slot},
//   //     Type: {items[i].id},
//   //     Material: {items[i].id},
//   //     Rank: {items[i].id},
//   //     Prefix_1: {items[i].id},
//   //     Prefix_2: {items[i].id},
//   //     Suffix: {items[i].id},
//   //     Greatness: {items[i].id},
//   //     XP: {items[i].id},
//   //     Bidder: {items[i].id},
//   //     Price: {items[i].id},
//   //     Status: {items[i].id},
//   //     Expiry: {items[i].id},
//   //     ClaimedTime: {items[i].id},
//   //     LastUpdated: {items[i].id},
//   //     Bid: {items[i].id},
//   //   },)
//   // }

//   // const items = [
//   //   {
//   //     Id: 1,
//   //     Slot: 1,
//   //     Type: 1,
//   //     Material: 2,
//   //     Rank: 3,
//   //     Prefix_1: 1,
//   //     Prefix_2: 2,
//   //     Suffix: 1,
//   //     Greatness: 50,
//   //     CreatedBlock: 1623456789,
//   //     XP: 100,
//   //     Adventurer: 1,
//   //     Bag: 1,
//   //     Bid: 0,
//   //   },
//   //   {
//   //     Id: 2,
//   //     Slot: 2,
//   //     Type: 3,
//   //     Material: 1,
//   //     Rank: 2,
//   //     Prefix_1: 3,
//   //     Prefix_2: 4,
//   //     Suffix: 2,
//   //     Greatness: 60,
//   //     CreatedBlock: 1623456790,
//   //     XP: 200,
//   //     Adventurer: 2,
//   //     Bag: 1,
//   //     Bid: 0,
//   //   },
//   //   {
//   //     Id: 3,
//   //     Slot: 3,
//   //     Type: 2,
//   //     Material: 3,
//   //     Rank: 1,
//   //     Prefix_1: 2,
//   //     Prefix_2: 3,
//   //     Suffix: 3,
//   //     Greatness: 70,
//   //     CreatedBlock: 1623456791,
//   //     XP: 300,
//   //     Adventurer: 1,
//   //     Bag: 2,
//   //     Bid: 0,
//   //   },
//   //   {
//   //     Id: 4,
//   //     Slot: 4,
//   //     Type: 1,
//   //     Material: 1,
//   //     Rank: 4,
//   //     Prefix_1: 4,
//   //     Prefix_2: 1,
//   //     Suffix: 4,
//   //     Greatness: 80,
//   //     CreatedBlock: 1623456792,
//   //     XP: 400,
//   //     Adventurer: 3,
//   //     Bag: 2,
//   //     Bid: 0,
//   //   },
//   // ];

//   return (
//     <div className="w-full">
//       <div className="w-full">
//         <table className="w-full border-terminal-green border">
//           <thead>
//             <tr className="p-3 border-b border-terminal-green">
//               {headings.map((heading, index) => (
//                 <th key={index}>{heading}</th>
//               ))}
//               <th>Bid</th>
//             </tr>
//           </thead>
//           <tbody>
//             {marketitems.map((item, index) => (
//               <tr key={index}>
//                 {Object.values(item).map((value, index) => (
//                   <td className="p-2 text-center" key={index}>
//                     {value}
//                   </td>
//                 ))}
//                 <td className="p-2 text-center">
//                   <BidButton />
//                 </td>
//               </tr>
//             ))}
//           </tbody>
//         </table>
//       </div>
//     </div>
//   );
// };

// export default Marketplace;
