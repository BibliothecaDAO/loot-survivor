import { useState } from "react";
import { SoundOffIcon, SoundOnIcon } from "@/app/components/icons/Icons";
import { Button } from "@/app/components/buttons/Button";
import useUIStore from "@/app/hooks/useUIStore";
import { useUiSounds, soundSelector } from "@/app/hooks/useUiSound";
import TokenLoader from "@/app/components/animations/TokenLoader";
import Intro from "@/app/components/onboarding/Intro";
import Login from "@/app/components/onboarding/Login";
import InfoBox from "@/app/components/onboarding/InfoBox";

export type Section = "connect" | "eth" | "lords" | "arcade";

interface OnboardingProps {
  ethBalance: bigint;
  lordsBalance: bigint;
  costToPlay: bigint;
  mintLords: (lordsAmount: number) => Promise<void>;
  getBalances: () => Promise<void>;
}

const Onboarding = ({
  ethBalance,
  lordsBalance,
  costToPlay,
  mintLords,
  getBalances,
}: OnboardingProps) => {
  const isMuted = useUIStore((state) => state.isMuted);
  const setIsMuted = useUIStore((state) => state.setIsMuted);

  const { play: clickPlay } = useUiSounds(soundSelector.click);

  const [section, setSection] = useState<Section | undefined>();

  const [mintingLords, setMintingLords] = useState(false);

  const setScreen = useUIStore((state) => state.setScreen);

  const eth = Number(ethBalance);
  const lords = Number(lordsBalance);
  const lordsGameCost = Number(costToPlay);

  const { loginScreen } = useUIStore();

  return (
    <div className="min-h-screen container flex flex-col items-center">
      {mintingLords && <TokenLoader isToppingUpLords={mintingLords} />}
      {section && (
        <InfoBox
          section={section}
          setSection={setSection}
          lordsGameCost={lordsGameCost}
        />
      )}
      <Button
        variant={"outline"}
        onClick={() => {
          setIsMuted(!isMuted);
          clickPlay();
        }}
        className="fixed top-1 left-1 sm:top-20 sm:left-20 xl:px-5"
      >
        {isMuted ? (
          <SoundOffIcon className="w-10 h-10 justify-center fill-current" />
        ) : (
          <SoundOnIcon className="w-10 h-10 justify-center fill-current" />
        )}
      </Button>
      <div className="flex flex-col items-center gap-5 py-20 sm:p-0">
        <h1 className="m-0 uppercase text-4xl sm:text-6xl text-center">
          Welcome to Loot Survivor
        </h1>
        {!loginScreen ? (
          <Intro />
        ) : (
          <Login
            eth={eth}
            lords={lords}
            lordsGameCost={lordsGameCost}
            setMintingLords={setMintingLords}
            mintLords={mintLords}
            setScreen={setScreen}
            setSection={setSection}
            getBalances={getBalances}
          />
        )}
      </div>
    </div>
  );
};

export default Onboarding;
