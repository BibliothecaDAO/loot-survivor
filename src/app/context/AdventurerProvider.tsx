import React, { createContext, useContext, useState, useEffect } from "react";
import { Adventurer } from "../types";
import { useLazyQuery } from "@apollo/client";
import { getAdventurerById } from "../hooks/graphql/queries";

export interface AdventurerProps {
  adventurer: Adventurer | undefined;
  image: string | undefined;
}

export interface AdventurerState {
  /** The connected guild object. */
  adventurer?: AdventurerProps;
  /** The emblem image string. */
  handleUpdateAdventurer: (id: number) => void;
}

const ADVENTURER_INITIAL_STATE: AdventurerState = {
  adventurer: undefined,
  handleUpdateAdventurer: () => undefined,
};

const AdventurerContext = createContext<AdventurerState>(
  ADVENTURER_INITIAL_STATE
);

export function useAdventurer(): AdventurerState {
  return useContext(AdventurerContext);
}

export const useAdventurerContext = () => {
  const [adventurer, setAdventurer] = useState<AdventurerProps>({
    adventurer: undefined,
    image: undefined,
  });

  const [getData, { loading, error, data }] = useLazyQuery(getAdventurerById, {
    onCompleted: (data) => {
      setAdventurer({
        adventurer: data.adventurers[0],
        image: undefined, // Set this to the image URL
      });
    },
  });

  const handleUpdateAdventurer = (id: number) => {
    getData({
      variables: {
        id: id,
      },
    });
    console.log(id);
  };

  return {
    adventurer,
    handleUpdateAdventurer,
  };
};

export function AdventurerProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const state = useAdventurerContext();
  return (
    <AdventurerContext.Provider value={state}>
      {children}
    </AdventurerContext.Provider>
  );
}
