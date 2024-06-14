import {
  BurnerAccount,
  useBurnerManager,
  BurnerManager,
} from "@dojoengine/create-burner";
import { createContext, ReactNode, useContext, useMemo } from "react";
import { Account, RpcProvider } from "starknet";

interface DojoContextType {
  masterAccount: Account;
  account: {
    create: typeof useBurnerManager.prototype.create;
    list: typeof useBurnerManager.prototype.list;
    get: typeof useBurnerManager.prototype.get;
    select: typeof useBurnerManager.prototype.select;
    clear: typeof useBurnerManager.prototype.clear;
    account: BurnerAccount | Account;
    isDeploying: boolean;
    copyToClipboard: typeof useBurnerManager.prototype.copyToClipboard;
    applyFromClipboard: typeof useBurnerManager.prototype.applyFromClipboard;
  };
}

export const DojoContext = createContext<DojoContextType | null>(null);

type Props = {
  children: ReactNode;
  value: {
    config: {
      masterAddress: string;
      masterPrivateKey: string;
    };
    burnerManager: BurnerManager;
    dojoProvider: RpcProvider;
  };
};

export const DojoProvider = ({ children, value }: Props) => {
  const currentValue = useContext(DojoContext);
  if (currentValue) throw new Error("DojoProvider can only be used once");

  const {
    config: { masterAddress, masterPrivateKey },
    burnerManager,
    dojoProvider,
  } = value;

  const masterAccount = useMemo(
    () => new Account(dojoProvider, masterAddress, masterPrivateKey, "1"),
    [masterAddress, masterPrivateKey, dojoProvider]
  );

  const {
    create,
    list,
    get,
    account,
    select,
    isDeploying,
    clear,
    copyToClipboard,
    applyFromClipboard,
  } = useBurnerManager({
    burnerManager,
  });

  return (
    <DojoContext.Provider
      value={{
        masterAccount,
        account: {
          create,
          list,
          get,
          select,
          clear,
          account: account ? account : masterAccount,
          isDeploying,
          copyToClipboard,
          applyFromClipboard,
        },
      }}
    >
      {children}
    </DojoContext.Provider>
  );
};
