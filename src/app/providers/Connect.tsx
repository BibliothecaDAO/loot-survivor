"use client";

import type { AppProps } from "next/app";
import React, { useMemo } from "react";
import { StarknetConfig, InjectedConnector } from "@starknet-react/core";
import CartridgeConnector from "@cartridge/connector";

export const Connect = ({ children }: any) => {
  const connectors: any = useMemo(
    () => [
      new CartridgeConnector([
        {
          target: "",
          method: "harvest",
        },
      ]),
    ],
    []
  );

  return (
    <StarknetConfig connectors={connectors} autoConnect>
      {children}
    </StarknetConfig>
  );
};
