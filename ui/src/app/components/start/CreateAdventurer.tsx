import React, {
  useState,
  ChangeEvent,
  FormEvent,
  useEffect,
  useCallback,
} from "react";
import { useContracts } from "../../hooks/useContracts";
import { stringToFelt } from "../../lib/utils";
import {
  useAccount,
  useTransactionManager,
  useContractWrite,
} from "@starknet-react/core";
import { getKeyFromValue } from "../../lib/utils";
import { GameData } from "../GameData";
import useLoadingStore from "../../hooks/useLoadingStore";
import useTransactionCartStore from "../../hooks/useTransactionCartStore";
import useUIStore from "../../hooks/useUIStore";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import { FormData, Adventurer } from "@/app/types";

export interface CreateAdventurerProps {
  isActive: boolean;
  onEscape: () => void;
  adventurers: Adventurer[];
}

export const CreateAdventurer = ({
  isActive,
  onEscape,
  adventurers,
}: CreateAdventurerProps) => {
  const { account } = useAccount();
  const { addTransaction } = useTransactionManager();
  const formatAddress = account ? account.address : "0x0";
  const [formData, setFormData] = useState<FormData>({
    startingWeapon: "",
    name: "",
    homeRealmId: "1",
    race: "",
    order: "",
  });
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const setScreen = useUIStore((state) => state.setScreen);

  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const handleSubmitCalls = useTransactionCartStore(
    (state) => state.handleSubmitCalls
  );
  const startLoading = useLoadingStore((state) => state.startLoading);
  const setTxHash = useLoadingStore((state) => state.setTxHash);
  const { writeAsync } = useContractWrite({ calls });
  const { gameContract, lordsContract } = useContracts();
  const [selectedIndex, setSelectedIndex] = useState(0);
  const gameData = new GameData();
  const [firstAdventurer, setFirstAdventurer] = useState(false);

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
      contractAddress: lordsContract?.address ?? "",
      entrypoint: "mint",
      calldata: [formatAddress, (100 * 10 ** 18).toString(), "0"],
    };
    addToCalls(mintLords);

    const approveLordsTx = {
      contractAddress: lordsContract?.address ?? "",
      entrypoint: "approve",
      calldata: [gameContract?.address ?? "", (100 * 10 ** 18).toString(), "0"],
    };
    addToCalls(approveLordsTx);

    const mintAdventurerTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "start",
      calldata: [
        getKeyFromValue(gameData.ITEMS, formData.startingWeapon) ?? "",
        parseInt(stringToFelt(formData.name)).toString(),
        formData.homeRealmId,
        getKeyFromValue(gameData.RACES, formData.race)?.toString() ?? "",
        getKeyFromValue(gameData.ORDERS, formData.order) ?? "",
        "1",
      ],
    };

    console.log(mintAdventurerTx);

    // const mintAdventurerTx = {
    //   contractAddress: gameContract?.address ?? "",
    //   entrypoint: "start",
    //   calldata: [
    //     getKeyFromValue(gameData.ITEMS, formData.startingWeapon) ?? "",
    //     "0",
    //     "0",
    //     "0",
    //     "0",
    //     "0",
    //   ],
    // };

    console.log(mintAdventurerTx);
    addToCalls(mintAdventurerTx);
    startLoading(
      "Create",
      "Spawning Adventurer",
      "adventurersByOwnerQuery",
      undefined,
      `You have spawned ${formData.name}!`
    );
    await handleSubmitCalls(writeAsync).then((tx: any) => {
      if (tx) {
        setTxHash(tx.transaction_hash);
        addTransaction({
          hash: tx?.transaction_hash,
          metadata: {
            method: `Spawn ${formData.name}`,
          },
        });
      }
    });
    if (!adventurers[0]) {
      setFirstAdventurer(true);
    }
  };

  const handleKeyDown = useCallback(
    (event: React.KeyboardEvent<HTMLInputElement> | KeyboardEvent) => {
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
        case "Escape":
          onEscape();
          break;
      }
      (inputs[selectedIndex] as HTMLElement).focus();
    },
    [selectedIndex, onEscape]
  );

  useEffect(() => {
    if (isActive) {
      window.addEventListener("keydown", handleKeyDown);
    } else {
      window.removeEventListener("keydown", handleKeyDown);
    }
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [isActive, selectedIndex, handleKeyDown]);

  useEffect(() => {
    if (adventurers[0] && firstAdventurer) {
      setScreen("actions");
      setAdventurer(adventurers[0]);
    }
  }, [adventurers, firstAdventurer, setAdventurer, setScreen]);

  return (
    <div className="flex items-center sm:w-1/2 mx-4 border border-terminal-green">
      <div className="flex flex-row w-full gap-2 p-2">
        <form
          onSubmit={handleSubmit}
          className="flex flex-col w-full gap-2 p-1 text-lg sm:text-2xl"
        >
          <label className="flex justify-between">
            <span className="self-center">Name:</span>

            <input
              type="text"
              name="name"
              onChange={handleChange}
              className="p-1 m-2 bg-terminal-black border border-slate-500"
              onKeyDown={handleKeyDown}
              maxLength={31}
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
              className="p-1 m-2 bg-terminal-black border border-slate-500"
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
              <option value="Short Sword">Short Sword</option>
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
  );
};
