import { useCallback, useEffect, useState } from "react";
import {
  Account,
  AccountInterface,
  CallData,
  ec,
  hash,
  Provider,
  stark,
  TransactionFinalityStatus,
  Call,
  selector,
} from "starknet";
import Storage from "./storage";
import { useAccount, useConnectors } from "@starknet-react/core";
import { ArcadeConnector } from "./arcade";
import { useContracts } from "../hooks/useContracts";
import { BurnerStorage } from "../types";

export const PREFUND_AMOUNT = "0x38D7EA4C68000"; // 0.001ETH

const provider = new Provider({
  sequencer: {
    baseUrl: "https://alpha4.starknet.io",
  },
});

export const useBurner = () => {
  const { refresh } = useConnectors();
  const { account: walletAccount } = useAccount();
  const [account, setAccount] = useState<Account>();
  const [isDeploying, setIsDeploying] = useState(false);
  const [isGeneratingNewKey, setIsGeneratingNewKey] = useState(false);
  const [isSettingPermissions, setIsSettingPermissions] = useState(false);
  const [isToppingUp, setIsToppingUp] = useState(false);
  const [isWithdrawing, setIsWithdrawing] = useState(false);
  const { gameContract, lordsContract } = useContracts();

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
      if (storage[address].gameContract === gameContract?.address) {
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

  const create = useCallback(async () => {
    setIsDeploying(true);
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
      process.env.NEXT_PUBLIC_ACCOUNT_CLASS_HASH!,
      constructorAACalldata,
      0
    );

    try {
      await prefundAccount(address, walletAccount);
    } catch (e) {
      setIsDeploying(false);
    }

    // deploy burner
    const burner = new Account(provider, address, privateKey, "1");

    const {
      transaction_hash: deployTx,
      contract_address: accountAAFinalAdress,
    } = await burner.deployAccount({
      classHash: process.env.NEXT_PUBLIC_ACCOUNT_CLASS_HASH!,
      constructorCalldata: constructorAACalldata,
      contractAddress: address,
      addressSalt: publicKey,
    });

    await provider.waitForTransaction(deployTx);

    setIsSettingPermissions(true);

    const setPermissionsTx = await setPermissions(
      accountAAFinalAdress,
      walletAccount
    );

    await provider.waitForTransaction(setPermissionsTx);

    // save burner
    let storage = Storage.get("burners") || {};
    for (let address in storage) {
      storage[address].active = false;
    }

    storage[address] = {
      privateKey,
      publicKey,
      deployTx,
      setPermissionsTx,
      masterAccount: walletAccount.address,
      gameContract: gameContract?.address,
      active: true,
    };

    setAccount(burner);
    Storage.set("burners", storage);
    setIsSettingPermissions(false);
    setIsDeploying(false);
    refresh();
    window.location.reload();
    return burner;
  }, [walletAccount]);

  const setPermissions = useCallback(
    async (accountAAFinalAdress: any, walletAccount: any) => {
      const permissions: Call[] = [
        {
          contractAddress: accountAAFinalAdress,
          entrypoint: "update_whitelisted_contracts",
          calldata: [
            "2",
            gameContract?.address ?? "",
            "1",
            lordsContract?.address ?? "",
            "1",
          ],
        },
        {
          contractAddress: accountAAFinalAdress,
          entrypoint: "update_whitelisted_calls",
          calldata: [
            "1",
            process.env.NEXT_PUBLIC_ETH_CONTRACT_ADDRESS!,
            selector.getSelectorFromName("transfer"),
            "1",
          ],
        },
      ];

      const { transaction_hash: permissionsTx } = await walletAccount.execute(
        permissions
      );

      return permissionsTx;
    },
    []
  );

  const topUp = async (address: string, account: AccountInterface) => {
    try {
      setIsToppingUp(true);
      const { transaction_hash } = await account.execute({
        contractAddress: process.env.NEXT_PUBLIC_ETH_CONTRACT_ADDRESS!,
        entrypoint: "transfer",
        calldata: CallData.compile([address, PREFUND_AMOUNT, "0x0"]),
      });

      const result = await account.waitForTransaction(transaction_hash, {
        retryInterval: 1000,
        successStates: [TransactionFinalityStatus.ACCEPTED_ON_L2],
      });

      if (!result) {
        throw new Error("Transaction did not complete successfully.");
      }

      setIsToppingUp(false);
      return result;
    } catch (error) {
      console.error(error);
      throw error;
    }
  };

  const withdraw = async (
    masterAccountAddress: string,
    account: AccountInterface,
    balance: bigint
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
        contractAddress: process.env.NEXT_PUBLIC_ETH_CONTRACT_ADDRESS!,
        entrypoint: "transfer",
        calldata: CallData.compile([
          masterAccountAddress,
          balance ?? "0x0",
          "0x0",
        ]),
      };

      const { suggestedMaxFee: estimatedFee } = await mainAccount.estimateFee(
        call
      );

      // Now we negate the fee from balance to withdraw (+10% for safety)

      const newBalance =
        BigInt(balance) - estimatedFee * (BigInt(11) / BigInt(10));

      const { transaction_hash } = await account.execute({
        contractAddress: process.env.NEXT_PUBLIC_ETH_CONTRACT_ADDRESS!,
        entrypoint: "transfer",
        calldata: CallData.compile([
          masterAccountAddress,
          newBalance ?? "0x0",
          "0x0",
        ]),
      });

      const result = await account.waitForTransaction(transaction_hash, {
        retryInterval: 1000,
        successStates: [TransactionFinalityStatus.ACCEPTED_ON_L2],
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
    async (burnerAddress: string) => {
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
        gameContract: gameContract?.address,
        active: true,
      };

      Storage.set("burners", storage);
      setIsGeneratingNewKey(false);
      refresh();
      window.location.reload();
    },
    [walletAccount]
  );

  const listConnectors = useCallback(() => {
    const arcadeAccounts = [];
    const burners = list();

    for (const burner of burners) {
      if (burner) {
        const arcadeConnector = new ArcadeConnector(
          {
            options: {
              id: burner.address,
            },
          },
          get(burner.address)
        );

        arcadeAccounts.push(arcadeConnector);
      }
    }

    return arcadeAccounts;
  }, [account, isDeploying]);

  // useEffect(() => {
  //     const interval = setInterval(refresh, 2000)
  //     return () => clearInterval(interval)
  // }, [refresh])

  return {
    get,
    getMasterAccount,
    list,
    select,
    create,
    topUp,
    withdraw,
    genNewKey,
    account,
    isDeploying,
    isSettingPermissions,
    isGeneratingNewKey,
    isToppingUp,
    isWithdrawing,
    listConnectors,
  };
};

const prefundAccount = async (address: string, account: AccountInterface) => {
  try {
    const { transaction_hash } = await account.execute({
      contractAddress: process.env.NEXT_PUBLIC_ETH_CONTRACT_ADDRESS!,
      entrypoint: "transfer",
      calldata: CallData.compile([address, PREFUND_AMOUNT, "0x0"]),
    });

    const result = await account.waitForTransaction(transaction_hash, {
      retryInterval: 1000,
      successStates: [TransactionFinalityStatus.ACCEPTED_ON_L2],
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
