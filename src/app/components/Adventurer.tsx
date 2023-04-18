import { useState } from "react";
import { useContracts } from "../hooks/useContracts";
import { useWriteContract } from "../hooks/useWriteContract";
import { useAdventurer } from "../context/AdventurerProvider";
import { useQuery } from "@apollo/client";
import { AdventurersList } from "./AdventurersList";
import { CreateAdventurer } from "./CreateAdventurer";
import About from "./About";
import VerticalKeyboardControl from "./VerticalMenu";

const Adventurer = () => {
  const { writeAsync, addToCalls } = useWriteContract();
  const { adventurerContract } = useContracts();
  const { adventurer, handleUpdateAdventurer } = useAdventurer();
  const [selected, setSelected] = useState<String>("");

  // const navigateToAdventurersList = () => {
  //   setSelected("choose adventurer");
  // };

  // const navigateToCreateAdventurer = () => {
  //   setSelected("create adventurer");
  // };

  // const navigateToAbout = () => {
  //   setSelected("about");
  // };

  const menu = [
    {
      id: 1,
      label: "Choose Adventurer",
      value: "choose adventurer",
      action: () => setSelected,
    },
    {
      id: 2,
      label: "Create Adventurer",
      value: "create adventurer",
      action: () => setSelected,
    },
    {
      id: 3,
      label: "About",
      value: "about",
      action: () => setSelected,
    },
  ];

  return (
    <div className="flex flex-row gap-2">
      <div className="w-1/3 my-7">
        <VerticalKeyboardControl
          buttonsData={menu}
          onButtonClick={(value) => setSelected(value)}
          // onEnterPress={
          //   selected === "choose adventurer"
          //     ? navigateToAdventurersList
          //     : undefined
          // }
        />
      </div>

      {selected === "choose adventurer" && (
        <div className="w-2/3">
          <AdventurersList />
        </div>
      )}
      {selected === "create adventurer" && (
        <div className="w-2/3">
          <CreateAdventurer />
        </div>
      )}
      {selected === "about" && (
        <div className="w-2/3">
          <About />
        </div>
      )}
    </div>
  );
};

export default Adventurer;
