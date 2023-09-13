import Image from "next/image";
import { FormData } from "@/app/types";
import { Button } from "../buttons/Button";

export interface ClassSelectProps {
  setFormData: (data: FormData) => void;
  formData: FormData;
  step: number;
  setStep: (step: number) => void;
}

export const ClassSelect = ({
  setFormData,
  formData,
  step,
  setStep,
}: ClassSelectProps) => {
  const classes = [
    {
      name: "Cleric",
      description: "+1 Intelligence +1 Wisdom +1 Dexterity +3 Charisma",
      image: "/classes/cleric2.png",
    },
    {
      name: "Merchant",
      description: "+6 Charisma",
      image: "/classes/hunter2.png",
    },
    {
      name: "Scout",
      description: "+1 Intelligence 1+ Dexterity +2 Strength +2 Charisma",
      image: "/classes/scout2.png",
    },
    {
      name: "Warrior",
      description: "+6 Strength",
      image: "/classes/warrior2.png",
    },
    // {
    //   name: "Seer",
    //   description: "+3 Intelligence +3 Wisdom",
    //   image: "/classes/hunter2.png",
    // },
    // {
    //   name: "Mage",
    //   description: "+1 Dexterity +1 Vitality +2 Intelligence +2 Wisdom",
    //   image: "/classes/cleric2.png",
    // },
    // {
    //   name: "Bard",
    //   description: "+1 Intelligence 1+ Dexterity +2 Strength +2 Charisma",
    //   image: "/classes/scout2.png",
    // },
    // {
    //   name: "Brute",
    //   description: "+6 Strength",
    //   image: "/classes/warrior2.png",
    // },
  ];

  const handleClassSelection = (classType: string | number) => {
    if (classType === "Warrior") {
      setFormData({
        ...formData,
        class: classType,
        startingStrength: "6",
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
        startingIntelligence: "1",
        startingDexterity: "1",
        startingStrength: "2",
        startingCharisma: "2",
      });
    } else if (classType === "Seer") {
      setFormData({
        ...formData,
        class: classType,
        startingIntelligence: "3",
        startingWisdom: "3",
      });
    } else if (classType === "Mage") {
      setFormData({
        ...formData,
        class: classType,
        startingIntelligence: "2",
        startingWisdom: "2",
        startingVitality: "1",
        startingDexterity: "1",
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
  return (
    <div className="w-full sm:p-8 md:p-4 2xl:flex 2xl:flex-col 2xl:gap-20 2xl:h-[700px]">
      <h3 className="uppercase text-center 2xl:text-5xl">Choose your class</h3>
      <div className="grid grid-cols-2 xl:overflow-y-auto xl:h-[420px] sm:flex flex-wrap sm:flex-row sm:items-center sm:justify-between gap-2 sm:gap-5 md:gap-5 lg:gap-10 2xl:gap-5 2xl:justify-center">
        {classes.map((classType) => (
          <div
            key={classType.name}
            className="flex flex-col items-center justify-between border sm:w-52 md:w-48 2xl:w-64 border-terminal-green"
          >
            <div className="relative w-28 h-28 sm:w-40 sm:h-40 md:w-52 md:h-52 2xl:h-64 2xl:w-64">
              <Image
                src={classType.image}
                fill={true}
                sizes="xl"
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
  );
};
