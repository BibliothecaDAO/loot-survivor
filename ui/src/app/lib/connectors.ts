import { InjectedConnector, StarknetConfig } from "@starknet-react/core";
import ControllerConnector from "@cartridge/connector";
import { contracts } from "../hooks/useContracts";

export const controllerConnector = new ControllerConnector([
    {
        target: contracts.goerli.lords_erc20_mintable,
        method: "mint",
    },
    {
        target: contracts.goerli.lords_erc20_mintable,
        method: "approve",
    },
    {
        target: contracts.goerli.adventurer,
        method: "mint_with_starting_weapon",
    },
]);

export const argentConnector = new InjectedConnector({
    options: {
        id: "argentX",
    },
});

export const connectors = [controllerConnector as any, argentConnector];