import React, { createContext, useContext, useState, ReactNode } from "react";

type Control = {
  callback: () => void;
};

type Controller = { [key: string]: Control };

type ControllerContextType = {
  controls: Controller;
  conditions: { [key: string]: boolean };
  addControl: (key: string, callback: () => void) => void;
  setCondition: (key: string, condition: boolean) => void;
};

const ControllerContext = createContext<ControllerContextType>({
  controls: {},
  conditions: {},
  addControl: () => {},
  setCondition: () => {},
});

export const ControllerProvider = ({ children }: { children: ReactNode }) => {
  const [controls, setControls] = useState<Controller>({});
  const [conditions, setConditions] = useState<{ [key: string]: boolean }>({});

  const addControl = (key: string, callback: () => void) => {
    setControls((prevControls) => ({
      ...prevControls,
      [key]: { callback },
    }));
  };

  const setCondition = (key: string, condition: boolean) => {
    setConditions((prevConditions) => ({
      ...prevConditions,
      [key]: condition,
    }));
  };

  return (
    <ControllerContext.Provider
      value={{ controls, conditions, addControl, setCondition }}
    >
      {children}
    </ControllerContext.Provider>
  );
};

export const useController = () => useContext(ControllerContext);
