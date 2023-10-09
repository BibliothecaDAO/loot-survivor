import React, { useState, useEffect, useCallback } from "react";
import { FormData } from "@/app/types";
import { AdventurerName } from "./AdventurerName";
import { WeaponSelect } from "./WeaponSelect";
import { Spawn } from "./Spawn";

export interface CreateAdventurerProps {
  isActive: boolean;
  onEscape: () => void;
  spawn: (...args: any[]) => any;
  lordsBalance?: bigint;
  mintLords: (...args: any[]) => any;
}

export const CreateAdventurer = ({
  isActive,
  onEscape,
  spawn,
  lordsBalance,
  mintLords,
}: CreateAdventurerProps) => {
  const [formData, setFormData] = useState<FormData>({
    startingWeapon: "",
    name: "",
    homeRealmId: "",
    class: "",
  });
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [step, setStep] = useState(1);

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

  const handleBack = () => {
    setStep((step) => Math.max(step - 1, 1));
  };

  if (step === 1) {
    return (
      <WeaponSelect
        setFormData={setFormData}
        formData={formData}
        handleBack={handleBack}
        step={step}
        setStep={setStep}
      />
    );
  } else if (step === 2) {
    return (
      <AdventurerName
        setFormData={setFormData}
        formData={formData}
        handleBack={handleBack}
        step={step}
        setStep={setStep}
      />
    );
  } else if (step === 3) {
    return (
      <Spawn
        formData={formData}
        spawn={spawn}
        handleBack={handleBack}
        lordsBalance={lordsBalance}
        mintLords={mintLords}
      />
    );
  } else {
    return null;
  }
};
