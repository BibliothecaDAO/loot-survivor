import { Button } from "@/app/components/buttons/Button";
import Profile from "public/icons/profile.svg";
import QuestionMark from "public/icons/question-mark.svg";
import useUIStore, { Network } from "@/app/hooks/useUIStore";
import { SoundOffIcon, SoundOnIcon } from "@/app/components/icons/Icons";
import { useUiSounds, soundSelector } from "@/app/hooks/useUiSound";

const Intro = () => {
  const {
    setLoginScreen,
    setScreen,
    handleOnboarded,
    setNetwork,
    setIsMuted,
    isMuted,
  } = useUIStore();

  const { play: clickPlay } = useUiSounds(soundSelector.click);

  let network = "";

  if (process.env.NEXT_PUBLIC_NETWORK === "development") {
    network = "sepolia";
  } else {
    network = process.env.NEXT_PUBLIC_NETWORK!;
  }

  return (
    <div className="min-h-screen container flex flex-col items-center">
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
        <div className="flex flex-col sm:flex-row sm:mt-20 gap-2 sm:gap-10 px-2 sm:p-0 justify-center items-center">
          <div className="flex flex-col items-center justify-between border border-terminal-green p-2 sm:p-5 text-center gap-2 sm:gap-10 z-1 h-[250px] sm:h-[425px] 2xl:h-[500px] w-full sm:w-1/3">
            <Profile className="sm:hidden 2xl:block fill-current h-12 sm:h-32" />
            {network === "mainnet" ? (
              <p className="sm:text-xl">
                Experience the full version of Loot Survivor on Starknet{" "}
                {network?.toUpperCase()}. Earn $lords rewards, collect NFTs, and
                compete for a spot on the global leaderboard!
              </p>
            ) : (
              <p className="sm:text-xl">
                Experience a preview of Loot Survivor on Starknet{" "}
                {network?.toUpperCase()}. Earn $lords rewards, collect NFTs, and
                compete for the global leaderboard!
              </p>
            )}
            <div className="flex flex-col gap-2">
              <Button
                size={"lg"}
                onClick={() => {
                  setLoginScreen(true);
                  setNetwork(network! as Network);
                }}
                disabled={network == "sepolia" ? false : true}
              >
                Play on {network}
              </Button>
            </div>
          </div>
          <div className="flex flex-col items-center justify-between border border-terminal-green p-2 sm:p-5 text-center gap-2 sm:gap-10 z-1 h-[250px] sm:h-[425px] 2xl:h-[500px] w-full sm:w-1/3">
            <QuestionMark className="sm:hidden 2xl:block fill-current h-12 sm:h-32" />
            <p className="sm:text-xl">
              Looking for a hassle-free gaming experience? Play on Testnet,
              enjoying quick gameplay without any real funds or prizes involved.
            </p>
            <div className="flex flex-col gap-5">
              <Button
                size={"lg"}
                onClick={() => {
                  setScreen("start");
                  handleOnboarded();
                  setNetwork("katana");
                }}
              >
                Play on Testnet
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Intro;
