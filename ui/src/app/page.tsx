"use client";

import { useAccount, useConnectors, useNetwork } from "@starknet-react/core";
import { useState, useEffect } from "react";
import { useAdventurer } from "./context/AdventurerProvider";
import { useTransactionCart } from "./context/TransactionCartProvider";
import { Button } from "./components/Button";
import HorizontalKeyboardControl from "./components/HorizontalMenu";
import Actions from "./components/Actions";
import Marketplace from "./components/Marketplace";
import Adventurer from "./components/Adventurer";
import Beast from "./components/Beast";
import { displayAddress } from "./lib/utils";
import { NullAdventurerProps } from "./types";
import Inventory from "./components/Inventory";
import TransactionHistory from "./components/TransactionHistory";
import TransactionCart from "./components/TransactionCart";
import Upgrade from "./components/Upgrade";
import Intro from "./components/Intro";
import { useUI } from "./context/UIProvider";
import { useIndexer } from "./context/IndexerProvider";

export default function Home() {
  const { connect, disconnect, connectors } = useConnectors();
  const { account } = useAccount();
  const { adventurer } = useAdventurer();
  const { calls } = useTransactionCart();
  const { onboarded, setOnboarded } = useUI();
  const { setIndexer } = useIndexer();

  const adventurerStats = adventurer ?? NullAdventurerProps;

  const upgrade = adventurer?.adventurer?.upgrading;

  const [menu, setMenu] = useState([
    {
      id: 1,
      label: "Start",
      value: "start",
    },
  ]);

  const [selected, setSelected] = useState(menu[0].value);

  useEffect(() => {
    if (!adventurer || adventurer.adventurer?.health == 0) {
      setSelected(menu[0].value);
    }
  }, [adventurer]);

  useEffect(() => {
    if (!account?.address) {
      setOnboarded(false);
    }
  }, [account]);

  useEffect(() => {
    setIndexer(
      (account as any)?.baseUrl == "http://3.215.42.99:5050"
        ? "http://3.215.42.99:8081/graphql"
        : "http://3.215.42.99:8080/graphql"
    );
  }, [account]);

  useEffect(() => {
    let newMenu = [
      {
        id: 1,
        label: "Start",
        value: "start",
      },
    ];

    if (adventurer?.adventurer && adventurer?.adventurer.health > 0) {
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
    <main className={`container mx-auto flex flex-wrap h-[520px]`}>
      {onboarded ? (
        <>
          <div className="flex justify-between w-full ">
            <h1>Loot Survivors</h1>
            <div className="flex flex-row gap-2 self-end">
              {account && calls.length > 0 && <TransactionCart />}
              {account && <TransactionHistory />}
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
          <div className="w-full h-6 my-2 bg-terminal-green" />

          {account ? (
            <div className="w-full">
              {adventurer?.adventurer ? (
                <div className="fixed text-lg w-[1280px] bottom-1 flex flew-row items-center bg-terminal-black border-2 border-terminal-green text-white justify-evenly">
                  {adventurerStats.adventurer?.name}
                  <p>HEALTH: {adventurerStats.adventurer?.health}</p>
                  <p>GOLD: {adventurerStats.adventurer?.gold}</p>
                  <p>LEVEL: {adventurerStats.adventurer?.level}</p>
                  <p>XP: {adventurerStats.adventurer?.xp}</p>
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
          ) : null}
        </>
      ) : (
        <Intro />
      )}
    </main>
  );
}
