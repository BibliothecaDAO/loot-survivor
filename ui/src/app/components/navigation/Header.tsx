import { useRef, useState, useEffect } from "react";
import { Contract } from "starknet";
import { useAccount, useDisconnect, useConnect } from "@starknet-react/core";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import useUIStore from "@/app/hooks/useUIStore";
import { useUiSounds } from "@/app/hooks/useUiSound";
import { soundSelector } from "@/app/hooks/useUiSound";
import Logo from "public/icons/logo.svg";
import Lords from "public/icons/lords.svg";
import { PenaltyCountDown } from "@/app/components/CountDown";
import { Button } from "@/app/components/buttons/Button";
import { formatNumber, displayAddress, indexAddress } from "@/app/lib/utils";
import {
  ArcadeIcon,
  SoundOffIcon,
  SoundOnIcon,
  CartIcon,
  SettingsIcon,
  GithubIcon,
} from "@/app/components/icons/Icons";
import TransactionCart from "@/app/components/navigation/TransactionCart";
import TransactionHistory from "@/app/components/navigation/TransactionHistory";
import { NullAdventurer } from "@/app/types";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";
import { getApibaraStatus } from "@/app/api/api";
import ApibaraStatus from "@/app/components/navigation/ApibaraStatus";
import TokenLoader from "@/app/components/animations/TokenLoader";
import { checkArcadeConnector } from "@/app/lib/connectors";
import { SkullIcon } from "@/app/components/icons/Icons";

export interface HeaderProps {
  multicall: (
    loadingMessage: string[],
    notification: string[]
  ) => Promise<void>;
  mintLords: (lordsAmount: number) => Promise<void>;
  suicide: () => Promise<void>;
  lordsBalance: bigint;
  gameContract: Contract;
  costToPlay: bigint;
}

