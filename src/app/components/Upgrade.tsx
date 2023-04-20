import KeyboardControl from "./KeyboardControls";
import { useContracts } from "../hooks/useContracts";
import { useWriteContract } from "../hooks/useWriteContract";
import { useAdventurer } from "../context/AdventurerProvider";

const Upgrade = () => {
  const { adventurerContract } = useContracts();
  const { adventurer } = useAdventurer();

  // const upgradeMenu = [
  //   {
  //     id: 1,
  //     label: "Choose Adventurer",
  //     value: "choose adventurer",
  //     action: () => setSelected,
  //   },
  //   {
  //     id: 2,
  //     label: "Create Adventurer",
  //     value: "create adventurer",
  //     action: () => setSelected,
  //   },
  //   {
  //     id: 3,
  //     label: "About",
  //     value: "about",
  //     action: () => setSelected,
  //   },
  //   {
  //     id: 3,
  //     label: "About",
  //     value: "about",
  //     action: () => setSelected,
  //   },
  //   {
  //     id: 3,
  //     label: "About",
  //     value: "about",
  //     action: () => setSelected,
  //   },
  // ];

  // const upgradeTx = {
  //   contractAddress: adventurerContract?.address,
  //   selector: "upgrade_stat",
  //   calldata: [adventurer?.adventurer?.id || 0, "0", lookup(stat)],
  // };

  return (
    <div className="flex flex-col gap-10 w-full mt-[100px]">
      <p className="mx-auto items-center text-[80px] animate-pulse">
        Please select upgrade!
      </p>
      <div className="flex flex-row">
        <div className="w-1/2">
          {/* <KeyboardControl buttonsData={upgradeMenu} /> */}
        </div>
        <div className="w-1/2 bg-black border"></div>
      </div>
    </div>
  );
};

export default Upgrade;
