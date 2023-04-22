import React, { createContext, useContext, useState, useEffect } from "react";
import { Adventurer } from "../types";
import { useLazyQuery } from "@apollo/client";
import { getAdventurerById } from "../hooks/graphql/queries";
import { useQuery } from "@apollo/client";

export interface AdventurerProps {
  adventurer: Adventurer | undefined;
  image: string | undefined;
}

export interface AdventurerState {
  adventurer?: AdventurerProps;
  handleUpdateAdventurer: (id: number) => void;
  setAdventurer: (value: any) => void;
}

const ADVENTURER_INITIAL_STATE: AdventurerState = {
  adventurer: undefined,
  handleUpdateAdventurer: () => undefined,
  setAdventurer: () => undefined,
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
  };

  const { data: updatedAdventurerData, error: testError } = useQuery(
    getAdventurerById,
    {
      variables: {
        id: adventurer?.adventurer?.id,
      },
      pollInterval: 5000,
    }
  );

  useEffect(() => {
    setAdventurer({
      adventurer: updatedAdventurerData?.adventurers[0],
      image: undefined, // Set this to the image URL
    });
  }, [updatedAdventurerData]);

  return {
    adventurer,
    handleUpdateAdventurer,
    setAdventurer,
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
