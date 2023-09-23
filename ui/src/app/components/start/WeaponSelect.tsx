import Image from "next/image";
import { Button } from "../buttons/Button";
import { BladeIcon, BludgeonIcon, MagicIcon } from "../icons/Icons";
import { FormData } from "@/app/types";

export interface WeaponSelectProps {
  setFormData: (data: FormData) => void;
  formData: FormData;
  handleBack: () => void;
  step: number;
  setStep: (step: number) => void;
}

export const WeaponSelect = ({
  setFormData,
  formData,
  handleBack,
  step,
  setStep,
}: WeaponSelectProps) => {
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
  const handleWeaponSelection = (weapon: string) => {
    setFormData({ ...formData, startingWeapon: weapon });
    setStep(step + 1);
  };
  return (
    <div className="w-full p-4 sm:p-8 md:p-4 2xl:flex 2xl:flex-col 2xl:gap-20 2xl:h-[700px]">
      <h3 className="uppercase text-center 2xl:text-5xl mb-3">Choose your weapon</h3>
      <div className="grid grid-cols-2 sm:flex flex-wrap sm:flex-row sm:justify-between gap-2 sm:gap-20 md:gap-5">
        {weapons.map((weapon) => (
          <div
            key={weapon.name}
            className="flex flex-col items-center justify-between border sm:w-56 md:w-48 2xl:h-64 2xl:w-64 border-terminal-green"
          >
            <div className="relative w-28 h-28 sm:w-40 sm:h-40 md:w-52 md:h-52 2xl:h-64 2xl:w-64">
              <Image
                src={weapon.image}
                width={200}
                height={200}
                alt={weapon.name}
                className="object-cover"
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
  );
};
