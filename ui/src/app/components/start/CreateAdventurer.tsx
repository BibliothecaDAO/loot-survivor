import React from "react";
import { Adventurer } from "@/app/types";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { AdventurerForm } from "./AdventurerForm";

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
  return (
    <>
      <AdventurerForm
        adventurers={adventurers}
        isActive={isActive}
        onEscape={onEscape}
      />
    </>
  );
};
