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
import { getArcadeConnectors, getWalletConnectors } from "@/app/lib/connectors";
import { fetchBalances } from "@/app/lib/balances";
import Lords from "public/icons/lords.svg";
import Eth from "public/icons/eth-2.svg";
import ArcadeLoader from "@/app/components/animations/ArcadeLoader";
import TokenLoader from "@/app/components/animations/TokenLoader";
import { fetchGoldenTokenImage } from "@/app/api/fetchMetadata";
import { getContracts } from "@/app/lib/constants";
import TopupInput from "./arcade/TopupInput";

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
  const { goldenToken } = getContracts();
  const [goldenTokenImage, setGoldenTokenImage] = useState<string | null>(null);
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
    const balances = await fetchBalances(
      account,
      ethContract!,
      lordsContract!,
      gameContract!
    );
    setArcadeBalances({
      ...arcadebalances,
      [account]: {
        eth: balances[0],
        lords: balances[1],
        lordsGameAllowance: balances[2],
      },
    });
  };

  const fetchGoldenToken = async () => {
    const image = await fetchGoldenTokenImage(goldenToken ?? "");
    setGoldenTokenImage(image);
  };

  useEffect(() => {
    fetchGoldenToken();
  }, []);

  useEffect(() => {
    getBalances();
  }, [arcadeConnectors, fetchedBalances]);

  if (!connectors) return <div></div>;

  return (
    <>
      <div className="fixed inset-0 opacity-80 bg-terminal-black z-40" />
      <div className="fixed flex flex-col text-center items-center justify-between sm:top-1/8 sm:left-1/8 sm:left-1/4 sm:w-3/4 sm:w-1/2 h-full sm:h-3/4 border-4 bg-terminal-black z-50 border-terminal-green p-4">
        <h3 className="mt-4">Arcade Accounts</h3>
        <div className="flex flex-col">
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
                  Note: This will initiate a transfer of 0.001 ETH & 250 LORDS
                  from your connected wallet to the arcade account to cover your
                  transaction costs from normal gameplay.
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
        </div>
        <div className="grid grid-cols-2 sm:grid-cols-3 2xl:grid-cols-4 gap-4 overflow-hidden my-6 h-1/3 w-full overflow-y-auto">
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
                goldenTokenImage={goldenTokenImage}
              />
            );
          })}
        </div>
        <Button
          onClick={() => showArcadeDialog(!arcadeDialog)}
          className="w-1/2"
        >
          close
        </Button>
      </div>
      {(isDeploying || isGeneratingNewKey) && (
        <ArcadeLoader
          isSettingPermissions={isSettingPermissions}
          isGeneratingNewKey={isGeneratingNewKey}
        />
      )}
      {(isToppingUpEth || isToppingUpLords || isWithdrawing) && (
        <TokenLoader
          isToppingUpEth={isToppingUpEth}
          isToppingUpLords={isToppingUpLords}
        />
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
  goldenTokenImage: any;
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
  goldenTokenImage,
}: ArcadeAccountCardProps) => {
  const { connect, connectors } = useConnect();
  const [isCopied, setIsCopied] = useState(false);
  const [selectedTopup, setSelectedTopup] = useState<string | null>(null);

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

  const walletConnectors = getWalletConnectors(connectors);

  const masterConnector = walletConnectors.find(
    (conn: any) => conn._wallet.selectedAddress === masterAccountAddress
  );

  const isArcade = arcadeConnectors.some(
    (conn) => conn.name == walletAccount?.address
  );

  return (
    <div className="border border-terminal-green p-3 items-center">
      <div className="text-left flex flex-col gap-2 text-sm sm:text-xl mb-0 sm:mb-4 items-center">
        <div className="flex flex-row items-center gap-2">
          <Button
            onClick={() => copyToClipboard(account.name)}
            variant={connected ? "default" : "outline"}
            size={"md"}
          >
            {account.id}
          </Button>
          {isCopied && <span>Copied!</span>}
        </div>
        <span className="text-lg w-full">
          {formattedEth === "NaN" ? (
            <span className="loading-ellipsis text-center">Loading</span>
          ) : (
            <span className="flex flex-row justify-between text-sm sm:text-base">
              <span className="flex flex-col items-center w-1/3">
                <Eth className="fill-black h-6 sm:h-8" />
                <p className="sm:text-xl">{formattedEth}</p>
                <div className="hidden sm:block">
                  <TopupInput
                    balanceType="eth"
                    increment={0.0001}
                    disabled={isArcade}
                    topup={topUpEth}
                    account={account.name}
                    master={walletAccount}
                    lordsGameAllowance={0}
                    getBalances={async () =>
                      await getAccountBalances(account.name)
                    }
                  />
                </div>
                <Button
                  className="sm:hidden"
                  onClick={() => setSelectedTopup("eth")}
                  disabled={selectedTopup === "eth"}
                >
                  Add
                </Button>
              </span>
              <span className="flex flex-col items-center w-1/3">
                <Lords className="fill-current h-6 sm:h-8" />
                <p className="sm:text-xl">{formattedLords}</p>
                <div className="hidden sm:block">
                  <TopupInput
                    balanceType="lords"
                    increment={50}
                    disabled={isArcade}
                    topup={topUpLords}
                    account={account.name}
                    master={walletAccount}
                    lordsGameAllowance={Number(balances?.lordsGameAllowance)}
                    getBalances={async () =>
                      await getAccountBalances(account.name)
                    }
                  />
                </div>
                <Button
                  className="sm:hidden"
                  onClick={() => setSelectedTopup("lords")}
                  disabled={selectedTopup === "lords"}
                >
                  Add
                </Button>
              </span>
              <span className="flex flex-col items-center w-1/3">
                <img
                  src={goldenTokenImage ?? ""}
                  alt="Golden Token"
                  className="fill-current right-0 h-6 sm:h-8"
                />
                <p className="sm:text-xl">0</p>
                <Button size={"xxxs"} className="text-black" disabled={true}>
                  Buy
                </Button>
              </span>
            </span>
          )}
        </span>
        {selectedTopup && (
          <TopupInput
            balanceType={selectedTopup!}
            increment={selectedTopup === "eth" ? 0.0001 : 50}
            disabled={isArcade}
            topup={selectedTopup === "eth" ? topUpEth : topUpLords}
            account={account.name}
            master={walletAccount}
            lordsGameAllowance={
              selectedTopup === "eth" ? 0 : Number(balances?.lordsGameAllowance)
            }
            getBalances={async () => await getAccountBalances(account.name)}
          />
        )}
      </div>
      <div className="flex flex-col gap-2 items-center">
        <Button
          variant={"ghost"}
          onClick={() => {
            disconnect();
            connected
              ? connect({ connector: masterConnector! })
              : connect({ connector: account });
          }}
        >
          {connected ? "Connect to Master" : "Connect"}
        </Button>
        {masterAccountAddress == walletAccount?.address && (
          <Button
            variant={"ghost"}
            onClick={async () => await genNewKey(account.name)}
          >
            Create New Keys
          </Button>
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
    </div>
  );
};
