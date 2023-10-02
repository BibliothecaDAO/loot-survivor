import React, { useEffect } from "react";
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
import {
  AccountInterface,
  CallData,
  TransactionFinalityStatus,
  uint256,
  Call,
  Account,
  Provider,
} from "starknet";
import { useCallback } from "react";
import { useContracts } from "../hooks/useContracts";
import { balanceSchema } from "../lib/utils";
import { MIN_BALANCE } from "../lib/constants";

const MAX_RETRIES = 10;
const RETRY_DELAY = 2000; // 2 seconds

export const ArcadeDialog = () => {
  const { account: walletAccount, address, connector } = useAccount();
  const showArcadeDialog = useUIStore((state) => state.showArcadeDialog);
  const arcadeDialog = useUIStore((state) => state.arcadeDialog);
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  const { connect, connectors, available } = useConnectors();
  const {
    getMasterAccount,
    create,
    isDeploying,
    isSettingPermissions,
    genNewKey,
    isGeneratingNewKey,
    topUp,
    withdraw,
  } = useBurner();
  const { ethContract } = useContracts();
  const [balances, setBalances] = useState<Record<string, bigint>>({});

  const arcadeConnectors = useCallback(() => {
    return available.filter(
      (connector) =>
        typeof connector.id === "string" && connector.id.includes("0x")
    );
  }, [available]);

  const fetchBalanceWithRetry = async (
    accountName: string,
    retryCount: number = 0
  ): Promise<bigint> => {
    try {
      const result = await ethContract!.call(
        "balanceOf",
        CallData.compile({ account: accountName })
      );
      return uint256.uint256ToBN(balanceSchema.parse(result).balance);
    } catch (error) {
      if (retryCount < MAX_RETRIES) {
        await new Promise((resolve) => setTimeout(resolve, RETRY_DELAY)); // delay before retry
        return fetchBalanceWithRetry(accountName, retryCount + 1);
      } else {
        throw new Error(
          `Failed to fetch balance after ${MAX_RETRIES} retries.`
        );
      }
    }
  };

  const getBalances = async () => {
    const localBalances: Record<string, bigint> = {};
    const balancePromises = arcadeConnectors().map((account) => {
      return fetchBalanceWithRetry(account.name).then((balance) => {
        localBalances[account.name] = balance;
        return balance;
      });
    });
    console.log(balancePromises);
    await Promise.all(balancePromises);
    setBalances(localBalances);
  };

  const getBalance = async (account: string) => {
    const balance = await fetchBalanceWithRetry(account);
    setBalances({ ...balances, [account]: balance });
  };

  useEffect(() => {
    getBalances();
  }, [arcadeConnectors]);

  if (!connectors) return <div></div>;

  return (
    <>
      <div className="fixed inset-0 opacity-80 bg-terminal-black z-40" />
      <div className="fixed text-center sm:top-1/8 sm:left-1/8 sm:left-1/4 sm:w-3/4 sm:w-1/2 h-3/4 border-4 bg-terminal-black z-50 border-terminal-green p-4 overflow-y-auto">
        <h3 className="mt-4">Arcade Accounts</h3>
        <p className="m-2 text-sm xl:text-xl 2xl:text-2xl">
          Go deep into the mist with signature free gameplay! Simply connect
          your wallet and create a free arcade account.
        </p>

        <div className="flex justify-center mb-1">
          {((connector?.options as any)?.id == "argentX" ||
            (connector?.options as any)?.id == "braavos") && (
            <div>
              <p className="my-2 text-sm sm:text-base text-terminal-yellow p-2 border border-terminal-yellow">
                Note: This will initiate a transfer of 0.001 ETH from your
                connected wallet to the arcade account to cover your transaction
                costs from normal gameplay.
              </p>
              <Button onClick={() => create()} disabled={isWrongNetwork}>
                create arcade account
              </Button>
            </div>
          )}
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 overflow-hidden my-6">
          {arcadeConnectors().map((account, index) => {
            const masterAccount = getMasterAccount(account.name);
            return (
              <ArcadeAccountCard
                key={index}
                account={account}
                onClick={connect}
                address={address!}
                walletAccount={walletAccount!}
                masterAccountAddress={masterAccount}
                arcadeConnectors={arcadeConnectors()}
                genNewKey={genNewKey}
                balance={balances[account.name]}
                getBalance={getBalance}
                topUp={topUp}
                withdraw={withdraw}
              />
            );
          })}
        </div>
        <div>
          <Button onClick={() => showArcadeDialog(!arcadeDialog)}>close</Button>
        </div>
      </div>
      {(isDeploying || isGeneratingNewKey) && (
        <div className="fixed inset-0 opacity-80 bg-terminal-black z-50 m-2 w-full h-full flex justify-center items-center">
          <h3 className="loading-ellipsis">
            {isSettingPermissions
              ? "Setting Permissions"
              : isGeneratingNewKey
              ? "Generating New Key"
              : "Deploying Account"}
          </h3>
        </div>
      )}
    </>
  );
};

