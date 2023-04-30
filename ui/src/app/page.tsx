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
import {
  AddDevnetEthButton,
  MintEthButton,
} from "./components/DevnetConnectors";

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
      (account as any)?.baseUrl ==
        "http://survivor-indexer.bibliothecadao.xyz:5050"
        ? "https://survivor-indexer.bibliothecadao.xyz:8080/devnet-graphql"
        : "https://survivor-indexer.bibliothecadao.xyz:8080/goerli-graphql"
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
    <main className={`min-h-screen container mx-auto flex flex-col bezel`}>
      {onboarded ? (
        <>
          <div className="flex justify-between w-full ">
            <h1>Loot Survivors</h1>
            <div className="flex flex-row self-end gap-2">
              {account && calls.length > 0 && <TransactionCart />}
              {account && <TransactionHistory />}
              {account && <AddDevnetEthButton />}
              {account && <MintEthButton />}
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
            <div className="flex-grow w-full">
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
              {/* {adventurer?.adventurer ? (
                <div className="fixed flex items-center w-5/6 text-lg text-white transform -translate-x-1/2 border-2 bottom-1 left-1/2 flew-row bg-terminal-black border-terminal-green justify-evenly">
                  {adventurerStats.adventurer?.name}
                  <p>HEALTH: {adventurerStats.adventurer?.health}</p>
                  <p>GOLD: {adventurerStats.adventurer?.gold}</p>
                  <p>LEVEL: {adventurerStats.adventurer?.level}</p>
                  <p>XP: {adventurerStats.adventurer?.xp}</p>
                </div>
              ) : null} */}
            </div>
          ) : null}
        </>
      ) : (
        <Intro />
      )}
    </main>
  );
}
