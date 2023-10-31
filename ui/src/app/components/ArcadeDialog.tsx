import React, { useEffect, useState, useCallback, ChangeEvent } from "react";
import { AccountInterface, Contract } from "starknet";
import {
  Connector,
  useAccount,
  useConnect,
  useDisconnect,
  useContract,
} from "@starknet-react/core";
import useUIStore from "@/app/hooks/useUIStore";
import { Button } from "@/app/components/buttons/Button";
import { useBurner } from "@/app/lib/burner";
import { MIN_BALANCE } from "@/app/lib/constants";
import { getArcadeConnectors, getWalletConnectors } from "@/app/lib/connectors";
import { fetchBalances } from "@/app/lib/balances";
import { isChecksumAddress, padAddress, indexAddress } from "../lib/utils";
import Lords from "public/icons/lords.svg";
import Eth from "public/icons/eth-2.svg";
import ArcadeLoader from "@/app/components/animations/ArcadeLoader";
import TokenLoader from "@/app/components/animations/TokenLoader";
import TopupInput from "@/app/components/arcade/TopupInput";
import ArcadeAccount from "@/app/abi/ArcadeAccount.json";
import Storage from "@/app/lib/storage";
import { BurnerStorage } from "@/app/types";

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
  const [recoverArcade, setRecoverArcade] = useState(false);
  const [recoveryAddress, setRecoveryAddress] = useState<string | undefined>();
  const [recoveryMasterAddress, setRecoveryMasterAddress] = useState<
    string | undefined
  >();
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
  } = useBurner({ walletAccount, gameContract, lordsContract, ethContract });
  const [arcadebalances, setArcadeBalances] = useState<
    Record<string, { eth: bigint; lords: bigint; lordsGameAllowance: bigint }>
  >({});

  // Needs to be callback else infinite loop
  const arcadeConnectors = useCallback(() => {
    return getArcadeConnectors(connectors);
  }, [connectors]);

  const walletConnectors = getWalletConnectors(connectors);
  const walletConnected = walletConnectors.some(
    (walletConnector) => walletConnector == connector
  );

  const formattedRecoveryAddress = padAddress(
    padAddress(recoveryAddress ?? "")
  );

  const { contract: arcadeContract } = useContract({
    address: formattedRecoveryAddress,
    abi: ArcadeAccount,
  });

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

  const handleChange = (
    e: ChangeEvent<HTMLInputElement | HTMLSelectElement>
  ) => {
    const { value } = e.target;
    setRecoveryAddress(value);
  };

  const handleGetMaster = async () => {
    const masterAccount = await arcadeContract?.call("get_master_account");
    setRecoveryMasterAddress("0x" + masterAccount?.toString(16));
  };

  useEffect(() => {
    getBalances();
  }, [arcadeConnectors, fetchedBalances]);

  useEffect(() => {
    if (isChecksumAddress(formattedRecoveryAddress)) {
      handleGetMaster();
    }
  }, [recoveryAddress]);

  const isMasterAccount =
    padAddress(address ?? "") === padAddress(recoveryMasterAddress ?? "");
  const recoveryAccountExists = () => {
    const storage: BurnerStorage = Storage.get("burners");
    if (storage) {
      return Object.keys(storage).includes(formattedRecoveryAddress ?? "");
    } else {
      return false;
    }
  };

  if (!connectors) return <div></div>;

  return (
    <>
      <div className="fixed inset-0 opacity-80 bg-terminal-black z-40" />
      <div className="fixed flex flex-col text-center items-center justify-between sm:top-1/8 sm:left-1/8 sm:left-1/4 sm:w-3/4 sm:w-1/2 h-full sm:h-3/4 border-4 bg-terminal-black z-50 border-terminal-green p-4">
        <h3 className="mt-4">Arcade Accounts</h3>
        {recoverArcade ? (
          <div className="flex flex-col items-center gap-5 h-3/4 w-full">
            <p className="text-3xl uppercase">Recover Arcade</p>
            <p className="text-lg">Enter address of the Arcade Account.</p>
            <input
              type="text"
              name="address"
              onChange={handleChange}
              className="p-1 m-2 bg-terminal-black border border-terminal-green animate-pulse transform w-1/2 2xl:h-16 2xl:text-4xl"
              maxLength={66}
            />
            {recoveryAddress && !isMasterAccount && (
              <>
                <p className="text-lg">Connect Master Account</p>
                {walletConnectors.map((connector, index) => (
                  <Button
                    disabled={
                      !isChecksumAddress(formattedRecoveryAddress) ||
                      isMasterAccount
                    }
                    onClick={() => {
                      disconnect();
                      connect({ connector });
                    }}
                    key={index}
                  >
                    {connector.id === "braavos" || connector.id === "argentX"
                      ? `Connect ${connector.id}`
                      : "Login With Email"}
                  </Button>
                ))}
              </>
            )}
            <Button
              onClick={async () => {
                await genNewKey(formattedRecoveryAddress, connector!);
                updateConnectors();
                setRecoverArcade(false);
              }}
              disabled={!isMasterAccount || recoveryAccountExists()}
              className="w-1/4"
            >
              {recoveryAccountExists()
                ? "Account Already Stored"
                : "Recover Account"}
            </Button>
          </div>
        ) : (
          <>
            <div className="flex flex-col">
              <p className="m-2 text-sm xl:text-xl 2xl:text-2xl">
                Go deep into the mist with signature free gameplay! Simply
                connect your wallet and create a free arcade account.
              </p>

              <div className="flex justify-center mb-1">
                <div className="flex flex-col">
                  <p className="my-2 text-sm sm:text-base text-terminal-yellow p-2 border border-terminal-yellow">
                    Note: Creating an account will initiate a transfer of 0.001
                    ETH & 250 LORDS from your connected wallet to the arcade
                    account to cover your transaction costs from gameplay.
                  </p>
                  <div className="flex flex-row justify-center gap-5">
                    <Button
                      onClick={async () => {
                        await create(connector!);
                        connect({ connector: listConnectors()[0] });
                        updateConnectors();
                      }}
                      disabled={isWrongNetwork || !walletConnected}
                    >
                      Create Account
                    </Button>
                    <Button onClick={() => setRecoverArcade(true)}>
                      Recover Account
                    </Button>
                  </div>
                </div>
              </div>
            </div>
            <div className="grid grid-cols-2 sm:grid-cols-3 2xl:grid-cols-4 gap-4 overflow-hidden my-6 h-1/2 w-full overflow-y-auto default-scroll">
              {arcadeConnectors().map((account, index) => {
                const masterAccount = getMasterAccount(account.name);
                return (
                  <ArcadeAccountCard
                    key={index}
                    account={account}
                    disconnect={disconnect}
                    address={address!}
                    walletAccount={walletAccount!}
                    connector={connector!}
                    masterAccountAddress={masterAccount}
                    arcadeConnectors={arcadeConnectors()}
                    genNewKey={genNewKey}
                    balances={arcadebalances[account.name]}
                    getAccountBalances={getAccountBalances}
                    topUpEth={topUpEth}
                    topUpLords={topUpLords}
                    withdraw={withdraw}
                    isWithdrawing={isWithdrawing}
                  />
                );
              })}
            </div>
          </>
        )}
        <Button
          onClick={() => showArcadeDialog(!arcadeDialog)}
          className="w-1/2 sm:w-1/4"
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
  connector: Connector;
  masterAccountAddress: string;
  arcadeConnectors: any[];
  genNewKey: (address: string, connector: Connector) => Promise<void>;
  balances: { eth: bigint; lords: bigint; lordsGameAllowance: bigint };
  getAccountBalances: (address: string) => Promise<void>;
  topUpEth: (address: string, account: AccountInterface) => Promise<any>;
  topUpLords: (
    address: string,
    account: AccountInterface,
    lordsAmount: number,
    lordsGameAllowance: number
  ) => Promise<any>;
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
  connector,
  masterAccountAddress,
  arcadeConnectors,
  genNewKey,
  balances,
  getAccountBalances,
  topUpEth,
  topUpLords,
  withdraw,
  isWithdrawing,
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
    (conn: any) => conn._wallet?.selectedAddress === masterAccountAddress
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
            {indexAddress(account.id)}
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
              {/* <span className="flex flex-col items-center w-1/3">
                <div className="relative w-6 h-6 sm:w-8 sm:h-8">
                  <Image
                    src={"/golden-token.png"}
                    alt="Golden Token"
                    fill={true}
                  />
                </div>
                <p className="sm:text-xl">0</p>
                <Button size={"xxxs"} className="text-black" disabled={true}>
                  Buy
                </Button>
              </span> */}
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
            onClick={async () => await genNewKey(account.name, connector!)}
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
