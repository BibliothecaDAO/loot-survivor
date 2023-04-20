import React, { useState, ChangeEvent, FormEvent } from "react";
import { useContracts } from "../hooks/useContracts";
import { useTransactionCart } from "../context/TransactionCartProvider";
import { stringToFelt } from "../lib/utils";
import {
  useAccount,
  useWaitForTransaction,
  useTransactionManager,
  useTransactions,
} from "@starknet-react/core";
import { getValueFromKey, getKeyFromValue } from "../lib/utils";
import { GameData } from "./GameData";
import { Button } from "./Button";

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

const FormComponent: React.FC = () => {
  const { account } = useAccount();
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

  const { writeAsync, addToCalls, calls } = useTransactionCart();
  const { adventurerContract, lordsContract } = useContracts();
  const [hash, setHash] = useState<string | undefined>(undefined);
  const { hashes, addTransaction } = useTransactionManager();
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
    console.log(formData);
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
    console.log(calls);
    await writeAsync().then((tx: any) => {
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

  const handleKeyDown = (event: React.KeyboardEvent<HTMLInputElement>) => {
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      const form = event.currentTarget.form;
      if (!form) return;

      const inputs = Array.from(form.querySelectorAll("input, select"));
      const currentIndex = inputs.indexOf(event.currentTarget);
      const newIndex =
        event.key === "ArrowDown"
          ? Math.min(currentIndex + 1, inputs.length - 1)
          : Math.max(currentIndex - 1, 0);
      (inputs[newIndex] as HTMLElement).focus();
      event.preventDefault();
    }
  };

  return (
    <div className="flex flex-row items-center mx-2 text-lg">
      <div className="flex p-1 flex-col gap-2">
        <form onSubmit={handleSubmit} className="flex p-1 flex-col gap-2">
          <label>
            Name:
            <input
              type="text"
              name="name"
              onChange={handleChange}
              className="bg-terminal-black m-2"
              onKeyDown={handleKeyDown}
            />
          </label>
          <label>
            Race:
            <select
              name="race"
              onChange={handleChange}
              className="bg-terminal-black m-2"
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
          <label>
            Home Realm ID:
            <input
              type="number"
              name="homeRealmId"
              min="1"
              max="8000"
              onChange={handleChange}
              className="bg-terminal-black m-2"
            />
          </label>
          <label>
            Order of Divinity:
            <select
              name="order"
              onChange={handleChange}
              className="bg-terminal-black m-2"
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
          <label>
            Starting Weapon:
            <select
              name="startingWeapon"
              onChange={handleChange}
              className="bg-terminal-black m-2"
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
            className="bg-terminal-black border border-terminal-green m-2 p-2 hover:bg-terminal-green/80 hover:animate-pulse hover:text-black"
          >
            Submit
          </button>
        </form>
        <>
          {hash && <div className="flex flex-col">Hash: {hash}</div>}
          {isLoading && hash && (
            <div className="loading-ellipsis">Loading...</div>
          )}
          {error && <div>Error: {JSON.stringify(error)}</div>}
          {data && <div>Status: {data.status}</div>}
        </>
      </div>
    </div>
  );
};

export default FormComponent;
