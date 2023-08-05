"use client";
import { useAccount, useNetwork } from "@starknet-react/core";

export default function NetworkSwitchError() {
  const { account } = useAccount();
  const { chain } = useNetwork();

  if (account && chain?.id !== "0x534e5f474f45524c49") {
    return (
      <div className="fixed top-1/16 w-[90%] sm:w-1/2 uppercase text-center border border-terminal-green bg-terminal-black z-50">
        <p>Please switch to Starknet Goerli network to play </p>
      </div>
    );
  } else {
    return null;
  }
}
