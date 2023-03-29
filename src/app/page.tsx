"use client";

import { useConnectors } from "@starknet-react/core";
import { Button } from "./components/Button";
import HorizontalKeyboardControl from "./components/HorizontalMenu";
import { useState } from "react";
import Explore from "./components/Explore";
import Marketplace from "./components/Marketplace";
import Adventurer from "./components/Adventurer";

export default function Home() {
  const { connect, connectors } = useConnectors();
  const [selected, setSelected] = useState("start");

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
      <div className="flex justify-between w-full">
        <h1>Loot Survivors</h1>
        <ul className="self-end">
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
        <div className="w-full h-4 my-2 bg-terminal-green"></div>
        <HorizontalKeyboardControl
          buttonsData={menu}
          onButtonClick={(value) => setSelected(value)}
        />

        {/* <Button onClick={() => addToCalls(tx)}>start</Button>
        <Button onClick={() => write()}>start</Button> */}

        {selected === "start" && <Adventurer />}
        {selected === "explore" && <Explore />}
        {selected === "market" && <Marketplace />}
      </div>
    </main>
  );
}
