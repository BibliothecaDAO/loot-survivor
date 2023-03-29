import { Button } from "./Button";

const Marketplace = () => {
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

  const items = [
    {
      Id: 1,
      Slot: 1,
      Type: 1,
      Material: 2,
      Rank: 3,
      Prefix_1: 1,
      Prefix_2: 2,
      Suffix: 1,
      Greatness: 50,
      CreatedBlock: 1623456789,
      XP: 100,
      Adventurer: 1,
      Bag: 1,
      Bid: 0,
    },
    {
      Id: 2,
      Slot: 2,
      Type: 3,
      Material: 1,
      Rank: 2,
      Prefix_1: 3,
      Prefix_2: 4,
      Suffix: 2,
      Greatness: 60,
      CreatedBlock: 1623456790,
      XP: 200,
      Adventurer: 2,
      Bag: 1,
      Bid: 0,
    },
    {
      Id: 3,
      Slot: 3,
      Type: 2,
      Material: 3,
      Rank: 1,
      Prefix_1: 2,
      Prefix_2: 3,
      Suffix: 3,
      Greatness: 70,
      CreatedBlock: 1623456791,
      XP: 300,
      Adventurer: 1,
      Bag: 2,
      Bid: 0,
    },
    {
      Id: 4,
      Slot: 4,
      Type: 1,
      Material: 1,
      Rank: 4,
      Prefix_1: 4,
      Prefix_2: 1,
      Suffix: 4,
      Greatness: 80,
      CreatedBlock: 1623456792,
      XP: 400,
      Adventurer: 3,
      Bag: 2,
      Bid: 0,
    },
  ];

  return (
    <div className="w-full">
      <h1>Marketplace</h1>
      <div className="w-full">
        <table className="w-full border-terminal-green border">
          <thead>
            <tr className="p-3 border-b border-terminal-green">
              {headings.map((heading, index) => (
                <th key={index}>{heading}</th>
              ))}
              <th>Buy</th>
            </tr>
          </thead>
          <tbody>
            {items.map((item, index) => (
              <tr key={index}>
                {Object.values(item).map((value, index) => (
                  <td className="p-2 text-center" key={index}>
                    {value}
                  </td>
                ))}
                <td className="p-2 text-center">
                  <Button>Buy</Button>
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
