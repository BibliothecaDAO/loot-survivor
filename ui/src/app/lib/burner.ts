import { useCallback, useEffect, useState } from "react";
import {
  Account,
  AccountInterface,
  CallData,
  ec,
  hash,
  Provider,
  stark,
  Call,
  selector,
  Contract,
} from "starknet";
import { Connector } from "@starknet-react/core";
import Storage from "@/app/lib/storage";
import { ArcadeConnector } from "@/app/lib/arcade";
import { BurnerStorage } from "@/app/types";
import { padAddress } from "@/app/lib/utils";
import { TRANSACTION_WAIT_RETRY_INTERVAL } from "@/app/lib/constants";

const isMainnet = process.env.NEXT_PUBLIC_NETWORK == "mainnet";
export const ETH_PREFUND_AMOUNT = isMainnet
  ? "0x2386F26FC10000"
  : "0x38D7EA4C68000"; // 0.01ETH on Mainnet, 0.001ETH on Testnet
export const LORDS_PREFUND_AMOUNT = "0x15AF1D78B58C40000"; // 25LORDS

const rpc_addr = process.env.NEXT_PUBLIC_RPC_URL;
const provider = new Provider({
  rpc: { nodeUrl: rpc_addr! },
  sequencer: { baseUrl: rpc_addr! },
});

interface UseBurnerProps {
  walletAccount?: AccountInterface;
  gameContract?: Contract;
  lordsContract?: Contract;
  ethContract?: Contract;
}

