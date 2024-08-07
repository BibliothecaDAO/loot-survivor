import { Connector } from "@starknet-react/core";
import { InjectedConnector } from "starknetkit/injected";
import CartridgeConnector from "@cartridge/connector";
import { shortString } from "starknet";
// import { WebWalletConnector } from "starknetkit/webwallet";

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

// export function argentWebWalletUrl() {
//   switch (process.env.NEXT_PUBLIC_NETWORK) {
//     case "goerli":
//       return "https://web.hydrogen.argent47.net";
//     case "mainnet":
//       return "https://web.argent.xyz/";
//     default:
//       return "https://web.hydrogen.argent47.net";
//   }
// }

// export function argentWebWalletUrl() {
//   return "https://web.hydrogen.argent47.net";
// }

// export const argentWebWalletConnector = new WebWalletConnector({
//   url: argentWebWalletUrl(),
// });

const cartridgeConnector = (
  gameAddress: string,
  lordsAddress: string,
  ethAddress: string
) =>
  new CartridgeConnector(
    [
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
        method: "mint_lords",
      },
      {
        target: ethAddress,
        method: "approve",
      },
    ],
    {
      paymaster: {
        caller: shortString.encodeShortString("ANY_CALLER"),
      },
      theme: "loot-survivor",
    }
  ) as never as Connector;

export const connectors = (
  gameAddress: string,
  lordsAddress: string,
  ethAddress: string
) => [
  cartridgeConnector(gameAddress, lordsAddress, ethAddress),
  new InjectedConnector({ options: { id: "braavos", name: "Braavos" } }),
  new InjectedConnector({ options: { id: "argentX", name: "Argent X" } }),
  // argentWebWalletConnector,
];
