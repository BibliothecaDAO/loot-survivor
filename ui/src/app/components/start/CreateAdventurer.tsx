import React from "react";
import { Adventurer } from "@/app/types";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { AdventurerForm } from "./AdventurerForm";

export interface CreateAdventurerProps {
  isActive: boolean;
  onEscape: () => void;
  adventurers: Adventurer[];
  spawn: (...args: any[]) => any;
}

export const CreateAdventurer = ({
  isActive,
  onEscape,
  adventurers,
  spawn,
}: CreateAdventurerProps) => {
  return (
    <>
      <AdventurerForm
        adventurers={adventurers}
        isActive={isActive}
        onEscape={onEscape}
        spawn={spawn}
      />
    </>
  );
};
