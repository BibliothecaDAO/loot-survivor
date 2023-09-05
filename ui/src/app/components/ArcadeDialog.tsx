import React from "react";
import { useState } from "react";
import useUIStore from "@/app/hooks/useUIStore";
import { Button } from "./buttons/Button";
import { PREFUND_AMOUNT, useBurner } from "../lib/burner";
import {
  Connector,
  useAccount,
  useBalance,
  useConnectors,
} from "@starknet-react/core";
import { AccountInterface, CallData, TransactionStatus } from "starknet";
import { useCallback } from "react";

export const ArcadeDialog = () => {
  const { account: MasterAccount, address, connector } = useAccount();
  const showArcadeDialog = useUIStore((state) => state.showArcadeDialog);
  const arcadeDialog = useUIStore((state) => state.arcadeDialog);
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  const { connect, connectors, available } = useConnectors();
  const { create, isDeploying } = useBurner();

  const arcadeConnectors = useCallback(() => {
    return available.filter(
      (connector) =>
        typeof connector.id === "string" && connector.id.includes("0x")
    );
  }, [available]);

  if (!connectors) return <div></div>;

  return (
    <>
      <div className="fixed inset-0 opacity-80 bg-terminal-black z-40 m-2" />
      <div className="fixed text-center top-1/8 left-1/8 sm:left-1/4 w-3/4 sm:w-1/2 h-3/4 border-4 bg-terminal-black z-50 border-terminal-green p-4 overflow-y-auto">
        <h3 className="mt-4">Arcade Accounts</h3>
        <p className="m-2 text-xl">
          Go deep into the mist with signature free gameplay! <br /> Connect
          your wallet to create an Arcade Account
        </p>

        {/* 
        <p className="text-sm xl:text-xl 2xl:text-2xl pb-4">
          Create your AA here <br /> for signature free gameplay!
        </p> */}

        <div className="flex justify-center mb-1">
          {((connector?.options as any)?.id == "argentX" ||
            (connector?.options as any)?.id == "braavos") && (
            <div>
              <p className="my-2 text-sm sm:text-base text-terminal-yellow p-2 border border-terminal-yellow">
                Note: This will initiate a 0.01 ETH transaction from your
                connected wallet to the arcade account. <br />
                You may need to refresh after the account has been created!
              </p>
              <Button onClick={() => create()} disabled={isWrongNetwork}>
                create arcade account
              </Button>
            </div>
          )}
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 overflow-hidden my-6">
          {arcadeConnectors().map((account, index) => {
            return (
              <ArcadeAccountCard
                key={index}
                account={account}
                onClick={connect}
                address={address!}
                masterAccount={MasterAccount!}
              />
            );
          })}
          {isDeploying && (
            <div className="flex justify-center border-terminal-green border">
              <p className="self-center">Deploying Account...</p>
            </div>
          )}
        </div>
        <div>
          <Button onClick={() => showArcadeDialog(!arcadeDialog)}>close</Button>
        </div>
      </div>
    </>
  );
};

interface ArcadeAccountCardProps {
  account: Connector;
  onClick: (conn: Connector<any>) => void;
  address: string;
  masterAccount: AccountInterface;
}

export const ArcadeAccountCard = ({
  account,
  onClick,
  address,
  masterAccount,
}: ArcadeAccountCardProps) => {
  const { data } = useBalance({
    address: account.name,
  });
  const [isCopied, setIsCopied] = useState(false);

  const connected = address == account.name;

  const balance = parseFloat(data?.formatted!).toFixed(4);

  const transfer = async (address: string, account: AccountInterface) => {
    try {
      const { transaction_hash } = await account.execute({
        contractAddress: process.env.NEXT_PUBLIC_ETH_CONTRACT_ADDRESS!,
        entrypoint: "transfer",
        calldata: CallData.compile([address, PREFUND_AMOUNT, "0x0"]),
      });

      const result = await account.waitForTransaction(transaction_hash, {
        retryInterval: 1000,
        successStates: [TransactionStatus.ACCEPTED_ON_L2],
      });

      if (!result) {
        throw new Error("Transaction did not complete successfully.");
      }

      return result;
    } catch (error) {
      console.error(error);
      throw error;
    }
  };

  const copyToClipboard = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setIsCopied(true);
      setTimeout(() => setIsCopied(false), 2000);
    } catch (err) {
      console.error("Failed to copy text: ", err);
    }
  };

  return (
    <div className="border border-terminal-green p-3 hover:bg-terminal-green hover:text-terminal-black items-center">
      <div className="text-left flex flex-col text-sm sm:text-xl mb-0 sm:mb-4 items-center">
        <span
          onClick={() => copyToClipboard(account.id)}
          style={{ cursor: "pointer" }}
        >
          {account.id}
        </span>
        <span className="text-lg">{balance}ETH</span>{" "}
      </div>
      <div className="flex justify-center">
        <Button
          variant={connected ? "default" : "ghost"}
          onClick={() => onClick(account)}
        >
          {connected ? "connected" : "connect"}
        </Button>
      </div>

      {isCopied && <span>Copied!</span>}
    </div>
  );
};
