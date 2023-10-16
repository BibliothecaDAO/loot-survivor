import { useRef, useState } from "react";
import { useBalance, useAccount, useConnectors } from "@starknet-react/core";
import { useContracts } from "@/app/hooks/useContracts";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import useUIStore from "@/app/hooks/useUIStore";
import { useUiSounds } from "@/app/hooks/useUiSound";
import { soundSelector } from "@/app/hooks/useUiSound";
import Logo from "public/icons/logo.svg";
import Lords from "public/icons/lords.svg";
import { PenaltyCountDown } from "@/app/components/CountDown";
import { Button } from "@/app/components/buttons/Button";
import { formatNumber, displayAddress } from "@/app/lib/utils";
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

export interface HeaderProps {
  multicall: (...args: any[]) => any;
  mintLords: (...args: any[]) => any;
  lordsBalance: bigint;
}

export default function Header({
  multicall,
  mintLords,
  lordsBalance,
}: HeaderProps) {
  const { account, address } = useAccount();
  const { disconnect } = useConnectors();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const setAdventurer = useAdventurerStore((state) => state.setAdventurer);
  const data = useQueriesStore((state) => state.data);
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

  const { play: clickPlay } = useUiSounds(soundSelector.click);

  const displayCartButtonRef = useRef<HTMLButtonElement>(null);
  const displayHistoryButtonRef = useRef<HTMLButtonElement>(null);

  const [showLordsMint, setShowLordsMint] = useState(false);

  return (
    <div className="flex flex-row justify-between px-1  ">
      <div className="flex flex-row items-center gap-2 sm:gap-5">
        <Logo className="fill-current w-24 md:w-32 xl:w-40 2xl:w-64" />
      </div>
      <div className="flex flex-row items-center self-end sm:gap-1 space-x-1 self-center">
        {adventurer?.id && (
          <PenaltyCountDown
            lastDiscoveryTime={
              data.latestDiscoveriesQuery?.discoveries[0]?.timestamp
            }
            lastBattleTime={data.lastBattleQuery?.battles[0]?.timestamp}
            dataLoading={isLoading.global}
          />
        )}
        <Button
          size={"xs"}
          variant={"outline"}
          className="hidden sm:block self-center xl:px-5"
          disabled={true}
        >
          Play For Real
        </Button>
        <Button
          size={"xs"}
          variant={"outline"}
          className="self-center xl:px-5 hover:bg-terminal-green"
          onClick={mintLords}
          onMouseEnter={() => setShowLordsMint(true)}
          onMouseLeave={() => setShowLordsMint(false)}
        >
          <span className="flex flex-row items-center justify-between w-full">
            {!showLordsMint ? (
              <>
                <Lords className="self-center sm:w-5 sm:h-5  h-3 w-3 fill-current mr-1" />
                <p>
                  {formatNumber(parseInt(lordsBalance.toString()) / 10 ** 18)}
                </p>
              </>
            ) : (
              <p className="text-black">Mint Lords</p>
            )}
          </span>
        </Button>
        <Button
          size={"xs"}
          variant={"outline"}
          onClick={() => showArcadeDialog(!arcadeDialog)}
          disabled={isWrongNetwork}
          className="xl:px-5"
        >
          <ArcadeIcon className="sm:w-5 sm:h-5  h-3 w-3 justify-center fill-current mr-2" />
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
          <Button
            variant={"outline"}
            size={"xs"}
            ref={displayCartButtonRef}
            onClick={() => {
              setDisplayCart(!displayCart);
              clickPlay();
            }}
            className="xl:px-5"
          >
            <CartIcon className="sm:w-5 sm:h-5 h-3 w-3 fill-current" />
          </Button>
        )}
        {displayCart && (
          <TransactionCart
            buttonRef={displayCartButtonRef}
            multicall={multicall}
          />
        )}
        <div className="flex items-center sm:hidden">
          <Button
            size={"xs"}
            variant={"outline"}
            onClick={() => {
              setScreen("settings");
              clickPlay();
            }}
            className="xl:px-5"
          >
            <SettingsIcon className="fill-current h-3 w-3" />
          </Button>
        </div>
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
      </div>
    </div>
  );
}
