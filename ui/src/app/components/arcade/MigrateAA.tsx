import { ChangeEvent, useState, useEffect } from "react";
import { CallData, Contract, ec, hash } from "starknet";
import { useContract } from "@starknet-react/core";
import { padAddress, isChecksumAddress } from "@/app/lib/utils";
import { Button } from "@/app/components/buttons/Button";
import Storage from "@/app/lib/storage";
import ArcadeAccount from "@/app/abi/ArcadeAccount.json";
import { getInterface } from "@/app/api/api";

const ARCADE_ACCOUNT_ID: string = "0x4152434144455F4143434F554E545F4944";

interface MigrateAAProps {
  setMigrateAA: (migrateAA: boolean) => void;
  gameContract: Contract;
  updateConnectors: () => void;
}

const MigrateAA = ({
  setMigrateAA,
  gameContract,
  updateConnectors,
}: MigrateAAProps) => {
  const [arcadePrivateKey, setArcadePrivateKey] = useState<
    string | undefined
  >();
  const [arcadeExists, setArcadeExists] = useState<boolean>(false);
  const [arcadeAddress, setArcadeAddress] = useState<string | undefined>();
  const [arcadePublicKey, setArcadePublicKey] = useState<string | undefined>();
  const [inputMasterAccount, setInputMasterAccount] = useState<
    string | undefined
  >();
  const [realMasterAccount, setRealMasterAccount] = useState<
    string | undefined
  >();
  const [masterInterface, setMasterInterface] = useState<string | undefined>();

  const formattedArcadeAddress = padAddress(padAddress(arcadeAddress ?? ""));

  const storage = Storage.get("burners") || {};

  const handleMasterAccountChange = (
    e: ChangeEvent<HTMLInputElement | HTMLSelectElement>
  ) => {
    const { value } = e.target;
    setInputMasterAccount(value);
  };

  const handlePrivateKeyChange = (
    e: ChangeEvent<HTMLInputElement | HTMLSelectElement>
  ) => {
    const { value } = e.target;
    setArcadePrivateKey(value);
  };

  const { contract: arcadeContract } = useContract({
    address: formattedArcadeAddress,
    abi: ArcadeAccount,
  });

  const getMasterAccount = async () => {
    try {
      const masterAccount = await arcadeContract?.call("get_master_account");
      if (masterAccount) {
        setArcadeExists(true);
        setRealMasterAccount("0x" + masterAccount.toString(16));
      }
    } catch (e) {
      console.log(e);
    }
  };

  const checkInterface = async () => {
    try {
      const accountInterface: any = await getInterface(
        inputMasterAccount!,
        ARCADE_ACCOUNT_ID
      );
      if (accountInterface.error) {
        setMasterInterface("braavos");
      } else {
        setMasterInterface("argentX");
      }
    } catch (e) {
      console.log(e);
    }
  };

  const handleGetArcade = () => {
    if (isChecksumAddress(arcadePrivateKey!)) {
      const publicKey = ec.starkCurve.getStarkKey(arcadePrivateKey!);

      const constructorAACalldata = CallData.compile({
        _public_key: publicKey,
        _master_account: inputMasterAccount!,
      });

      const address = hash.calculateContractAddressFromHash(
        publicKey,
        process.env.NEXT_PUBLIC_ARCADE_ACCOUNT_CLASS_HASH!,
        constructorAACalldata,
        0
      );

      setArcadeAddress(address);
      setArcadePublicKey(publicKey);
    }
  };

  const importBurner = () => {
    storage[formattedArcadeAddress!] = {
      privateKey: arcadePrivateKey,
      publicKey: arcadePublicKey,
      masterAccount: inputMasterAccount,
      masterAccountProvider: masterInterface,
      gameContract: gameContract?.address,
      active: true,
    };

    Storage.set("burners", storage);
  };

  const arcadeAccountExists = () => {
    if (storage) {
      return Object.keys(storage).includes(formattedArcadeAddress ?? "");
    } else {
      return false;
    }
  };

  const isMasterAccount =
    padAddress(inputMasterAccount!) === padAddress(realMasterAccount ?? "");

  useEffect(() => {
    if (arcadePrivateKey && inputMasterAccount) {
      handleGetArcade();
    }
  }, [arcadePrivateKey]);

  useEffect(() => {
    if (arcadeAddress) {
      getMasterAccount();
    }
  }, [arcadeAddress]);

  useEffect(() => {
    if (inputMasterAccount) {
      checkInterface();
    }
  }, [inputMasterAccount]);

  return (
    <div className="flex flex-col items-center gap-5 h-3/4 w-full overflow-scroll">
      <p className="text-2xl uppercase">Import Arcade Account</p>
      <p className="text-lg">
        Please enter the master account address and private key of the Arcade
        Account you would like to import to this client.
      </p>
      <input
        type="text"
        name="address"
        onChange={handleMasterAccountChange}
        className="p-1 m-2 bg-terminal-black border border-terminal-green animate-pulse transform w-1/2 2xl:h-16 2xl:text-4xl placeholder-terminal-green"
        placeholder="Enter Master Account"
        maxLength={66}
      />
      <input
        type="text"
        name="address"
        onChange={handlePrivateKeyChange}
        className="p-1 m-2 bg-terminal-black border border-terminal-green animate-pulse transform w-1/2 2xl:h-16 2xl:text-4xl placeholder-terminal-green"
        placeholder="Enter Private Key"
        maxLength={66}
      />
      <Button
        disabled={
          !isChecksumAddress(arcadePrivateKey!) ||
          !arcadeExists ||
          arcadeAccountExists()
        }
        onClick={() => {
          if (isMasterAccount) {
            importBurner();
            updateConnectors();
            setMigrateAA(false);
          }
        }}
        className="w-1/4"
      >
        {!arcadeExists
          ? "Arcade Doesn't Exist"
          : arcadeAccountExists()
          ? "Arcade Already Stored"
          : "Import Arcade"}
      </Button>
    </div>
  );
};

export default MigrateAA;