export default function Header({
  multicall,
  mintLords,
  suicide,
  lordsBalance,
  gameContract,
  costToPlay,
}: HeaderProps) {
  const [mintingLords, setMintingLords] = useState(false);
  const { account } = useAccount();
  const { connector } = useConnect();
  const { disconnect } = useDisconnect();
  const [apibaraStatus, setApibaraStatus] = useState();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const resetData = useQueriesStore((state) => state.resetData);
  const isLoading = useQueriesStore((state) => state.isLoading);

  const setDisconnected = useUIStore((state) => state.setDisconnected);
  const arcadeDialog = useUIStore((state) => state.arcadeDialog);
  const showArcadeDialog = useUIStore((state) => state.showArcadeDialog);
  const isWrongNetwork = useUIStore((state) => state.isWrongNetwork);
  const isMuted = useUIStore((state) => state.isMuted);
  const setIsMuted = useUIStore((state) => state.setIsMuted);
  const displayCart = useUIStore((state) => state.displayCart);
  const setDisplayCart = useUIStore((state) => state.setDisplayCart);
  const displayHistory = useUIStore((state) => state.displayHistory);
  const setDisplayHistory = useUIStore((state) => state.setDisplayHistory);
  const setScreen = useUIStore((state) => state.setScreen);
  const updateDeathPenalty = useUIStore((state) => state.updateDeathPenalty);
  const setUpdateDeathPenalty = useUIStore(
    (state) => state.setUpdateDeathPenalty
  );
  const startPenalty = useUIStore((state) => state.startPenalty);
  const setStartPenalty = useUIStore((state) => state.setStartPenalty);

  const calls = useTransactionCartStore((state) => state.calls);
  const txInCart = calls.length > 0;

  const { play: clickPlay } = useUiSounds(soundSelector.click);

  const displayCartButtonRef = useRef<HTMLButtonElement>(null);
  const displayHistoryButtonRef = useRef<HTMLButtonElement>(null);

  const [showLordsBuy, setShowLordsBuy] = useState(false);

  const lordsGameCost = Number(costToPlay);

  const handleApibaraStatus = async () => {
    const data = await getApibaraStatus();
    setApibaraStatus(data.status.indicator);
  };

  const checkArcade = checkArcadeConnector(connector);

  useEffect(() => {
    handleApibaraStatus();
  }, []);

  useEffect(() => {
    if (startPenalty) {
      setStartPenalty(false);
    }
  }, [adventurer]);

  const isOnMainnet = process.env.NEXT_PUBLIC_NETWORK === "mainnet";

  return (
    <div className="flex flex-row justify-between px-1 h-10 ">
      <div className="flex flex-row items-center gap-2 sm:gap-5">
        <Logo className="fill-current w-24 md:w-32 xl:w-40 2xl:w-64" />
      </div>
      <div className="flex flex-row items-center self-end sm:gap-1 self-center">
        {adventurer?.id && (
          <Button onClick={() => suicide()} variant={"outline"}>
            <div className="flex flex-row items-center gap-2">
              <SkullIcon className="w-3 fill-current" />
              <p>Suicide</p>
            </div>
          </Button>
        )}
        <ApibaraStatus status={apibaraStatus} />
        {adventurer?.id && (
          <PenaltyCountDown
            dataLoading={isLoading.global}
            startCountdown={startPenalty || (adventurer?.level ?? 0) > 1}
            updateDeathPenalty={updateDeathPenalty}
            setUpdateDeathPenalty={setUpdateDeathPenalty}
          />
        )}
        <Button
          size={"xs"}
          variant={"outline"}
          className="hidden sm:block self-center xl:px-5"
          onClick={() =>
            process.env.NEXT_PUBLIC_NETWORK === "mainnet"
              ? window.open("https://goerli-survivor.realms.world/", "_blank")
              : window.open("https://survivor.realms.world/", "_blank")
          }
        >
          {isOnMainnet ? "Play on Testnet" : "Play on Mainnet"}
        </Button>
        <Button
          size={"xs"}
          variant={"outline"}
          className="self-center xl:px-5 hover:bg-terminal-green"
          onClick={async () => {
            if (isOnMainnet) {
              const avnuLords = `https://app.avnu.fi/en?tokenFrom=${indexAddress(
                process.env.NEXT_PUBLIC_ETH_ADDRESS ?? ""
              )}&tokenTo=${indexAddress(
                process.env.NEXT_PUBLIC_LORDS_ADDRESS ?? ""
              )}&amount=0.001`;
              window.open(avnuLords, "_blank");
            } else {
              setMintingLords(true);
              await mintLords(lordsGameCost * 25);
              setMintingLords(false);
            }
          }}
          onMouseEnter={() => setShowLordsBuy(true)}
          onMouseLeave={() => setShowLordsBuy(false)}
        >
          <span className="flex flex-row items-center justify-between w-full">
            {!showLordsBuy ? (
              <>
                <Lords className="self-center sm:w-5 sm:h-5  h-3 w-3 fill-current mr-1" />
                <p>
                  {formatNumber(parseInt(lordsBalance.toString()) / 10 ** 18)}
                </p>
              </>
            ) : (
              <p className="text-black">
                {isOnMainnet ? "Buy Lords" : "Mint Lords"}
              </p>
            )}
          </span>
        </Button>
        <span className="sm:hidden w-5 h-5">
          <Button
            size={"fill"}
            variant={checkArcade ? "outline" : "default"}
            onClick={() => showArcadeDialog(!arcadeDialog)}
            disabled={isWrongNetwork || !account}
            className={`xl:px-5 ${checkArcade ? "" : "animate-pulse"}`}
          >
            <ArcadeIcon className="w-5 h-5 justify-center fill-current sm:mr-2" />
            <span className="hidden sm:block">arcade account</span>
          </Button>
        </span>
        <Button
          size={"xs"}
          variant={checkArcade ? "outline" : "default"}
          onClick={() => showArcadeDialog(!arcadeDialog)}
          disabled={isWrongNetwork || !account}
          className={`hidden sm:flex xl:px-5 ${
            checkArcade ? "" : "animate-pulse"
          }`}
        >
          <ArcadeIcon className="w-5 h-5 justify-center fill-current mr-2" />
          <span className="hidden sm:block">arcade account</span>
        </Button>
        <Button
          size={"xs"}
          variant={"outline"}
          onClick={() => {
            setIsMuted(!isMuted);
            clickPlay();
          }}
          className="hidden sm:block xl:px-5"
        >
          {isMuted ? (
            <SoundOffIcon className="sm:w-5 sm:h-5 h-3 w-3 justify-center fill-current" />
          ) : (
            <SoundOnIcon className="sm:w-5 sm:h-5 h-3 w-3 justify-center fill-current" />
          )}
        </Button>
        {account && (
          <>
            <span className="sm:hidden w-5 h-5 mx-2">
              <Button
                variant={txInCart ? "default" : "outline"}
                size={"fill"}
                ref={displayCartButtonRef}
                onClick={() => {
                  setDisplayCart(!displayCart);
                  clickPlay();
                }}
                className={`xl:px-5 ${txInCart ? "animate-pulse" : ""}`}
              >
                <CartIcon className="w-5 h-5 fill-current" />
              </Button>
            </span>
            <Button
              variant={txInCart ? "default" : "outline"}
              size={"xs"}
              ref={displayCartButtonRef}
              onClick={() => {
                setDisplayCart(!displayCart);
                clickPlay();
              }}
              className={`hidden sm:block xl:px-5 ${
                txInCart ? "animate-pulse" : ""
              }`}
            >
              <CartIcon className="w-5 h-5 fill-current" />
            </Button>
          </>
        )}
        {displayCart && (
          <TransactionCart
            buttonRef={displayCartButtonRef}
            multicall={multicall}
            gameContract={gameContract}
          />
        )}
        <span className="sm:hidden flex flex-row gap-2 items-center">
          <div className="relative">
            <Button
              variant={"outline"}
              size={"sm"}
              onClick={() => {
                disconnect();
                resetData();
                setAdventurer(NullAdventurer);
                setDisconnected(true);
              }}
              className="xl:px-5 p-0"
            >
              {account ? displayAddress(account.address) : "Connect"}
            </Button>
            {checkArcade && (
              <div className="absolute top-0 right-0">
                <ArcadeIcon className="fill-current w-2 sm:w-4" />
              </div>
            )}
          </div>
          <Button
            size={"fill"}
            variant={"outline"}
            onClick={() => {
              setScreen("settings");
              clickPlay();
            }}
            className="xl:px-5"
          >
            <SettingsIcon className="fill-current h-5 w-5" />
          </Button>
        </span>
        <div className="hidden sm:block sm:flex sm:flex-row sm:items-center sm:gap-1">
          {account && (
            <>
              <Button
                variant={"outline"}
                size={"xs"}
                ref={displayHistoryButtonRef}
                onClick={() => {
                  setDisplayHistory(!displayHistory);
                }}
                className="xl:px-5"
              >
                {displayHistory ? "Hide Ledger" : "Show Ledger"}
              </Button>
            </>
          )}
          <div className="relative">
            <Button
              variant={"outline"}
              size={"sm"}
              onClick={() => {
                disconnect();
                resetData();
                setAdventurer(NullAdventurer);
                setDisconnected(true);
              }}
              className="xl:px-5"
            >
              {account ? displayAddress(account.address) : "Connect"}
            </Button>
            {checkArcade && (
              <div className="absolute top-0 right-0">
                <ArcadeIcon className="fill-current w-4" />
              </div>
            )}
          </div>

          <Button
            variant={"outline"}
            size={"sm"}
            href="https://github.com/BibliothecaDAO/loot-survivor"
            className="xl:px-5"
          >
            <GithubIcon className="w-6 fill-current" />
          </Button>
        </div>
        {account && displayHistory && (
          <TransactionHistory buttonRef={displayHistoryButtonRef} />
        )}
        {mintingLords && <TokenLoader isToppingUpLords={mintingLords} />}
      </div>
    </div>
  );
}
