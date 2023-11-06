import { useEffect, useState } from "react";
import { MdClose } from "react-icons/md";
import { Contract } from "starknet";
import { useAccount, useConnect, useDisconnect } from "@starknet-react/core";
import {
  ETH_PREFUND_AMOUNT,
  LORDS_PREFUND_AMOUNT,
  useBurner,
} from "@/app/lib/burner";
import { Button } from "@/app/components/buttons/Button";
import useUIStore from "@/app/hooks/useUIStore";
import { getWalletConnectors } from "@/app/lib/connectors";
import ArcadeLoader from "@/app/components/animations/ArcadeLoader";
import Lords from "public/icons/lords.svg";
import QuantityButtons from "../buttons/QuantityButtons";
import { indexAddress } from "@/app/lib/utils";

interface ArcadeIntroProps {
  ethBalance: bigint;
  lordsBalance: bigint;
  gameContract: Contract;
  lordsContract: Contract;
  ethContract: Contract;
  updateConnectors: () => void;
  mintLords: () => Promise<void>;
}

export const ArcadeIntro = ({
  ethBalance,
  lordsBalance,
  gameContract,
  lordsContract,
  ethContract,
  updateConnectors,
  mintLords,
}: ArcadeIntroProps) => {
  const { account, address, connector } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const [step, setStep] = useState(1);
  const [fullDeployment, setFullDeployment] = useState(false);
  const [gamesPrefundAmount, setGamesPrefundAmount] = useState(1);
  const [readDisclaimer, setReadDisclaimer] = useState(false);
  const [buyLordsLater, setBuyLordsLater] = useState(false);
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  const showArcadeIntro = useUIStore((state) => state.showArcadeIntro);
  const setClosedArcadeIntro = useUIStore(
    (state) => state.setClosedArcadeIntro
  );
  const {
    create,
    isPrefunding,
    isDeploying,
    isSettingPermissions,
    listConnectors,
    showLoader,
  } = useBurner({
    walletAccount: account,
    gameContract,
    lordsContract,
    ethContract,
  });
  const walletConnectors = getWalletConnectors(connectors);
  const setScreen = useUIStore((state) => state.setScreen);
  const lords = Number(lordsBalance);
  const eth = Number(ethBalance);

  const checkNotEnoughPrefundEth = eth < parseInt(ETH_PREFUND_AMOUNT);
  const checkNotEnoughPrefundLords = lords < parseInt(LORDS_PREFUND_AMOUNT);

  useEffect(() => {
    if (
      account &&
      (!checkNotEnoughPrefundLords || buyLordsLater) &&
      readDisclaimer
    ) {
      setStep(4);
    } else if (account && readDisclaimer) {
      setStep(3);
    } else if (account) {
      setStep(2);
    } else {
      setStep(1);
    }
  }, [account, checkNotEnoughPrefundLords, readDisclaimer, buyLordsLater]);

  const formattedLords = lords / 10 ** 18;

  const maxGames = Math.min(Math.floor(formattedLords / 25), 100);

  const onMainnet = process.env.NEXT_PUBLIC_NETWORK === "mainnet";

  return (
    <>
      <div className="fixed inset-0 opacity-80 bg-terminal-black z-40" />
      <div className="fixed flex flex-col justify-between text-center sm:top-1/8 sm:left-1/8 sm:left-1/4 sm:w-3/4 sm:w-1/2 h-3/4 border-4 bg-terminal-black z-50 border-terminal-green p-4 overflow-y-auto">
        <button
          className="absolute top-2 right-2 cursor-pointer text-red-500"
          onClick={() => {
            showArcadeIntro(false);
            setClosedArcadeIntro(true);
          }}
        >
          <MdClose size={50} />
        </button>
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
            <h3 className="mt-4 uppercase">
              {onMainnet ? "Buy Lords" : "Mint Lords"}
            </h3>
            <div className="flex flex-col gap-2">
              <p className="m-2 text-sm xl:text-xl 2xl:text-2xl">
                In order to play Loot Survivor you must insert at least 25
                Lords.
              </p>
              <p className="text-sm xl:text-xl 2xl:text-2xl">
                {onMainnet
                  ? "If you do not have any LORDS please select the button below to buy from a DEX."
                  : "Mint 250 (10 games worth) with the button below"}
              </p>
              <p className="text-sm xl:text-xl 2xl:text-2xl">
                Please ensure that your Account is deployed!
              </p>
            </div>
            <div className="flex flex-col gap-10 items-center justify-center w-full">
              <Lords className="w-24 h-24 sm:w-40 sm:h-40 fill-current" />
              <div className="flex flex-col gap-2 w-1/4">
                <Button
                  onClick={async () => {
                    if (onMainnet) {
                      const avnuLords = `https://app.avnu.fi/en?tokenFrom=${indexAddress(
                        process.env.NEXT_PUBLIC_ETH_ADDRESS ?? ""
                      )}&tokenTo=${indexAddress(
                        process.env.NEXT_PUBLIC_LORDS_ADDRESS ?? ""
                      )}&amount=0.001`;
                      window.open(avnuLords, "_blank");
                    } else {
                      await mintLords();
                    }
                  }}
                  disabled={
                    isWrongNetwork || !checkNotEnoughPrefundLords || !account
                  }
                  className="flex flex-row"
                >
                  {lordsBalance || lords == 0 ? (
                    onMainnet ? (
                      "Buy Lords"
                    ) : (
                      "Mint Lords"
                    )
                  ) : (
                    <p className="loading-ellipsis">Getting Balance</p>
                  )}
                </Button>
                <Button onClick={() => setBuyLordsLater(true)}>
                  I have a Golden Token
                </Button>
              </div>
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
                <li>Pre-fund the AA with ETH and LORDS</li>
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
              {checkNotEnoughPrefundEth ? (
                <Button
                  onClick={() =>
                    onMainnet
                      ? window.open("https://starkgate.starknet.io//", "_blank")
                      : window.open(
                          "https://faucet.goerli.starknet.io/",
                          "_blank"
                        )
                  }
                  className="w-1/4"
                  disabled={!ethBalance}
                >
                  {ethBalance ? (
                    "GET ETH"
                  ) : (
                    <p className="loading-ellipsis">Getting Balance</p>
                  )}
                </Button>
              ) : (
                <div className="flex flex-col gap-5 items-center w-3/4">
                  <p className="text-sm xl:text-xl 2xl:text-2xl">
                    How many games would you like to fund?
                  </p>
                  <div className="flex flex-row gap-5 w-1/2">
                    <div className="w-1/2">
                      <QuantityButtons
                        amount={gamesPrefundAmount}
                        min={0}
                        max={maxGames}
                        setAmount={(value) => {
                          setGamesPrefundAmount(value);
                        }}
                      />
                    </div>
                    <Button
                      onClick={async () => {
                        setFullDeployment(true);
                        await create(
                          connector!,
                          gamesPrefundAmount * (25 * 10 ** 18)
                        );
                        disconnect();
                        connect({ connector: listConnectors()[0] });
                        updateConnectors();
                        showArcadeIntro(false);
                        setFullDeployment(false);
                      }}
                      disabled={
                        isWrongNetwork ||
                        checkNotEnoughPrefundLords ||
                        !account ||
                        gamesPrefundAmount === 0 ||
                        gamesPrefundAmount > maxGames
                      }
                      className="w-1/2 h-1/4"
                    >
                      Create Account
                    </Button>
                  </div>
                  <Button
                    onClick={async () => {
                      setFullDeployment(true);
                      await create(connector!, 0);
                      disconnect();
                      connect({ connector: listConnectors()[0] });
                      updateConnectors();
                      showArcadeIntro(false);
                      setFullDeployment(false);
                    }}
                  >
                    Create without Lords
                  </Button>
                </div>
              )}
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
        <ArcadeLoader
          isPrefunding={isPrefunding}
          isDeploying={isDeploying}
          isSettingPermissions={isSettingPermissions}
          fullDeployment={fullDeployment}
          showLoader={showLoader}
        />
      </div>
    </>
  );
};
