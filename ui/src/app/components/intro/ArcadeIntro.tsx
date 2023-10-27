import { useEffect, useState } from "react";
import { Contract } from "starknet";
import { useAccount, useConnect, useDisconnect } from "@starknet-react/core";
import Image from "next/image";
import {
  ETH_PREFUND_AMOUNT,
  LORDS_PREFUND_AMOUNT,
  useBurner,
} from "@/app/lib/burner";
import { Button } from "@/app/components/buttons/Button";
import useUIStore from "@/app/hooks/useUIStore";
import { getWalletConnectors } from "@/app/lib/connectors";
import Lords from "public/icons/lords.svg";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";
import { Call } from "@/app/types";
import ArcadeLoader from "@/app/components/animations/ArcadeLoader";

interface ArcadeIntroProps {
  ethBalance: bigint;
  lordsBalance: bigint;
  getBalances: () => void;
  gameContract: Contract;
  lordsContract: Contract;
  ethContract: Contract;
  updateConnectors: () => void;
}

export const ArcadeIntro = ({
  ethBalance,
  lordsBalance,
  getBalances,
  gameContract,
  lordsContract,
  ethContract,
  updateConnectors,
}: ArcadeIntroProps) => {
  const { account, address, connector } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const [step, setStep] = useState(1);
  const [readDisclaimer, setReadDisclaimer] = useState(false);
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  const showArcadeIntro = useUIStore((state) => state.showArcadeIntro);
  const { create, isDeploying, isSettingPermissions, listConnectors } =
    useBurner(account, gameContract, lordsContract, ethContract);
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
        calldata: [address ?? "0x0", (260 * 10 ** 18).toString(), "0"],
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
  const checkNotEnoughPrefundLords = lords < parseInt(LORDS_PREFUND_AMOUNT);
  const checkAnyETh = eth === 0;

  useEffect(() => {
    if (account && !checkNotEnoughPrefundLords && readDisclaimer) {
      setStep(4);
    } else if (account && readDisclaimer) {
      setStep(3);
    } else if (account) {
      setStep(2);
    } else {
      setStep(1);
    }
  }, [account, checkNotEnoughPrefundLords, readDisclaimer]);

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
              Your Arcade Account&apos;s key is securely stored in your browser
              and is linked to your main wallet with limited permissions. This
              provides a low-risk, superfast onchain gaming experience.
            </p>
            <p className="text-sm xl:text-xl 2xl:text-2xl">
              Please choose a Starknet Wallet below.
            </p>
            <div className="flex flex-col gap-2 w-1/2 sm:w-1/4">
              <Button onClick={() => setScreen("tutorial")}>
                I don&apos;t have a wallet
              </Button>
              {walletConnectors.map((connector, index) => (
                <Button
                  disabled={address !== undefined}
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
            </div>
          </div>
        )}
        {step == 2 && (
          <div className="flex flex-col gap-10 items-center">
            <h3 className="mt-4 uppercase">Disclaimers</h3>
            <p className="text-sm xl:text-xl 2xl:text-2xl">
              The game is still in testing and there may be things outside of
              our control that cause incomplete games after Lords have been
              inserted. We kindly advise that any problems encountered are
              reported to the discord channel within Biblithecadao.
            </p>
            <p className="text-sm xl:text-xl 2xl:text-2xl">
              The game has an idle penalty counter that will kill the adventurer
              if a move isn&apos;t made within a certain number of blocks (~
              7-10 mins). To avoid frustration please keep an eye on the idle
              penalty.
            </p>
            <Button onClick={() => setReadDisclaimer(true)}>
              I understand
            </Button>
          </div>
        )}
        {step == 3 && (
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
              <Lords className="w-24 h-24 sm:w-40 sm:h-40 fill-current" />
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
                  !checkNotEnoughPrefundLords ||
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
        {step == 4 && (
          <div className="flex flex-col gap-10 items-center h-full">
            <h3 className="mt-4 uppercase">Deploy Arcade Account</h3>
            <div className="flex flex-col items-center gap-2">
              <p className="text-sm xl:text-xl 2xl:text-2xl">
                You are about to deploy a new Arcade Account (AA)! You will be
                asked to sign 2 transactions:
              </p>
              <ul className="text-sm xl:text-xl 2xl:text-2xl list-disc w-2/3">
                <li>Pre-fund the AA with Eth and Lords</li>
                <li>
                  Set Permissions on the AA to play Loot Survivor and transfer
                  back
                </li>
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
                onClick={async () => {
                  if (checkNotEnoughPrefundEth) {
                    window.open("https://faucet.goerli.starknet.io/", "_blank");
                  } else {
                    await create(connector!);
                    connect({ connector: listConnectors()[0] });
                    updateConnectors();
                    showArcadeIntro(false);
                  }
                }}
                disabled={
                  isWrongNetwork || checkNotEnoughPrefundLords || !account
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
              className={`w-8 h-8 sm:w-12 sm:h-12 ${
                step >= 1 ? "bg-terminal-green" : "border border-terminal-green"
              }`}
            />
            <div
              className={`w-8 h-8 sm:w-12 sm:h-12  ${
                step >= 2 ? "bg-terminal-green" : "border border-terminal-green"
              }`}
            />
            <div
              className={`w-8 h-8 sm:w-12 sm:h-12  ${
                step >= 3 ? "bg-terminal-green" : "border border-terminal-green"
              }`}
            />
            <div
              className={`w-8 h-8 sm:w-12 sm:h-12  ${
                step == 4 ? "bg-terminal-green" : "border border-terminal-green"
              }`}
            />
          </div>
        </div>
        {isDeploying && (
          <ArcadeLoader isSettingPermissions={isSettingPermissions} />
        )}
      </div>
    </>
  );
};
