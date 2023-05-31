import { InjectedConnector } from "@starknet-react/core";
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
    {
        target: contracts.goerli.adventurer,
        method: "explore"
    },
    {
        target: contracts.goerli.adventurer,
        method: "upgrade_stat"
    },
    {
        target: contracts.goerli.lootMarketArcade,
        method: "claim_item"
    },
    {
        target: contracts.goerli.lootMarketArcade,
        method: "mint_daily_items"
    },
    {
        target: contracts.goerli.lootMarketArcade,
        method: "bid_on_item"
    },
    {
        target: contracts.goerli.beast,
        method: "attack"
    },
    {
        target: contracts.goerli.beast,
        method: "flee"
    }
]);

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


export const connectors = [controllerConnector as any, argentConnector, braavosConnector];