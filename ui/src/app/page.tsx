"use client";
import { StarknetConfig } from "@starknet-react/core";
import { useAccount, useConnectors } from "@starknet-react/core";
import { useState, useEffect } from "react";
import { Button } from "./components/Button";
import HorizontalKeyboardControl, {
  ButtonData,
} from "./components/HorizontalMenu";
import Actions from "./components/Actions";
import Marketplace from "./components/Marketplace";
import Adventurer from "./components/Adventurer";
import BattleScene from "./components/BattleScene";
import Beast from "./components/Beast";
import { displayAddress } from "./lib/utils";
import Inventory from "./components/Inventory";
import TransactionHistory from "./components/TransactionHistory";
import TransactionCart from "./components/TransactionCart";
import Upgrade from "./components/Upgrade";
import Intro from "./components/Intro";
import {
  AddDevnetEthButton,
  MintEthButton,
} from "./components/DevnetConnectors";
import Leaderboard from "./components/Leaderboard";
import { TxActivity } from "./components/TxActivity";
import useLoadingStore from "./hooks/useLoadingStore";
import useAdventurerStore from "./hooks/useAdventurerStore";
import usePrevious from "use-previous";
import { useLazyQuery } from "@apollo/client";
import { getAdventurerById } from "./hooks/graphql/queries";
import useUIStore from "./hooks/useUIStore";
import useIndexerStore from "./hooks/useIndexerStore";
import useTransactionCartStore from "./hooks/useTransactionCartStore";
import { useMusic, musicSelector } from "./hooks/useMusic";
import { testnet_addr } from "./lib/constants";

export default function Home() {
  const { disconnect } = useConnectors();
  const { account } = useAccount();
  const [isMuted, setIsMuted] = useState(false);

  const loading = useLoadingStore((state) => state.loading);
  const stopLoading = useLoadingStore((state) => state.stopLoading);
  const data = useLoadingStore((state) => state.data);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const calls = useTransactionCartStore((state) => state.calls);
  const onboarded = useUIStore((state) => state.onboarded);
  const setOnboarded = useUIStore((state) => state.setOnboarded);
  const setIndexer = useIndexerStore((state) => state.setIndexer);
  const [showBattleScene, setShowBattleScene] = useState(true);
  const upgrade = adventurer?.upgrading;

  const { play, stop } = useMusic(musicSelector.backgroundMusic, {
    volume: 0.5,
    loop: true,
    isMuted: isMuted,
  });

  useEffect(() => {
    // play();

    return () => {
      stop();
    };
  }, [play, stop]);

  const [menu, setMenu] = useState<ButtonData[]>([
    {
      id: 1,
      label: "Start",
      value: "start",
      disabled: false,
    },
  ]);

  const [selected, setSelected] = useState(menu[0].value);
  const hasBeast = !!adventurer?.beastId;

  useEffect(() => {
    if (!adventurer || adventurer?.health == 0) {
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
      (account as any)?.baseUrl == testnet_addr ||
        (account as any)?.provider?.baseUrl == "https://alpha4.starknet.io"
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
        disabled: false,
      },
    ];

    if (adventurer && adventurer.health > 0) {
      newMenu = [
        ...newMenu,
        {
          id: 2,
          label: "Actions",
          value: "actions",
          disabled: hasBeast,
        },
        {
          id: 3,
          label: "Market",
          value: "market",
          disabled: hasBeast,
        },
        {
          id: 4,
          label: "Inventory",
          value: "inventory",
          disabled: false,
        },
        {
          id: 5,
          label: "Beast",
          value: "beast",
          disabled: false,
        },
        {
          id: 6,
          label: "Leaderboard",
          value: "leaderboard",
          disabled: hasBeast,
        },
      ];
    }

    setMenu(newMenu);
  }, [adventurer, account]);

  const [getData, _] = useLazyQuery(getAdventurerById, {
    onCompleted: (data) => {
      setAdventurer(data.adventurers[0]);
    },
  });

  useEffect(() => {
    if (adventurer) {
      getData({
        variables: {
          id: adventurer?.id,
        },
      });
    }
  }, [adventurer]);

  const prevData = usePrevious(data);

  useEffect(() => {
    if (
      loading &&
      data &&
      prevData &&
      JSON.stringify(data) !== JSON.stringify(prevData)
    ) {
      stopLoading();
    }
  }, [loading, data, prevData, stopLoading]);

  return (
    <main className={`min-h-screen container mx-auto flex flex-col p-10`}>
      {onboarded ? (
        <>
          <div className="flex justify-between w-full ">
            <h1 className="glitch">Loot Survivors</h1>
            <div className="flex flex-row self-end gap-2">
              <TxActivity />
              <Button onClick={() => setIsMuted(!isMuted)}>
                {isMuted ? "Unmute" : "Mute"}
              </Button>
              {account && calls.length > 0 && <TransactionCart />}
              {account && <TransactionHistory />}
              {(account as any)?.baseUrl == testnet_addr && (
                <AddDevnetEthButton />
              )}
              {(account as any)?.baseUrl == testnet_addr && <MintEthButton />}
              {account && (
                <Button onClick={() => disconnect()}>
                  {displayAddress(account.address)}
                </Button>
              )}
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
                  {selected === "beast" &&
                    (showBattleScene ? <BattleScene /> : <Beast />)}
                  {selected === "leaderboard" && <Leaderboard />}
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
