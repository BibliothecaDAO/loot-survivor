import React, { useEffect, useState, useCallback } from "react";
import { AccountInterface, Contract } from "starknet";
import {
  Connector,
  useAccount,
  useConnect,
  useDisconnect,
} from "@starknet-react/core";
import useUIStore from "@/app/hooks/useUIStore";
import { Button } from "@/app/components/buttons/Button";
import { useBurner } from "@/app/lib/burner";
import { MIN_BALANCE } from "@/app/lib/constants";
import { getArcadeConnectors } from "@/app/lib/connectors";
import SpriteAnimation from "@/app/components/animations/SpriteAnimation";
import { fetchBalances } from "@/app/lib/balances";
import Lords from "public/icons/lords.svg";
import Eth from "public/icons/eth.svg";
import ArcadeLoader from "@/app/components/animations/ArcadeLoader";
import TokenLoader from "@/app/components/animations/TokenLoader";

interface ArcadeDialogProps {
  gameContract: Contract;
  lordsContract: Contract;
  ethContract: Contract;
  updateConnectors: () => void;
}

export const ArcadeDialog = ({
  gameContract,
  lordsContract,
  ethContract,
  updateConnectors,
}: ArcadeDialogProps) => {
  const [fetchedBalances, setFetchedBalances] = useState(false);
  const { account: walletAccount, address, connector } = useAccount();
  const showArcadeDialog = useUIStore((state) => state.showArcadeDialog);
  const arcadeDialog = useUIStore((state) => state.arcadeDialog);
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const {
    getMasterAccount,
    create,
    isDeploying,
    isSettingPermissions,
    genNewKey,
    isGeneratingNewKey,
    topUpEth,
    isToppingUpEth,
    topUpLords,
    isToppingUpLords,
    withdraw,
    isWithdrawing,
    listConnectors,
  } = useBurner(walletAccount, gameContract, lordsContract, ethContract);
  const [arcadebalances, setArcadeBalances] = useState<
    Record<string, { eth: bigint; lords: bigint; lordsGameAllowance: bigint }>
  >({});

  // Needs to be callback else infinite loop
  const arcadeConnectors = useCallback(() => {
    return getArcadeConnectors(connectors);
  }, [connectors]);

  const getBalances = async () => {
    const localBalances: Record<
      string,
      { eth: bigint; lords: bigint; lordsGameAllowance: bigint }
    > = {};
    const balancePromises = arcadeConnectors().map((account) => {
      return fetchBalances(
        account.name,
        ethContract!,
        lordsContract!,
        gameContract!
      ).then((balances) => {
        localBalances[account.name] = {
          eth: BigInt(0),
          lords: BigInt(0),
          lordsGameAllowance: BigInt(0),
        }; // Initialize with empty values
        localBalances[account.name]["eth"] = balances[0];
        localBalances[account.name]["lords"] = balances[1];
        localBalances[account.name]["lordsGameAllowance"] = balances[2];
        return balances;
      });
    });
    await Promise.all(balancePromises);
    setArcadeBalances(localBalances);
    setFetchedBalances(true);
  };

  const getAccountBalances = async (account: string) => {
    const balances = await fetchBalances(account);
    setArcadeBalances({
      ...arcadebalances,
      [account]: {
        eth: balances[0],
        lords: balances[1],
        lordsGameAllowance: balances[2],
      },
    });
  };

  useEffect(() => {
    getBalances();
  }, [arcadeConnectors, fetchedBalances]);

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
          {(connector?.id == "argentX" ||
            connector?.id == "braavos" ||
            connector?.id == "argentWebWallet") && (
            <div>
              <p className="my-2 text-sm sm:text-base text-terminal-yellow p-2 border border-terminal-yellow">
                Note: This will initiate a transfer of 0.001 ETH from your
                connected wallet to the arcade account to cover your transaction
                costs from normal gameplay.
              </p>
              <Button
                onClick={async () => {
                  await create(connector);
                  connect({ connector: listConnectors()[0] });
                  updateConnectors();
                }}
                disabled={isWrongNetwork}
              >
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
                disconnect={disconnect}
                address={address!}
                walletAccount={walletAccount!}
                masterAccountAddress={masterAccount}
                arcadeConnectors={arcadeConnectors()}
                genNewKey={genNewKey}
                balances={arcadebalances[account.name]}
                getAccountBalances={getAccountBalances}
                topUpEth={topUpEth}
                isToppingUpEth={isToppingUpEth}
                topUpLords={topUpLords}
                isToppingUpLords={isToppingUpLords}
                withdraw={withdraw}
                isWithdrawing={isWithdrawing}
              />
            );
          })}
        </div>
        <div>
          <Button onClick={() => showArcadeDialog(!arcadeDialog)}>close</Button>
        </div>
      </div>
      {(isDeploying || isGeneratingNewKey) && (
        <ArcadeLoader
          isSettingPermissions={isSettingPermissions}
          isGeneratingNewKey={isGeneratingNewKey}
        />
      )}
      {(isToppingUpEth || isToppingUpLords || isWithdrawing) && (
        <div className="fixed inset-0 opacity-80 bg-terminal-black z-50 m-2 w-full h-full">
          <TokenLoader
            isToppingUpEth={isToppingUpEth}
            isToppingUpLords={isToppingUpLords}
          />
          <div className="sm:hidden flex flex-col items-center justify-center w-full h-full">
            <SpriteAnimation
              frameWidth={200}
              frameHeight={200}
              columns={8}
              rows={1}
              frameRate={5}
              className="coin-sprite"
            />
            <h3 className="text-lg sm:text-3xl loading-ellipsis flex items-center justify-center w-full">
              {isToppingUpEth
                ? "Topping Up Eth"
                : isToppingUpLords
                ? "Topping Up Lords"
                : "Withdrawing Tokens"}
            </h3>
          </div>
        </div>
      )}
    </>
  );
};

