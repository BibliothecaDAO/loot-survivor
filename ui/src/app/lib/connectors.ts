import { InjectedConnector } from "@starknet-react/core";


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

export const connectors = [argentConnector, braavosConnector]