interface ArcadeAccountCardProps {
  account: Connector;
  onClick: (conn: Connector<any>) => void;
  address: string;
  walletAccount: AccountInterface;
  masterAccountAddress: string;
  arcadeConnectors: any[];
  genNewKey: (address: string) => void;
  balance: bigint;
  getBalance: (address: string) => void;
  topUp: (address: string, account: AccountInterface) => void;
  withdraw: (
    masterAccountAddress: string,
    account: AccountInterface,
    balance: bigint
  ) => void;
}

export const ArcadeAccountCard = ({
  account,
  onClick,
  address,
  walletAccount,
  masterAccountAddress,
  arcadeConnectors,
  genNewKey,
  balance,
  getBalance,
  topUp,
  withdraw,
}: ArcadeAccountCardProps) => {
  const [isCopied, setIsCopied] = useState(false);
  const [isToppingUp, setIsToppingUp] = useState(false);
  const [isWithdrawing, setIsWithdrawing] = useState(false);

  const connected = address == account.name;

  const formatted = (Number(balance) / 10 ** 18).toFixed(4);

  const copyToClipboard = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setIsCopied(true);
      setTimeout(() => setIsCopied(false), 2000);
    } catch (err) {
      console.error("Failed to copy text: ", err);
    }
  };

  const minimalBalance = balance < BigInt(MIN_BALANCE);

  return (
    <div className="border border-terminal-green p-3 hover:bg-terminal-green hover:text-terminal-black items-center">
      <div className="text-left flex flex-col text-sm sm:text-xl mb-0 sm:mb-4 items-center">
        <span
          onClick={() => copyToClipboard(account.name)}
          style={{ cursor: "pointer" }}
        >
          {account.id}
        </span>
        <span className="text-lg">
          {formatted === "NaN" ? (
            <span className="loading-ellipsis">Loading</span>
          ) : (
            `${formatted}ETH`
          )}
        </span>{" "}
      </div>
      <div className="flex flex-col items-center">
        <div className="flex flex-row">
          <Button
            variant={connected ? "default" : "ghost"}
            onClick={() => onClick(account)}
          >
            {connected ? "connected" : "connect"}
          </Button>
          {!arcadeConnectors.some(
            (conn) => conn.options.options.id == walletAccount.address
          ) && (
            <Button
              variant={"ghost"}
              onClick={() => {
                topUp(account.name, walletAccount);
                getBalance(account.name);
              }}
              disabled={isToppingUp}
            >
              {isToppingUp ? (
                <span className="loading-ellipsis">Topping Up</span>
              ) : (
                <span className="flex flex-col">
                  <span>Top Up</span> <span>(0.001Eth)</span>
                </span>
              )}
            </Button>
          )}
        </div>
        <div className="flex flex-row">
          {masterAccountAddress == walletAccount.address && (
            <Button variant={"ghost"} onClick={() => genNewKey(account.name)}>
              Create New Keys
            </Button>
          )}
          {connected && (
            <Button
              variant={"ghost"}
              onClick={() => {
                withdraw(masterAccountAddress, walletAccount, balance);
                getBalance(account.name);
              }}
              disabled={isWithdrawing || minimalBalance}
            >
              {isWithdrawing ? (
                <span className="loading-ellipsis">Withdrawing</span>
              ) : (
                "Withdraw"
              )}
            </Button>
          )}
        </div>
      </div>

      {isCopied && <span>Copied!</span>}
    </div>
  );
};
