import Image from "next/image";
import { Button } from "@/app/components/buttons/Button";
import {
  BladeIcon,
  BludgeonIcon,
  MagicIcon,
} from "@/app/components/icons/Icons";
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
  const handleWeaponSelectionMobile = (weapon: string) => {
    setFormData({ ...formData, startingWeapon: weapon });
    setStep(step + 1);
  };
  const handleWeaponSelectionDesktop = (weapon: string) => {
    setFormData({ ...formData, startingWeapon: weapon });
  };

  return (
    <div className="w-full p-4 2xl:flex 2xl:flex-col 2xl:gap-2 2xl:h-1/2">
      <h3 className="uppercase text-center 2xl:text-5xl h-1/6 m-0 sm:mb-3">
        Choose your weapon
      </h3>
      <div className="grid grid-cols-2 sm:flex flex-wrap sm:flex-row sm:justify-between gap-2 md:gap-5 h-5/6">
        {weapons.map((weapon) => (
          <div
            key={weapon.name}
            className={`flex flex-col items-center border sm:w-56 md:w-48 2xl:w-64 2xl:h-64 ${
              formData.startingWeapon == weapon.name
                ? "border-terminal-yellow"
                : "border-terminal-green"
            }`}
          >
            <div className="relative w-28 h-28 2xl:w-40 2xl:h-48">
              <Image
                src={weapon.image}
                fill={true}
                alt={weapon.name}
                className="object-contains"
                sizes="100%"
              />
            </div>
            <div className="flex items-center pb-2 sm:pb-2 md:pb-4 text-base sm:text-md">
              <div className="w-4">{weapon.icon}</div>
              <p className="ml-2">{weapon.description}</p>
            </div>
            <Button
              className="sm:hidden w-full mt-auto"
              disabled={formData.startingWeapon == weapon.name}
              onClick={() => handleWeaponSelectionMobile(weapon.name)}
            >
              {weapon.name}
            </Button>
            <Button
              className={`hidden sm:block w-full  mt-auto`}
              disabled={formData.startingWeapon == weapon.name}
              onClick={() => handleWeaponSelectionDesktop(weapon.name)}
            >
              {weapon.name}
            </Button>
          </div>
        ))}
      </div>
    </div>
  );
};
