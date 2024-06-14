import { Connector } from "@starknet-react/core";
import { InjectedConnector } from "starknetkit/injected";
import CartridgeConnector from "@cartridge/connector";

export const checkArcadeConnector = (connector?: Connector) => {
  return typeof connector?.id === "string" && connector?.id.includes("0x");
};

export const getArcadeConnectors = (connectors: Connector[]) => {
  return connectors.filter(
    (connector) =>
      typeof connector.id === "string" && connector.id.includes("0x")
  );
};

export const getWalletConnectors = (connectors: Connector[]) =>
  connectors.filter(
    (connector) =>
      typeof connector.id !== "string" || !connector.id.includes("0x")
  );

export const checkCartridgeConnector = (connector?: Connector) => {
  return connector?.id === "cartridge";
};

export const providerInterfaceCamel = (provider: string) => {
  // check provider, braavos interface is camel, argent is snake
  if (provider === "braavos") {
    return "1";
  } else {
    return "0";
  }
};

const cartridgeConnector = (gameAddress: string, lordsAddress: string) =>
  new CartridgeConnector([
    {
      target: gameAddress,
      method: "new_game",
    },
    {
      target: gameAddress,
      method: "explore",
    },
    {
      target: gameAddress,
      method: "attack",
    },
    {
      target: gameAddress,
      method: "flee",
    },
    {
      target: gameAddress,
      method: "equip",
    },
    {
      target: gameAddress,
      method: "drop",
    },
    {
      target: gameAddress,
      method: "upgrade",
    },
    {
      target: lordsAddress,
      method: "approve",
    },
    {
      target: lordsAddress,
      method: "mint",
    },
  ]) as never as Connector;

export const connectors = (gameAddress: string, lordsAddress: string) => [
  new InjectedConnector({ options: { id: "braavos", name: "Braavos" } }),
  new InjectedConnector({ options: { id: "argentX", name: "Argent X" } }),
  cartridgeConnector(gameAddress, lordsAddress),
];
