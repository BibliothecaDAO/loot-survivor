import { Connector, argent, braavos } from "@starknet-react/core";
import { WebWalletConnector } from "@argent/starknet-react-webwallet-connector";

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

export const providerInterfaceCamel = (provider: string) => {
  // check provider, braavos interface is camel, argent is snake
  if (provider === "braavos") {
    return "1";
  } else {
    return "0";
  }
};

function argentWebWalletUrl() {
  switch (process.env.NEXT_PUBLIC_NETWORK) {
    case "goerli":
      return "https://web.hydrogen.argent47.net";
    case "mainnet":
      return "https://web.argent.xyz/";
    default:
      return "https://web.hydrogen.argent47.net";
  }
}

export const argentWebWalletConnector = new WebWalletConnector({
  url: argentWebWalletUrl(),
});

export const connectors = [argent(), braavos(), argentWebWalletConnector];
