import React, {
  useState,
  ChangeEvent,
  FormEvent,
  useEffect,
  useCallback,
} from "react";
import { useAccount, useConnectors } from "@starknet-react/core";
import useUIStore from "../../hooks/useUIStore";
import { FormData, Adventurer } from "@/app/types";
import { Button } from "../buttons/Button";
import Image from "next/image";
import { WalletTutorial } from "../tutorial/WalletTutorial";
import { BladeIcon, BludgeonIcon, MagicIcon } from "../icons/Icons";
import { TypeAnimation } from "react-type-animation";
import { battle } from "@/app/lib/constants";
import { TxActivity } from "../navigation/TxActivity";
import { MdClose } from "react-icons/md";
import { syscalls } from "@/app/lib/utils/syscalls";

export interface AdventurerFormProps {
  isActive: boolean;
  onEscape: () => void;
  adventurers: Adventurer[];
}

export const AdventurerForm = ({
  isActive,
  onEscape,
  adventurers,
}: AdventurerFormProps) => {
  const { account } = useAccount();
  const { connectors, connect } = useConnectors();

  const [formData, setFormData] = useState<FormData>({
    startingWeapon: "",
    name: "",
    homeRealmId: "",
    class: "",
    startingStrength: "0",
    startingDexterity: "0",
    startingVitality: "0",
    startingIntelligence: "0",
    startingWisdom: "0",
    startingCharisma: "0",
  });
  const setMintAdventurer = useUIStore((state) => state.setMintAdventurer);

  const [selectedIndex, setSelectedIndex] = useState(0);
  const [step, setStep] = useState(1);
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  const [showWalletTutorial, setShowWalletTutorial] = useState(false);

  const walletConnectors = () =>
    connectors.filter((connector) => !connector.id.includes("0x"));

  const { spawn } = syscalls();

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

  const handleButtonClick = () => {
    setShowWalletTutorial(true);
  };

  const handleChange = (
    e: ChangeEvent<HTMLInputElement | HTMLSelectElement>
  ) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value.slice(0, 13),
    });
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    await spawn(formData);
    setMintAdventurer(true);
  };

  const [formFilled, setFormFilled] = useState(false);

  useEffect(() => {
    if (formData.startingStrength && formData.name && formData.startingWeapon) {
      setFormFilled(true);
    } else {
      setFormFilled(false);
    }
  }, [formData]);

  const handleClassSelection = (classType: string | number) => {
    if (classType === "Warrior") {
      setFormData({
        ...formData,
        class: classType,
        startingStrength: "1",
        startingDexterity: "1",
        startingVitality: "1",
        startingIntelligence: "1",
        startingWisdom: "1",
        startingCharisma: "1",
      });
    } else if (classType === "Merchant") {
      setFormData({
        ...formData,
        class: classType,
        startingCharisma: "6",
      });
    } else if (classType === "Cleric") {
      setFormData({
        ...formData,
        class: classType,
        startingDexterity: "1",
        startingWisdom: "1",
        startingIntelligence: "1",
        startingCharisma: "3",
      });
    } else if (classType === "Scout") {
      setFormData({
        ...formData,
        class: classType,
        startingDexterity: "2",
        startingWisdom: "2",
        startingIntelligence: "2",
      });
    } else {
      setFormData({
        ...formData,
        startingDexterity: [],
        startingWisdom: [],
        startingIntelligence: [],
        startingCharisma: [],
        startingStrength: [],
        startingVitality: [],
      });
    }
    setStep(step + 1);
  };

  const handleWeaponSelection = (weapon: string) => {
    setFormData({ ...formData, startingWeapon: weapon });
    setStep(step + 1);
  };

  const handleNameEntry = (name: string) => {
    setFormData({ ...formData, name: name });
    setTimeout(() => {
      setStep(step + 1);
    }, 1000);
  };

  const handleBack = () => {
    setStep((step) => Math.max(step - 1, 1));
  };

  const classes = [
    {
      name: "Cleric",
      description: "+1 Intelligence +1 Wisdom +1 Dexterity +3 Charisma",
      image: "/classes/cleric2.png",
    },
    {
      name: "Scout",
      description: "+2 Intelligence +2 Wisdom +2 Dexterity",
      image: "/classes/scout2.png",
    },
    {
      name: "Merchant",
      description: "+6 Charisma",
      image: "/classes/hunter2.png",
    },
    {
      name: "Warrior",
      description:
        "+1 Strength +1 Dexterity +1 Vitality +1 Intelligence +1 Wisdom +1 Charisma",
      image: "/classes/warrior2.png",
    },
  ];

  const weapons = [
    {
      name: "Book",
      description: "Magic Weapon",
      image: "/weapons/book.png",
      icon: <MagicIcon />,
    },
    {
      name: "Wand",
      description: "Magic Weapon",
      image: "/weapons/wand.png",
      icon: <MagicIcon />,
    },
    {
      name: "Short Sword",
      description: "Blade Weapon",
      image: "/weapons/shortsword.png",
      icon: <BladeIcon />,
    },
    {
      name: "Club",
      description: "Bludgeon Weapon",
      image: "/weapons/club.png",
      icon: <BludgeonIcon />,
    },
  ];

  if (step === 1) {
    return (
      <>
        <div className="w-full sm:p-8 md:p-4 2xl:flex 2xl:flex-col 2xl:gap-20 2xl:h-[700px]">
          <h3 className="uppercase text-center 2xl:text-5xl">
            Choose your class
          </h3>
          <div className="grid grid-cols-2 sm:flex flex-wrap sm:flex-row sm:items-center sm:justify-between gap-2 sm:gap-5 md:gap-5 lg:gap-10 2xl:gap-5 2xl:justify-center">
            {classes.map((classType) => (
              <div
                key={classType.name}
                className="flex flex-col items-center justify-between border sm:w-56 md:w-48 2xl:w-64 border-terminal-green"
              >
                <div className="relative w-28 h-28 sm:w-56 sm:h-56 md:h-40 2xl:h-64 2xl:w-64">
                  <Image
                    src={classType.image}
                    fill={true}
                    alt={classType.name}
                    style={{
                      objectFit: "contain",
                    }}
                  />
                </div>
                <div className="flex items-center p-2 sm:pb-4 h-10 sm:h-20 md:h-16 text-center text-xxs sm:text-base md:text-sm">
                  <p className="ml-2">{classType.description}</p>
                </div>
                <Button
                  className="w-full"
                  onClick={() => handleClassSelection(classType.name)}
                >
                  {classType.name}
                </Button>
              </div>
            ))}
          </div>
        </div>
      </>
    );
  } else if (step === 2) {
    return (
      <>
        <div className="w-full sm:p-8 md:p-4 2xl:flex 2xl:flex-col 2xl:gap-20 2xl:h-[700px]">
          <h3 className="uppercase text-center 2xl:text-5xl">
            Choose your weapon
          </h3>
          <div className="grid grid-cols-2 sm:flex flex-wrap sm:flex-row sm:justify-between gap-2 sm:gap-20 md:gap-5">
            {weapons.map((weapon) => (
              <div
                key={weapon.name}
                className="flex flex-col items-center justify-between border sm:w-56 md:w-48 2xl:h-64 2xl:w-64 border-terminal-green"
              >
                <div className="relative w-28 h-28 sm:w-40 sm:h-40 md:w-52 md:h-52 2xl:h-64 2xl:w-64">
                  <Image
                    src={weapon.image}
                    fill={true}
                    alt={weapon.name}
                    style={{
                      objectFit: "contain",
                    }}
                  />
                </div>
                <div className="flex items-center pb-2 sm:pb-2 md:pb-4 text-base sm:text-md">
                  {weapon.icon}
                  <p className="ml-2">{weapon.description}</p>
                </div>
                <Button
                  className="w-full"
                  onClick={() => handleWeaponSelection(weapon.name)}
                >
                  {weapon.name}
                </Button>
              </div>
            ))}
          </div>
          <div className="flex flex-col items-center">
            <Button className="my-2" onClick={handleBack}>
              Back
            </Button>
          </div>
        </div>
      </>
    );
  } else if (step === 3) {
    return (
      <>
        <div className="sm:w-3/4 text-center p-4 uppercase 2xl:flex 2xl:flex-col 2xl:gap-10 2xl:h-[700px]">
          <h3 className="2xl:text-5xl">Enter adventurer name</h3>
          <div className="items-center flex flex-col gap-2">
            <input
              type="text"
              name="name"
              onChange={handleChange}
              className="p-1 m-2 2xl:h-16 2xl:w-64 2xl:text-4xl bg-terminal-black border border-terminal-green animate-pulse transform"
              onKeyDown={handleKeyDown}
              maxLength={13}
            />
          </div>
          <div className="sm:hidden flex flex-row justify-between">
            <Button size={"sm"} onClick={handleBack}>
              Back
            </Button>
            <Button size={"sm"} onClick={() => handleNameEntry(formData.name)}>
              Next
            </Button>
          </div>
          <div className="hidden sm:flex flex-row justify-between">
            <Button size={"lg"} onClick={handleBack}>
              Back
            </Button>
            <Button size={"lg"} onClick={() => handleNameEntry(formData.name)}>
              Next
            </Button>
          </div>
        </div>
      </>
    );
  } else if (step === 4) {
    return (
      <>
        <div className="flex flex-col w-full h-full justify-center">
          {showWalletTutorial && (
            <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-1/2 h-4/5 z-20 bg-terminal-black overflow-y-auto flex flex-col items-center gap-4">
              {" "}
              <Button
                onClick={() => setShowWalletTutorial(false)}
                className="text-red-500 hover:text-red-700"
                variant={"ghost"}
              >
                <MdClose size={20} />
              </Button>
              <WalletTutorial />
            </div>
          )}
          <div className="flex flex-col h-full">
            <Image
              className="mx-auto border border-terminal-green absolute  object-cover sm:py-4 sm:px-8"
              src={"/scenes/intro/beast.png"}
              alt="adventurer facing beast"
              fill
            />

            <span className="absolute sm:hidden top-0">
              <TxActivity />
            </span>

            {!isWrongNetwork && (
              <div className="absolute text-xs sm:text-xl leading-normal sm:leading-loose z-10 top-1/4">
                <TypeAnimation
                  sequence={[battle]}
                  wrapper="span"
                  cursor={true}
                  speed={40}
                  style={{ fontSize: "2em" }}
                />
              </div>
            )}

            <div className="absolute top-1/2 left-0 right-0 flex flex-col items-center gap-4 z-10">
              <span className="hidden sm:block">
                <TxActivity />
              </span>
              {!account ? (
                <>
                  <div className="flex flex-col justify-between">
                    <div className="flex flex-col gap-2">
                      {walletConnectors().map((connector, index) => (
                        <Button
                          onClick={() => connect(connector)}
                          disabled={!formFilled}
                          key={index}
                          className="w-full"
                        >
                          Connect {connector.id}
                        </Button>
                      ))}
                      <Button onClick={handleButtonClick}>
                        I don&apos;t have a wallet
                      </Button>
                    </div>
                  </div>
                </>
              ) : (
                <form onSubmit={handleSubmit}>
                  <Button
                    type="submit"
                    size={"xl"}
                    disabled={!formFilled || !account || isWrongNetwork}
                  >
                    {formFilled ? "Start Game!!" : "Fill details"}
                  </Button>
                </form>
              )}
            </div>
            <div className="absolute bottom-10 left-0 right-0 flex flex-col items-center gap-4 z-10 pb-8">
              <Button size={"xs"} variant={"default"} onClick={handleBack}>
                Back
              </Button>
            </div>
          </div>
        </div>
      </>
    );
  } else {
    return null;
  }
};