interface ArcadeAccountCardProps {
  account: Connector;
  disconnect: () => void;
  address: string;
  walletAccount: AccountInterface;
  masterAccountAddress: string;
  arcadeConnectors: any[];
  genNewKey: (address: string) => Promise<void>;
  balances: { eth: bigint; lords: bigint; lordsGameAllowance: bigint };
  getAccountBalances: (address: string) => Promise<void>;
  topUpEth: (address: string, account: AccountInterface) => Promise<any>;
  isToppingUpEth: boolean;
  topUpLords: (
    address: string,
    account: AccountInterface,
    lordsAmount: number,
    lordsGameAllowance: number
  ) => Promise<any>;
  isToppingUpLords: boolean;
  withdraw: (
    masterAccountAddress: string,
    account: AccountInterface,
    ethBalance: bigint,
    lordsBalance: bigint
  ) => Promise<any>;
  isWithdrawing: boolean;
}

export const ArcadeAccountCard = ({
  account,
  disconnect,
  address,
  walletAccount,
  masterAccountAddress,
  arcadeConnectors,
  genNewKey,
  balances,
  getAccountBalances,
  topUpEth,
  isToppingUpEth,
  topUpLords,
  isToppingUpLords,
  withdraw,
  isWithdrawing,
}: ArcadeAccountCardProps) => {
  const { connect } = useConnect();
  const [isCopied, setIsCopied] = useState(false);
  const [topUpScreen, setTopUpScreen] = useState<boolean>(false);
  const [lordsAmount, setLordsAmount] = useState<string>("");

  const connected = address == account.name;

  const formattedEth = (Number(balances?.eth) / 10 ** 18).toFixed(4);
  const formattedLords = (Number(balances?.lords) / 10 ** 18).toFixed(2);

  const copyToClipboard = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setIsCopied(true);
      setTimeout(() => setIsCopied(false), 2000);
    } catch (err) {
      console.error("Failed to copy text: ", err);
    }
  };

  const minimalBalance =
    balances?.eth < BigInt(MIN_BALANCE) && balances?.eth < BigInt(MIN_BALANCE);

  return (
    <div className="border border-terminal-green p-3 items-center">
      <div className="text-left flex flex-col text-sm sm:text-xl mb-0 sm:mb-4 items-center">
        <span
          onClick={() => copyToClipboard(account.name)}
          style={{ cursor: "pointer" }}
        >
          {account.id}
        </span>
        <span className="text-lg w-full">
          {formattedEth === "NaN" ? (
            <span className="loading-ellipsis text-center">Loading</span>
          ) : (
            <span className="flex flex-row justify-between text-sm sm:text-base">
              <span className="flex flex-col">
                <Eth className="fill-current" />
                <p>{formattedEth}</p>
              </span>
              <span className="flex flex-col">
                <Lords className="fill-current" />
                <p>{formattedLords}</p>
              </span>
            </span>
          )}
        </span>{" "}
      </div>
      <div className="flex flex-col gap-2 items-center">
        {!topUpScreen && (
          <>
            <div className="flex flex-row">
              <Button
                variant={connected ? "default" : "ghost"}
                onClick={() => {
                  disconnect();
                  connect({ connector: account });
                }}
              >
                {connected ? "connected" : "connect"}
              </Button>
              {masterAccountAddress == walletAccount?.address && (
                <Button
                  variant={"ghost"}
                  onClick={async () => await genNewKey(account.name)}
                >
                  Create New Keys
                </Button>
              )}
            </div>
            {!arcadeConnectors.some(
              (conn) => conn.id == walletAccount?.address
            ) && (
              <Button variant={"ghost"} onClick={() => setTopUpScreen(true)}>
                Top Ups
              </Button>
            )}
          </>
        )}
        {topUpScreen && (
          <div className="flex flex-col sm:flex-row sm:gap-2 items-center">
            {!arcadeConnectors.some(
              (conn) => conn.id == walletAccount?.address
            ) && (
              <Button
                variant={"ghost"}
                onClick={async () => {
                  await topUpEth(account.name, walletAccount);
                  await getAccountBalances(account.name);
                }}
                disabled={isToppingUpEth}
              >
                <span className="flex flex-col">
                  <span>Add 0.001ETH</span>
                </span>
              </Button>
            )}
            {!arcadeConnectors.some(
              (conn) => conn.id == walletAccount?.address
            ) && (
              <span className="flex flex-row items-center gap-2">
                <span className="flex flex-col">
                  <span>Add Lords</span>
                  <span className="flex flex-row">
                    <input
                      type="number"
                      value={lordsAmount}
                      onChange={(e) => setLordsAmount(e.target.value)}
                      min="1"
                      className="p-1 bg-terminal-black border border-terminal-green text-terminal-green w-20"
                    />
                    <Button
                      variant={"ghost"}
                      onClick={async () => {
                        await topUpLords(
                          account.name,
                          walletAccount,
                          parseInt(lordsAmount),
                          Number(balances?.lordsGameAllowance)
                        );
                        await getAccountBalances(account.name);
                      }}
                      disabled={isToppingUpLords}
                    >
                      Add
                    </Button>
                  </span>
                </span>
              </span>
            )}
            <Button variant={"ghost"} onClick={() => setTopUpScreen(false)}>
              Back
            </Button>
          </div>
        )}
        {connected && (
          <Button
            variant={"ghost"}
            onClick={async () => {
              await withdraw(
                masterAccountAddress,
                walletAccount,
                balances?.eth,
                balances?.lords
              );
              await getAccountBalances(account.name);
            }}
            disabled={isWithdrawing || minimalBalance}
          >
            Withdraw To Master
          </Button>
        )}
      </div>

      {isCopied && <span>Copied!</span>}
    </div>
  );
};
