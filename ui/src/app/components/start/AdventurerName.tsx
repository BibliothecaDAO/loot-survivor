import { useState, ChangeEvent } from "react";
import { Button } from "@/app/components/buttons/Button";
import { FormData } from "@/app/types";

export interface AdventurerNameProps {
  setFormData: (data: FormData) => void;
  formData: FormData;
  handleBack: () => void;
  step: number;
  setStep: (step: number) => void;
}

export const AdventurerName = ({
  setFormData,
  formData,
  handleBack,
  step,
  setStep,
}: AdventurerNameProps) => {
  const [isMaxLength, setIsMaxLength] = useState(false);

  const handleChange = (
    e: ChangeEvent<HTMLInputElement | HTMLSelectElement>
  ) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value.slice(0, 13),
    });
    if (value.length >= 13) {
      setIsMaxLength(true);
    } else {
      setIsMaxLength(false);
    }
  };

  const handleNameEntry = (name: string) => {
    setFormData({ ...formData, name: name });
    setTimeout(() => {
      setStep(step + 1);
    }, 1000);
  };

  return (
    <>
      <div className="sm:w-3/4 text-center p-4 uppercase 2xl:flex 2xl:flex-col 2xl:gap-5 2xl:h-1/2">
        <h3 className="2xl:text-5xl">Enter adventurer name</h3>
        <div className="relative items-center flex flex-col gap-2">
          <input
            type="text"
            name="name"
            onChange={handleChange}
            className="p-1 m-2 2xl:h-16 2xl:w-64 2xl:text-4xl bg-terminal-black border border-terminal-green animate-pulse transform"
            maxLength={13}
          />
          {isMaxLength && (
            <p className="absolute top-10 sm:top-20">MAX LENGTH!</p>
          )}
        </div>
        <div className="sm:hidden flex flex-row justify-between">
          <Button size={"sm"} onClick={handleBack}>
            Back
          </Button>
          <Button
            size={"sm"}
            disabled={
              !formData.startingWeapon || !formData.name || formData.name === ""
            }
            onClick={() => handleNameEntry(formData.name)}
          >
            Next
          </Button>
        </div>
        <div className="hidden sm:flex items-center justify-center">
          <Button
            size={"lg"}
            disabled={
              !formData.startingWeapon || !formData.name || formData.name === ""
            }
            onClick={() => handleNameEntry(formData.name)}
          >
            Next
          </Button>
        </div>
      </div>
    </>
  );
};
