import { useCallback } from "react";
import { InjectedConnector, Connector } from "@starknet-react/core";
// import { WebWalletConnector } from "@argent/starknet-react-webwallet-connector";

export const argentConnector = new InjectedConnector({
  options: {
    id: "argentX",
  },
});

export const braavosConnector = new InjectedConnector({
  options: {
    id: "braavos",
  },
});

export const getArcadeConnectors = (available: Connector[]) => {
  return available.filter(
    (connector) =>
      typeof connector.id === "string" && connector.id.includes("0x")
  );
};

export const getWalletConnectors = (available: Connector[]) =>
  available.filter(
    (connector) =>
      typeof connector.id !== "string" || !connector.id.includes("0x")
  );

function argentWebWalletUrl() {
  switch (process.env.NEXT_PUBLIC_NETWORK) {
    case "dev":
      return "https://web.hydrogen.argent47.net";
    case "production":
      return "https://web.argent.xyz/";
    default:
      return "https://web.hydrogen.argent47.net";
  }
}

// export const argentWebWalletConnector = new WebWalletConnector({
//   url: argentWebWalletUrl(),
// });

export const connectors = [
  argentConnector,
  braavosConnector,
  // argentWebWalletConnector,
];