export const useBurner = ({
  walletAccount,
  gameContract,
  lordsContract,
  ethContract,
}: UseBurnerProps) => {
  const [account, setAccount] = useState<Account>();
  const [showLoader, setShowLoader] = useState(false);
  const [isPrefunding, setIsPrefunding] = useState(false);
  const [isDeploying, setIsDeploying] = useState(false);
  const [isGeneratingNewKey, setIsGeneratingNewKey] = useState(false);
  const [isSettingPermissions, setIsSettingPermissions] = useState(false);
  const [isToppingUpEth, setIsToppingUpEth] = useState(false);
  const [isToppingUpLords, setIsToppingUpLords] = useState(false);
  const [isWithdrawing, setIsWithdrawing] = useState(false);
  const arcadeClassHash = process.env.NEXT_PUBLIC_ARCADE_ACCOUNT_CLASS_HASH;

  // init
  useEffect(() => {
    const storage: BurnerStorage = Storage.get("burners");
    if (storage) {
      // check one to see if exists, perhaps appchain restarted
      const firstAddr = Object.keys(storage)[0];
      walletAccount
        ?.getTransactionReceipt(storage[firstAddr].deployTx)
        .catch(() => {
          setAccount(undefined);
          Storage.remove("burners");
          throw new Error("burners not deployed, chain may have restarted");
        });

      // set active account
      for (let address in storage) {
        if (storage[address].active) {
          const burner = new Account(
            provider,
            address,
            storage[address].privateKey
          );
          setAccount(burner);
          return;
        }
      }
    }
  }, []);

  const list = useCallback(() => {
    let storage = Storage.get("burners") || {};
    return Object.keys(storage).map((address) => {
      if (
        storage[address].gameContract ===
          process.env.NEXT_PUBLIC_GAME_ADDRESS ||
        storage[address].gameContract ===
          process.env.NEXT_PUBLIC_OLD_GAME_ADDRESS
      ) {
        return {
          address,
          active: storage[address].active,
        };
      }
    });
  }, [walletAccount]);

  const select = useCallback(
    (address: string) => {
      let storage = Storage.get("burners") || {};
      if (!storage[address]) {
        throw new Error("burner not found");
      }

      for (let addr in storage) {
        storage[addr].active = false;
      }
      storage[address].active = true;

      Storage.set("burners", storage);
      const burner = new Account(
        provider,
        address,
        storage[address].privateKey
      );
      setAccount(burner);
    },
    [walletAccount]
  );

  const get = useCallback(
    (address: string) => {
      let storage = Storage.get("burners") || {};
      if (!storage[address]) {
        throw new Error("burner not found");
      }

      return new Account(provider, address, storage[address].privateKey, "1");
    },
    [walletAccount]
  );

  const getMasterAccount = useCallback(
    (address: string) => {
      let storage = Storage.get("burners") || {};
      if (!storage[address]) {
        throw new Error("burner not found");
      }

      return storage[address].masterAccount;
    },
    [walletAccount]
  );

  const prefundAccount = async (
    address: string,
    account: AccountInterface,
    lordsAmount: number
  ) => {
    try {
      const transferEthTx = {
        contractAddress: ethContract?.address ?? "0x0",
        entrypoint: "transfer",
        calldata: CallData.compile([address, ETH_PREFUND_AMOUNT, "0x0"]),
      };

      const transferLordsTx = {
        contractAddress: lordsContract?.address ?? "0x0",
        entrypoint: "transfer",
        calldata: CallData.compile([address, lordsAmount.toString(), "0x0"]),
      };

      const prefundCalls =
        lordsAmount > 0 ? [transferEthTx, transferLordsTx] : [transferEthTx];

      const { transaction_hash } = await account.execute(prefundCalls);

      const result = await account.waitForTransaction(transaction_hash, {
        retryInterval: TRANSACTION_WAIT_RETRY_INTERVAL,
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

  const create = useCallback(
    async (connector: Connector, lordsAmount: number) => {
      setShowLoader(true);
      setIsPrefunding(true);
      const privateKey = stark.randomAddress();
      const publicKey = ec.starkCurve.getStarkKey(privateKey);

      if (!walletAccount) {
        throw new Error("wallet account not found");
      }

      const constructorAACalldata = CallData.compile({
        _public_key: publicKey,
        _master_account: walletAccount.address,
      });

      const address = hash.calculateContractAddressFromHash(
        publicKey,
        arcadeClassHash!,
        constructorAACalldata,
        0
      );

      // save keys
      let storageKeys = Storage.get("keys") || {};
      storageKeys[padAddress(address)] = {
        privateKey,
        publicKey,
        masterAccount: walletAccount.address,
        masterAccountProvider: connector.id,
        gameContract: gameContract?.address,
        active: true,
      };

      Storage.set("keys", storageKeys);

      try {
        await prefundAccount(address, walletAccount, lordsAmount);

        setIsPrefunding(false);
        setIsDeploying(true);

        // deploy burner
        const burner = new Account(provider, address, privateKey, "1");

        const feeEstimateResult = await burner.estimateAccountDeployFee({
          classHash: arcadeClassHash!,
          constructorCalldata: constructorAACalldata,
          contractAddress: address,
          addressSalt: publicKey,
        });

        const {
          transaction_hash: deployTx,
          contract_address: accountAAFinalAddress,
        } = await burner.deployAccount(
          {
            classHash: arcadeClassHash!,
            constructorCalldata: constructorAACalldata,
            contractAddress: address,
            addressSalt: publicKey,
          },
          {
            maxFee: feeEstimateResult.suggestedMaxFee * BigInt(2),
          }
        );

        await provider.waitForTransaction(deployTx);

        setIsDeploying(false);

        const setPermissionsTx = await setPermissions(
          accountAAFinalAddress,
          walletAccount
        );

        // save burner
        let storage = Storage.get("burners") || {};
        for (let address in storage) {
          storage[address].active = false;
        }

        storage[padAddress(accountAAFinalAddress)] = {
          privateKey,
          publicKey,
          deployTx,
          setPermissionsTx,
          masterAccount: walletAccount.address,
          masterAccountProvider: connector.id,
          gameContract: gameContract?.address,
          active: true,
        };

        setAccount(burner);
        Storage.set("burners", storage);
        setShowLoader(false);
        return burner;
      } catch (e) {
        console.log(e);
        setIsPrefunding(false);
        setIsDeploying(false);
        setIsSettingPermissions(false);
        setShowLoader(false);
      }
    },
    [walletAccount]
  );

  const setPermissions = useCallback(
    async (
      accountAAFinalAdress: string,
      walletAccount: AccountInterface,
      alreadyDeployed?: boolean
    ) => {
      try {
        setShowLoader(true);
        setIsSettingPermissions(true);
        const permissions: Call[] = [
          {
            contractAddress: accountAAFinalAdress,
            entrypoint: "update_whitelisted_contracts",
            calldata: ["1", gameContract?.address ?? "", "1"],
          },
          {
            contractAddress: accountAAFinalAdress,
            entrypoint: "update_whitelisted_calls",
            calldata: [
              "3",
              ethContract?.address ?? "",
              selector.getSelectorFromName("transfer"),
              "1",
              lordsContract?.address ?? "",
              selector.getSelectorFromName("approve"),
              "1",
              lordsContract?.address ?? "",
              selector.getSelectorFromName("transfer"),
              "1",
            ],
          },
        ];

        const { transaction_hash: permissionsTx } = await walletAccount.execute(
          permissions
        );

        await provider.waitForTransaction(permissionsTx);

        if (alreadyDeployed) {
          // save burner
          let storage = Storage.get("burners") || {};
          for (let address in storage) {
            storage[address].active = false;
          }
          storage[padAddress(accountAAFinalAdress)].gameContract =
            gameContract?.address ?? "";

          Storage.set("burners", storage);
          setShowLoader(false); // close loader for set permissions called from deployed arcade
        }

        setIsSettingPermissions(false);
        return permissionsTx;
      } catch (e) {
        setIsSettingPermissions(false);
        setShowLoader(false);
        throw new Error("Error setting permissions.");
      }
    },
    []
  );

  const topUpEth = async (
    address: string,
    account: AccountInterface,
    ethAmount?: number
  ) => {
    try {
      setIsToppingUpEth(true);
      const { transaction_hash } = await account.execute({
        contractAddress: ethContract?.address ?? "",
        entrypoint: "transfer",
        calldata: CallData.compile([
          address,
          ethAmount
            ? Math.round(ethAmount * 10 ** 18).toString()
            : ETH_PREFUND_AMOUNT,
          "0x0",
        ]),
      });

      const result = await account.waitForTransaction(transaction_hash, {
        retryInterval: TRANSACTION_WAIT_RETRY_INTERVAL,
      });

      if (!result) {
        throw new Error("Transaction did not complete successfully.");
      }

      // Wait for 5 seconds for balance to change
      await new Promise((resolve) => setTimeout(resolve, 5000));

      setIsToppingUpEth(false);
      return result;
    } catch (e) {
      setIsToppingUpEth(false);
      console.log(e);
    }
  };

  const topUpLords = async (
    address: string,
    account: AccountInterface,
    lordsAmount: number
  ) => {
    try {
      setIsToppingUpLords(true);
      const lordsTransferTx = {
        contractAddress: lordsContract?.address ?? "",
        entrypoint: "transfer",
        calldata: CallData.compile([
          address,
          Math.round(lordsAmount * 10 ** 18).toString(),
          "0x0",
        ]),
      };
      const { transaction_hash } = await account.execute([lordsTransferTx]);

      const result = await account.waitForTransaction(transaction_hash, {
        retryInterval: TRANSACTION_WAIT_RETRY_INTERVAL,
      });

      if (!result) {
        throw new Error("Transaction did not complete successfully.");
      }

      // Wait for 5 seconds for balance to change
      await new Promise((resolve) => setTimeout(resolve, 5000));

      setIsToppingUpLords(false);
      return result;
    } catch (e) {
      setIsToppingUpLords(false);
      console.log(e);
    }
  };

  const withdraw = async (
    masterAccountAddress: string,
    account: AccountInterface,
    ethBalance: bigint,
    lordsBalance: bigint
  ) => {
    try {
      setIsWithdrawing(true);

      // First we need to calculate the fee from withdrawing

      const mainAccount = new Account(
        provider,
        account.address,
        account.signer,
        account.cairoVersion
      );

      const call = {
        contractAddress: ethContract?.address ?? "",
        entrypoint: "transfer",
        calldata: CallData.compile([
          masterAccountAddress,
          ethBalance ?? "0x0",
          "0x0",
        ]),
      };

      const transferLordsTx = {
        contractAddress: lordsContract?.address ?? "",
        entrypoint: "transfer",
        calldata: CallData.compile([
          masterAccountAddress,
          lordsBalance ?? "0x0",
          "0x0",
        ]),
      };

      const { suggestedMaxFee: estimatedFee } = await mainAccount.estimateFee([
        call,
        transferLordsTx,
      ]);

      // Now we negate the fee from balance to withdraw (+10% for safety)

      const newEthBalance =
        BigInt(ethBalance) - estimatedFee * (BigInt(11) / BigInt(10));

      const transferEthTx = {
        contractAddress: ethContract?.address ?? "",
        entrypoint: "transfer",
        calldata: CallData.compile([
          masterAccountAddress,
          newEthBalance ?? "0x0",
          "0x0",
        ]),
      };

      // If they have Lords also withdraw
      const calls =
        lordsBalance > BigInt(0)
          ? [transferEthTx, transferLordsTx]
          : [transferEthTx];

      const { transaction_hash } = await account.execute(calls);

      const result = await account.waitForTransaction(transaction_hash, {
        retryInterval: TRANSACTION_WAIT_RETRY_INTERVAL,
      });

      if (!result) {
        throw new Error("Transaction did not complete successfully.");
      }

      setIsWithdrawing(false);
      return result;
    } catch (error) {
      console.error(error);
      throw error;
    }
  };

  const genNewKey = useCallback(
    async (burnerAddress: string, connector: Connector) => {
      try {
        setShowLoader(true);
        setIsGeneratingNewKey(true);
        const privateKey = stark.randomAddress();
        const publicKey = ec.starkCurve.getStarkKey(privateKey);

        if (!walletAccount) {
          throw new Error("wallet account not found");
        }

        const { transaction_hash } = await walletAccount.execute({
          contractAddress: burnerAddress,
          entrypoint: "set_public_key",
          calldata: [publicKey],
        });

        await provider.waitForTransaction(transaction_hash);

        // save new keys
        let storage = Storage.get("burners") || {};
        for (let address in storage) {
          storage[address].active = false;
        }

        storage[burnerAddress] = {
          privateKey,
          publicKey,
          masterAccount: walletAccount.address,
          masterAccountProvider: connector.id,
          gameContract: gameContract?.address,
          active: true,
        };

        Storage.set("burners", storage);
        setIsGeneratingNewKey(false);
        setShowLoader(false);
      } catch (e) {
        setIsGeneratingNewKey(false);
        console.log(e);
      }
    },
    [walletAccount]
  );

  const deployAccountFromHash = useCallback(
    async (
      connector: Connector,
      address: string,
      walletAccount: AccountInterface
    ) => {
      setShowLoader(true);
      setIsDeploying(true);

      // get keys
      let storageKeys = Storage.get("keys") || {};

      const privateKey = storageKeys[address].privateKey;
      const publicKey = storageKeys[address].publicKey;

      if (!walletAccount) {
        throw new Error("wallet account not found");
      }

      const constructorAACalldata = CallData.compile({
        _public_key: publicKey,
        _master_account: walletAccount.address,
      });

      try {
        // deploy burner
        const burner = new Account(provider, address, privateKey, "1");

        const feeEstimateResult = await burner.estimateAccountDeployFee({
          classHash: arcadeClassHash!,
          constructorCalldata: constructorAACalldata,
          contractAddress: address,
          addressSalt: publicKey,
        });

        const {
          transaction_hash: deployTx,
          contract_address: accountAAFinalAddress,
        } = await burner.deployAccount(
          {
            classHash: arcadeClassHash!,
            constructorCalldata: constructorAACalldata,
            contractAddress: address,
            addressSalt: publicKey,
          },
          {
            maxFee: feeEstimateResult.suggestedMaxFee * BigInt(2),
          }
        );

        await provider.waitForTransaction(deployTx);

        // save burner
        let storage = Storage.get("burners") || {};
        for (let address in storage) {
          storage[address].active = false;
        }

        storage[padAddress(accountAAFinalAddress)] = {
          privateKey,
          publicKey,
          deployTx,
          masterAccount: walletAccount.address,
          masterAccountProvider: connector.id,
          gameContract: gameContract?.address,
          active: true,
        };
        Storage.set("burners", storage);
        setIsDeploying(false);
        setShowLoader(false);
      } catch (e) {
        setIsDeploying(false);
        console.log(e);
      }
    },
    []
  );

  const listConnectors = useCallback(() => {
    const arcadeAccounts = [];
    const burners = list();

    for (const burner of burners) {
      if (burner) {
        const arcadeConnector = new ArcadeConnector(get(burner.address));

        arcadeAccounts.push(arcadeConnector);
      }
    }

    return arcadeAccounts;
  }, [account, isDeploying]);

  return {
    get,
    getMasterAccount,
    list,
    select,
    create,
    topUpEth,
    topUpLords,
    withdraw,
    genNewKey,
    setPermissions,
    setIsSettingPermissions,
    account,
    isPrefunding,
    isDeploying,
    isSettingPermissions,
    isGeneratingNewKey,
    isToppingUpEth,
    isToppingUpLords,
    isWithdrawing,
    showLoader,
    setShowLoader,
    listConnectors,
    deployAccountFromHash,
  };
};
