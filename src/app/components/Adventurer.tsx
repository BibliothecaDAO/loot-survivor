import { useContracts } from "../hooks/useContracts";
import { useWriteContract } from "../hooks/useWriteContract";
import KeyboardControl, { ButtonData } from "./KeyboardControls";

const Adventurer = () => {
  const { writeAsync, addToCalls } = useWriteContract();
  const { AdventurerContract } = useContracts();

  const tx = {
    contractAddress: AdventurerContract?.address,
    entrypoint: "mint",
    calldata: [],
  };

  const buttonsData: ButtonData[] = [
    {
      id: 1,
      label: "Start",
      action: () => addToCalls(tx),
    },
    {
      id: 2,
      label: "Explore",
      action: async () => await writeAsync(),
    },
    {
      id: 3,
      label: "Buy",
      action: () => console.log("Button 3 clicked"),
    },
  ];
  return (
    <div>
      <KeyboardControl buttonsData={buttonsData} />
    </div>
  );
};

export default Adventurer;
