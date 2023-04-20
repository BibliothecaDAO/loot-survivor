"use client";

import { useAccount, useConnectors } from "@starknet-react/core";
import { Button } from "./components/Button";
import HorizontalKeyboardControl from "./components/HorizontalMenu";
import { useState, useEffect } from "react";
import Actions from "./components/Actions";
import Marketplace from "./components/Marketplace";
import Adventurer from "./components/Adventurer";
import Beast from "./components/Beast";
import { displayAddress } from "./lib/utils";
import { useAdventurer } from "./context/AdventurerProvider";
import { NullAdventurerProps } from "./types";
import Inventory from "./components/Inventory";
import TransactionCart from "./components/TransactionCart";
import Upgrade from "./components/Upgrade";

export default function Home() {
  const { connect, disconnect, connectors } = useConnectors();
  const { account } = useAccount();
  const { adventurer } = useAdventurer();

  const adventurerStats = adventurer ?? NullAdventurerProps;

  const upgrade = false;

  const [menu, setMenu] = useState([
    {
      id: 1,
      label: "Start",
      value: "start",
    },
  ]);

  const [selected, setSelected] = useState(menu[0].value);

  useEffect(() => {
    let newMenu = [
      {
        id: 1,
        label: "Start",
        value: "start",
      },
    ];

    if (adventurer?.adventurer) {
      newMenu = [
        ...newMenu,
        {
          id: 2,
          label: "Actions",
          value: "actions",
        },
        {
          id: 3,
          label: "Market",
          value: "market",
        },
        {
          id: 4,
          label: "Inventory",
          value: "inventory",
        },
        {
          id: 5,
          label: "Beast",
          value: "beast",
        },
      ];
    }

    setMenu(newMenu);
  }, [adventurer, account]);

  return (
    <main className={`container mx-auto p-8 flex flex-wrap`}>
      <div className="flex justify-between w-full">
        <h1>Loot Survivors</h1>
        <div className="flex flex-row gap-2 self-end">
          {account && <TransactionCart />}
          <ul className="flex flex-row gap-2">
            {account ? (
              <Button onClick={() => disconnect()}>
                {displayAddress(account.address)}
              </Button>
            ) : (
              connectors.map((connector) => (
                <li key={connector.id()}>
                  <Button onClick={() => connect(connector)}>
                    Connect {connector.id()}
                  </Button>
                </li>
              ))
            )}
          </ul>
        </div>
      </div>
      <div className="w-full h-6 my-2 bg-terminal-green"></div>

      {account ? (
        <div className="w-full">
          {adventurer?.adventurer ? (
            <div className="absolute bottom-1 w-5/6 flex flew-row font-medium bg-terminal-black text-white justify-evenly ml-3">
              {adventurerStats.adventurer?.name}
              <p className="text-lg">
                HEALTH: {adventurerStats.adventurer?.health}
              </p>
              <p className="text-lg ">
                GOLD: {adventurerStats.adventurer?.gold}
              </p>
              <p className="text-lg">
                BEAST: {adventurerStats.adventurer?.beast}
              </p>
              <p className="text-lg">
                LEVEL: {adventurerStats.adventurer?.level}
              </p>
              <p className="text-lg">XP: {adventurerStats.adventurer?.xp}</p>
            </div>
          ) : null}

          {!upgrade ? (
            <>
              <div className="gap-10 pb-2">
                <HorizontalKeyboardControl
                  buttonsData={menu}
                  onButtonClick={(value) => {
                    setSelected(value);
                  }}
                />
              </div>

              {selected === "start" && <Adventurer />}
              {selected === "actions" && <Actions />}
              {selected === "market" && <Marketplace />}
              {selected === "inventory" && <Inventory />}
              {selected === "beast" && <Beast />}
            </>
          ) : (
            <Upgrade />
          )}
        </div>
      ) : (
        <div className="flex w-full mt-[200px]">
          <p className="mx-auto items-center text-[50px] animate-pulse">
            Please Connect Wallet
          </p>
        </div>
      )}
    </main>
  );
}
