import { useEffect, useState } from "react";
import { Contract } from "starknet";
import { useAccount, useConnect } from "@starknet-react/core";
import Image from "next/image";
import {
  ETH_PREFUND_AMOUNT,
  LORDS_PREFUND_AMOUNT,
  useBurner,
} from "@/app/lib/burner";
import { Button } from "@/app/components/buttons/Button";
import useUIStore from "@/app/hooks/useUIStore";
import PixelatedImage from "@/app/components/animations/PixelatedImage";
import { getWalletConnectors } from "@/app/lib/connectors";
import Lords from "public/icons/lords.svg";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";
import { Call } from "@/app/types";

interface ArcadeIntroProps {
  ethBalance: bigint;
  lordsBalance: bigint;
  getBalances: () => void;
  gameContract: Contract;
  lordsContract: Contract;
  ethContract: Contract;
}

export const ArcadeIntro = ({
  ethBalance,
  lordsBalance,
  getBalances,
  gameContract,
  lordsContract,
  ethContract,
}: ArcadeIntroProps) => {
  const { account, address } = useAccount();
  const { connect, connectors } = useConnect();
  const [step, setStep] = useState(1);
  const [loadingMessage, setLoadingMessage] = useState<string | null>(null);
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  const { create, isDeploying, isSettingPermissions } = useBurner(
    account,
    gameContract,
    lordsContract,
    ethContract
  );
  const walletConnectors = getWalletConnectors(connectors);
  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const handleSubmitCalls = useTransactionCartStore(
    (state) => state.handleSubmitCalls
  );
  const setScreen = useUIStore((state) => state.setScreen);
  const lords = Number(lordsBalance);
  const eth = Number(ethBalance);
  const [isMintingLords, setIsMintingLords] = useState(false);

  const mintLords = async () => {
    try {
      setIsMintingLords(true);
      // Mint 250 LORDS
      const mintLords: Call = {
        contractAddress: lordsContract?.address ?? "",
        entrypoint: "mint",
        calldata: [address ?? "0x0", (250 * 10 ** 18).toString(), "0"],
      };
      addToCalls(mintLords);
      const tx = await handleSubmitCalls(account!, [...calls, mintLords]);
      const result = await account?.waitForTransaction(tx?.transaction_hash, {
        retryInterval: 2000,
      });

      if (!result) {
        throw new Error("Lords Mint did not complete successfully.");
      }

      setIsMintingLords(false);
      getBalances();
    } catch (e) {
      setIsMintingLords(false);
      console.log(e);
    }
  };

  const checkNotEnoughPrefundEth = eth < parseInt(ETH_PREFUND_AMOUNT);
  const checkAnyETh = eth === 0;

  useEffect(() => {
    if (!checkNotEnoughPrefundEth) {
      setStep(3);
    } else if (account) {
      setStep(2);
    } else {
      setStep(1);
    }
  }, [account, checkNotEnoughPrefundEth]);

  useEffect(() => {
    const timer = setInterval(() => {
      setLoadingMessage((prev) =>
        prev === "Please Wait" || !prev
          ? isSettingPermissions
            ? "Setting Permissions"
            : "Deploying Arcade Account"
          : "Please Wait"
      );
    }, 5000);

    return () => {
      clearInterval(timer); // Cleanup timer on component unmount
    };
  }, []);

  console.log(lordsBalance);

  return (
    <>
      <div className="fixed inset-0 opacity-80 bg-terminal-black z-40" />
      <div className="fixed flex flex-col justify-between text-center sm:top-1/8 sm:left-1/8 sm:left-1/4 sm:w-3/4 sm:w-1/2 h-3/4 border-4 bg-terminal-black z-50 border-terminal-green p-4 overflow-y-auto">
        {step == 1 && (
          <div className="flex flex-col gap-5 items-center">
            <h3 className="mt-4 uppercase">Create Arcade Account</h3>
            <p className="m-2 text-sm xl:text-xl 2xl:text-2xl">
              Welcome to Arcade Accounts! Follow three steps now to enjoy
              signature-free speed runs in Loot Survivor.
            </p>
            <p className="text-sm xl:text-xl 2xl:text-2xl">
              Your Arcade Account's key is securely stored in your browser and
              is linked to your main wallet with limited permissions. This
              provides a low-risk, superfast onchain gaming experience.
            </p>
            <p className="text-sm xl:text-xl 2xl:text-2xl">
              Please choose a Starknet Wallet below.
            </p>
            <div className="flex flex-col gap-2 w-1/4">
              <Button onClick={() => setScreen("tutorial")}>
                I don&apos;t have a wallet
              </Button>
              {walletConnectors.map((connector, index) => (
                <Button
                  disabled={address !== undefined}
                  onClick={() => connect({ connector })}
                  key={index}
                >
                  {connector.id === "braavos" || connector.id === "argentX"
                    ? `Connect ${connector.id}`
                    : "Login With Email"}
                </Button>
              ))}
            </div>
          </div>
        )}
        {step == 2 && (
          <div className="flex flex-col gap-10 items-center">
            <h3 className="mt-4 uppercase">Mint Lords</h3>
            <div className="flex flex-col gap-2">
              <p className="m-2 text-sm xl:text-xl 2xl:text-2xl">
                In order to play Loot Survivor you must insert 25 Lords.
              </p>
              <p className="text-sm xl:text-xl 2xl:text-2xl">
                Since you are on Goerli, you can mint and fund your Arcade
                Account with 250 Lords below to get started!
              </p>
            </div>
            <div className="flex flex-col gap-10 items-center justify-center w-full">
              <Lords className="w-40 h-40 fill-current" />
              <Button
                onClick={() =>
                  checkAnyETh
                    ? window.open(
                        "https://faucet.goerli.starknet.io/",
                        "_blank"
                      )
                    : mintLords()
                }
                disabled={
                  isWrongNetwork ||
                  isMintingLords ||
                  lords >= parseInt(LORDS_PREFUND_AMOUNT) ||
                  !account
                }
                className="flex flex-row w-1/4"
              >
                {isMintingLords ? (
                  <p className="loading-ellipsis">Minting Lords</p>
                ) : checkAnyETh ? (
                  "GET GOERLI ETH"
                ) : lordsBalance ? (
                  "Mint 250 Lords"
                ) : (
                  <p className="loading-ellipsis">Getting Balance</p>
                )}
              </Button>
            </div>
          </div>
        )}
        {step == 3 && (
          <div className="flex flex-col gap-10 items-center h-full">
            <h3 className="mt-4 uppercase">Deploy Arcade Account</h3>
            <div className="flex flex-col items-center gap-2">
              <p className="text-sm xl:text-xl 2xl:text-2xl">
                You are about to deploy a new Arcade Account! You will be asked
                to sign 2 transactions:
              </p>
              <ul className="text-sm xl:text-xl 2xl:text-2xl list-disc w-2/3">
                <li>Pre-fund the AA with Eth and Lords</li>
                <li>Set Permissions on the AA to play LS and transfer back</li>
              </ul>
              <p className="text-sm xl:text-xl 2xl:text-2xl">
                Transactions may take some time, please be patient. Avoid
                refreshing as it could lead to loss of funds.
              </p>
            </div>
            <div className="flex flex-col items-center justify-between h-1/2 w-full">
              <div className="relative w-1/4 h-full">
                <Image
                  src={"/scenes/intro/arcade-account.png"}
                  alt="Arcade Account"
                  fill={true}
                />
              </div>
              <Button
                onClick={() =>
                  checkNotEnoughPrefundEth
                    ? window.open(
                        "https://faucet.goerli.starknet.io/",
                        "_blank"
                      )
                    : create()
                }
                disabled={
                  isWrongNetwork ||
                  lords < parseInt(LORDS_PREFUND_AMOUNT) ||
                  !account
                }
                className="w-1/4 h-1/4"
              >
                {checkNotEnoughPrefundEth ? "GET GOERLI ETH" : "CREATE"}
              </Button>
            </div>
          </div>
        )}
        <div className="flex items-center justify-center w-full h-1/5">
          <div className="flex flex-row justify-between items-center w-1/2 h-full">
            <div
              className={`w-12 h-12 ${
                step >= 1 ? "bg-terminal-green" : "border border-terminal-green"
              }`}
            />
            <div
              className={`w-12 h-12 ${
                step >= 2 ? "bg-terminal-green" : "border border-terminal-green"
              }`}
            />
            <div
              className={`w-12 h-12 ${
                step == 3 ? "bg-terminal-green" : "border border-terminal-green"
              }`}
            />
          </div>
        </div>
        {isDeploying && (
          <div className="fixed flex flex-row inset-0 bg-black z-50 m-2 w-full h-full">
            <div className="w-1/2 h-full">
              <PixelatedImage
                src={"/scenes/intro/arcade-account.png"}
                pixelSize={5}
                pulsate={true}
              />
            </div>
            <h3 className="text-lg sm:text-3xl loading-ellipsis flex items-center justify-start w-1/2">
              {loadingMessage}
            </h3>
          </div>
        )}
      </div>
    </>
  );
};
