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
} from "starknet";
import Storage from "@/app/lib/storage";
import { useAccount, useConnectors } from "@starknet-react/core";
import { ArcadeConnector } from "@/app/lib/arcade";
import { useContracts } from "@/app/hooks/useContracts";
import { BurnerStorage } from "@/app/types";
import { getRPCUrl, getArcadeClassHash } from "@/app/lib/constants";

export const ETH_PREFUND_AMOUNT = "0x38D7EA4C68000"; // 0.001ETH
export const LORDS_PREFUND_AMOUNT = "0x0d8d726b7177a80000"; // 250LORDS

const rpc_addr = getRPCUrl();
const provider = new Provider({
  rpc: { nodeUrl: rpc_addr! },
  sequencer: { baseUrl: rpc_addr! },
});

export const useBurner = () => {
  const { refresh } = useConnectors();
  const { account: walletAccount } = useAccount();
  const [account, setAccount] = useState<Account>();
  const [isDeploying, setIsDeploying] = useState(false);
  const [isGeneratingNewKey, setIsGeneratingNewKey] = useState(false);
  const [isSettingPermissions, setIsSettingPermissions] = useState(false);
  const [isToppingUpEth, setIsToppingUpEth] = useState(false);
  const [isToppingUpLords, setIsToppingUpLords] = useState(false);
  const [isWithdrawing, setIsWithdrawing] = useState(false);
  const { gameContract, lordsContract, ethContract } = useContracts();
  const arcadeClassHash = getArcadeClassHash();

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

  const prefundAccount = async (address: string, account: AccountInterface) => {
    try {
      const transferEthTx = {
        contractAddress: ethContract?.address ?? "0x0",
        entrypoint: "transfer",
        calldata: CallData.compile([address, ETH_PREFUND_AMOUNT, "0x0"]),
      };

      const transferLordsTx = {
        contractAddress: lordsContract?.address ?? "0x0",
        entrypoint: "transfer",
        calldata: CallData.compile([address, LORDS_PREFUND_AMOUNT, "0x0"]),
      };

      const { transaction_hash } = await account.execute(
        [transferEthTx, transferLordsTx],
        undefined,
        {
          maxFee: "100000000000000", // currently setting to 0.0001ETH
        }
      );

      const result = await account.waitForTransaction(transaction_hash, {
        retryInterval: 2000,
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
      arcadeClassHash!,
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
    } = await burner.deployAccount(
      {
        classHash: arcadeClassHash!,
        constructorCalldata: constructorAACalldata,
        contractAddress: address,
        addressSalt: publicKey,
      },
      {
        maxFee: "100000000000000", // currently setting to 0.0001ETH
      }
    );

    await provider.waitForTransaction(deployTx);

    setIsSettingPermissions(true);

    const setPermissionsAndApprovalTx = await setPermissionsAndApproval(
      accountAAFinalAdress,
      walletAccount
    );

    await provider.waitForTransaction(setPermissionsAndApprovalTx);

    // save burner
    let storage = Storage.get("burners") || {};
    for (let address in storage) {
      storage[address].active = false;
    }

    storage[address] = {
      privateKey,
      publicKey,
      deployTx,
      setPermissionsAndApprovalTx,
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

  const setPermissionsAndApproval = useCallback(
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
            ethContract?.address ?? "",
            selector.getSelectorFromName("transfer"),
            "1",
          ],
        },
      ];

      // Approve 250 LORDS
      const approveLordsSpendingTx = {
        contractAddress: lordsContract?.address ?? "",
        entrypoint: "approve",
        calldata: [gameContract?.address ?? "", LORDS_PREFUND_AMOUNT, "0"],
      };
      const { transaction_hash: permissionsTx } = await walletAccount.execute(
        [...permissions, approveLordsSpendingTx],
        undefined,
        {
          maxFee: "100000000000000", // currently setting to 0.0001ETH
        }
      );

      return permissionsTx;
    },
    []
  );

  const topUpEth = async (address: string, account: AccountInterface) => {
    try {
      setIsToppingUpEth(true);
      const { transaction_hash } = await account.execute({
        contractAddress: ethContract?.address ?? "",
        entrypoint: "transfer",
        calldata: CallData.compile([address, ETH_PREFUND_AMOUNT, "0x0"]),
      });

      const result = await account.waitForTransaction(transaction_hash, {
        retryInterval: 2000,
      });

      if (!result) {
        throw new Error("Transaction did not complete successfully.");
      }

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
    lordsAmount: number,
    lordsGameAllowance: number
  ) => {
    try {
      setIsToppingUpLords(true);
      const lordsTransferTx = {
        contractAddress: lordsContract?.address ?? "",
        entrypoint: "transfer",
        calldata: CallData.compile([
          address,
          (lordsAmount * 10 ** 18).toString(),
          "0x0",
        ]),
      };
      const increasedAllowance = lordsAmount * 10 ** 18 + lordsGameAllowance;
      const lordsGameApprovalTx = {
        contractAddress: lordsContract?.address ?? "",
        entrypoint: "approve",
        calldata: CallData.compile([
          gameContract?.address ?? "",
          increasedAllowance,
          "0x0",
        ]),
      };
      const { transaction_hash } = await account.execute([
        lordsTransferTx,
        lordsGameApprovalTx,
      ]);

      const result = await account.waitForTransaction(transaction_hash, {
        retryInterval: 2000,
      });

      if (!result) {
        throw new Error("Transaction did not complete successfully.");
      }

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
        retryInterval: 2000,
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
      try {
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
      } catch (e) {
        setIsGeneratingNewKey(false);
        console.log(e);
      }
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
    topUpEth,
    topUpLords,
    withdraw,
    genNewKey,
    account,
    isDeploying,
    isSettingPermissions,
    isGeneratingNewKey,
    isToppingUpEth,
    isToppingUpLords,
    isWithdrawing,
    listConnectors,
  };
};
