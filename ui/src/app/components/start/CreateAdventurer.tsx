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
import { getRealmNameById } from "../../lib/utils";
import { Button } from "../buttons/Button";

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
    homeRealmId: "",
    race: ""
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
        "0x043f721181BdA07742453f9C9C0AD27a6c04e39D665B73A583b2E5c166B6F77e",
        getKeyFromValue(gameData.ITEMS, formData.startingWeapon) ?? "",
        parseInt(stringToFelt(formData.name)).toString(),
        formData.homeRealmId,
        getKeyFromValue(gameData.RACES, formData.race)?.toString() ?? "",
        "1",
      ],
    };

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

  const realm = getRealmNameById(parseInt(formData.homeRealmId) ?? 0);

  const [formFilled, setFormFilled] = useState(false);

  useEffect(() => {
    if (formData.homeRealmId && formData.name && formData.startingWeapon && formData.race) {
      setFormFilled(true);
    } else {
      setFormFilled(false);
    }
  }, [formData]);

  return (
    <div className=" items-center sm:w-1/3 mx-4 border border-terminal-green uppercase">
      <h4 className="w-full text-center ">Create Adventurer</h4>
      <hr className="border-terminal-green" />
      <div className="flex flex-row w-full gap-2 p-4">
        <form
          onSubmit={handleSubmit}
          className="flex flex-col w-full gap-2 text-lg sm:text-2xl"
        >
          <label className="flex justify-between">
            <span className="self-center">Name:</span>

            <input
              type="text"
              name="name"
              onChange={handleChange}
              className="p-1 m-2 bg-terminal-black border border-terminal-green"
              onKeyDown={handleKeyDown}
              maxLength={16}
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
            <span>
              {formData.homeRealmId && (
                <span className="self-center text-terminal-yellow">
                  {realm?.properties.name}
                </span>
              )}
              <input
                type="number"
                name="homeRealmId"
                min="1"
                max="8000"
                onChange={handleChange}
                className="p-1 m-2 bg-terminal-black border border-terminal-green"
              />
            </span>
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
          <Button
            variant={'default'}
            type="submit"
            size={'lg'}
            disabled={!formFilled}

          >
            {formFilled ? "Spawn" : "Fill details"}
          </Button>
        </form>
      </div>
    </div>
  );
};
