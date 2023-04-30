import React, { useState, ChangeEvent, FormEvent, useEffect } from "react";
import { useContracts } from "../hooks/useContracts";
import { useTransactionCart } from "../context/TransactionCartProvider";
import { stringToFelt } from "../lib/utils";
import {
  useAccount,
  useWaitForTransaction,
  useTransactionManager,
  useTransactions,
  useTransaction,
} from "@starknet-react/core";
import { getKeyFromValue } from "../lib/utils";
import { GameData } from "./GameData";

export interface CreateAdventurerProps {
  isActive: boolean;
  onEscape: () => void;
}

interface FormData {
  name: string;
  race: string;
  homeRealmId: string;
  order: string;
  startingWeapon: string;
  imageHash1: string;
  imageHash2: string;
  interfaceaddress: string;
}

export const CreateAdventurer = ({
  isActive,
  onEscape,
}: CreateAdventurerProps) => {
  const { account } = useAccount();
  const { hashes, addTransaction } = useTransactionManager();
  const currentHash = hashes[hashes.length - 1];
  const currentTransaction = useTransaction({ hash: currentHash });
  const formatAddress = account ? account.address : "0x0";
  const [formData, setFormData] = useState<FormData>({
    name: "",
    race: "",
    homeRealmId: "1",
    order: "",
    startingWeapon: "",
    imageHash1: "1",
    imageHash2: "1",
    interfaceaddress:
      "0x12e0839c07c8fac67dd47a88e38317e0a56180faacf5e81f78d09a4c6338021",
  });

  const { handleSubmitCalls, addToCalls, calls } = useTransactionCart();
  const { adventurerContract, lordsContract } = useContracts();
  const [hash, setHash] = useState<string | undefined>(undefined);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const transactions = useTransactions({ hashes });

  const { data, isLoading, error } = useWaitForTransaction({
    hash,
    watch: true,
  });

  const gameData = new GameData();

  const handleChange = (
    e: ChangeEvent<HTMLInputElement | HTMLSelectElement>
  ) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value,
    });
  };

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const mintLords = {
      contractAddress: lordsContract?.address,
      selector: "mint",
      calldata: [formatAddress, (100 * 10 ** 18).toString(), "0"],
    };
    addToCalls(mintLords);

    const approveLords = {
      contractAddress: lordsContract?.address,
      selector: "approve",
      calldata: [adventurerContract?.address, (100 * 10 ** 18).toString(), "0"],
    };
    addToCalls(approveLords);

    const mintAdventurer = {
      contractAddress: adventurerContract?.address,
      selector: "mint_with_starting_weapon",
      calldata: [
        formatAddress,
        getKeyFromValue(gameData.RACES, formData.race)?.toString(),
        formData.homeRealmId,
        stringToFelt(formData.name),
        getKeyFromValue(gameData.ORDERS, formData.order),
        formData.imageHash1,
        formData.imageHash2,
        getKeyFromValue(gameData.ITEMS, formData.startingWeapon),
        formData.interfaceaddress,
      ],
    };
    addToCalls(mintAdventurer);
    await handleSubmitCalls().then((tx: any) => {
      setHash(tx.transaction_hash);
      addTransaction({
        hash: tx.transaction_hash,
        metadata: {
          method: "Minting adventurer",
          description: "Adventurer is being minted!",
        },
      });
    });
  };

  // const handleKeyDown = (event: React.KeyboardEvent<HTMLInputElement>) => {
  //   if (event.key === "ArrowDown" || event.key === "ArrowUp") {
  //     const form = event.currentTarget.form;
  //     if (!form) return;

  //     const inputs = Array.from(form.querySelectorAll("input, select"));
  //     const currentIndex = inputs.indexOf(event.currentTarget);
  //     const newIndex =
  //       event.key === "ArrowDown"
  //         ? Math.min(currentIndex + 1, inputs.length - 1)
  //         : Math.max(currentIndex - 1, 0);
  //     (inputs[newIndex] as HTMLElement).focus();
  //     event.preventDefault();
  //   }
  // };

  const handleKeyDown = (
    event: React.KeyboardEvent<HTMLInputElement> | KeyboardEvent
  ) => {
    if (!event.currentTarget) return;
    const form = (event.currentTarget as HTMLElement).closest("form");
    if (!form) return;
    const inputs = Array.from(form.querySelectorAll("input, select"));
    switch (event.key) {
      case "ArrowDown":
        setSelectedIndex((prev) => {
          const newIndex = Math.min(prev + 1, inputs.length - 1);
          return newIndex;
        });
        break;
      case "ArrowUp":
        setSelectedIndex((prev) => {
          const newIndex = Math.max(prev - 1, 0);
          return newIndex;
        });
        break;
      // case "Enter":
      //   onEnterAction && buttonsData[selectedIndex].action();
      //   break;
      case "Escape":
        onEscape();
        break;
    }
    (inputs[selectedIndex] as HTMLElement).focus();
  };

  useEffect(() => {
    if (isActive) {
      window.addEventListener("keydown", handleKeyDown);
    } else {
      window.removeEventListener("keydown", handleKeyDown);
    }
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [isActive, selectedIndex]);

  const loading = data?.status == "RECEIVED" || data?.status == "PENDING";

  return (
    <div className="flex flex-row w-full">
      <div className="flex items-center w-1/2 mx-2 text-lg border border-terminal-green">
        <div className="flex flex-row w-full gap-2 p-1">
          <form
            onSubmit={handleSubmit}
            className="flex flex-col w-full gap-2 p-1 text-2xl"
          >
            <label className="flex justify-between">
              <span className="self-center">Name:</span>

              <input
                type="text"
                name="name"
                onChange={handleChange}
                className="p-1 m-2 bg-terminal-black"
                onKeyDown={handleKeyDown}
              />
            </label>
            <label className="flex justify-between">
              <span className="self-center">Race:</span>
              <select
                name="race"
                onChange={handleChange}
                className="p-1 m-2 bg-terminal-black"
              >
                <option value="">Select a race</option>
                <option value="Elf">Elf</option>
                <option value="Fox">Fox</option>
                <option value="Giant">Giant</option>
                <option value="Human">Human</option>
                <option value="Orc">Orc</option>
                <option value="Demon">Demon</option>
                <option value="Goblin">Goblin</option>
                <option value="Fish">Fish</option>
                <option value="Cat">Cat</option>
                <option value="Frog">Frog</option>
              </select>
            </label>
            <label className="flex justify-between">
              <span className="self-center">Home Realm:</span>
              <input
                type="number"
                name="homeRealmId"
                min="1"
                max="8000"
                onChange={handleChange}
                className="p-1 m-2 bg-terminal-black"
              />
            </label>
            <label className="flex justify-between">
              <span className="self-center">Order of Divinity:</span>
              <select
                name="order"
                onChange={handleChange}
                className="p-1 m-2 bg-terminal-black"
              >
                <option value="">Select an order</option>
                <optgroup label="Order of Light">
                  <option value="Power">Power</option>
                  <option value="Giants">Giants</option>
                  <option value="Perfection">Perfection</option>
                  <option value="Brilliance">Brilliance</option>
                  <option value="Enlightenment">Enlightenment</option>
                  <option value="Protection">Protection</option>
                  <option value="Skill">Skill</option>
                  <option value="Titans">Titans</option>
                </optgroup>
                <optgroup label="Order of Dark">
                  <option value="Twins">Twins</option>
                  <option value="Detection">Detection</option>
                  <option value="Reflection">Reflection</option>
                  <option value="Fox">Fox</option>
                  <option value="Vitriol">Vitriol</option>
                  <option value="Fury">Fury</option>
                  <option value="Rage">Rage</option>
                  <option value="Anger">Anger</option>
                </optgroup>
              </select>
            </label>
            <label className="flex justify-between">
              <span className="self-center">Starting Weapon:</span>
              <select
                name="startingWeapon"
                onChange={handleChange}
                className="p-1 m-2 bg-terminal-black"
              >
                <option value="">Select a weapon</option>
                <option value="Wand">Wand</option>
                <option value="Book">Book</option>
                <option value="ShortSword">Short Sword</option>
                <option value="Club">Club</option>
              </select>
            </label>
            <button
              type="submit"
              className="p-2 m-2 border bg-terminal-black border-terminal-green hover:bg-terminal-green/80 hover:animate-pulse hover:text-black"
            >
              Spawn
            </button>
          </form>
        </div>
      </div>
      <div className="flex flex-col w-1/2">
        {loading && hash && <div className="loading-ellipsis">Loading</div>}
        {hash && <div className="flex flex-col">Hash: {hash}</div>}
        {/* {error && <div>Error: {JSON.stringify(error)}</div>} */}
        {data && <div>Status: {data.status}</div>}
      </div>
    </div>
  );
};
