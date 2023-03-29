"use client";

import { useConnectors } from "@starknet-react/core";
import { useWriteContract } from "./hooks/useWriteContract";
import { useContracts } from "./hooks/useContracts";
import KeyboardControl, { ButtonData } from "./components/KeyboardControls";
import { Button } from "./components/Button";
import HorizontalKeyboardControl from "./components/HorizontalMenu";
import { useState } from "react";
import Explore from "./components/Explore";
import Marketplace from "./components/Marketplace";
import Adventurer from "./components/Adventurer";

export default function Home() {
  const { connect, connectors } = useConnectors();

  const { write, addToCalls } = useWriteContract();

  const { AdventurerContract } = useContracts();

  const [selected, setSelected] = useState("start");

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
      action: () => write(),
    },
    {
      id: 3,
      label: "Buy",
      action: () => console.log("Button 3 clicked"),
    },
  ];

  const menu = [
    {
      id: 1,
      label: "Start",
      value: "start",
    },
    {
      id: 2,
      label: "Explore",
      value: "explore",
    },
    {
      id: 3,
      label: "Market",
      value: "market",
    },
  ];

  return (
    <main className={`container mx-auto p-8 flex flex-wrap`}>
      <div className="w-full">
        <ul>
          {connectors.map((connector) => (
            <li key={connector.id()}>
              <Button onClick={() => connect(connector)}>
                Connect {connector.id()}
              </Button>
            </li>
          ))}
        </ul>
      </div>

      <div className="w-full">
        <div className="h-4 bg-terminal-green w-full my-2"></div>
        <HorizontalKeyboardControl
          buttonsData={menu}
          onButtonClick={(value) => setSelected(value)}
        />
        <h1>Loot Survivors</h1>
        {/* <Button onClick={() => addToCalls(tx)}>start</Button>
        <Button onClick={() => write()}>start</Button> */}

        {selected === "start" && <Adventurer />}
        {selected === "explore" && <Explore />}
        {selected === "market" && <Marketplace />}

        {/* market component */}
        {/* <Market /> */}
      </div>
    </main>
  );
}
