import { Button } from "@/app/components/buttons/Button";
import Profile from "public/icons/profile.svg";
import QuestionMark from "public/icons/question-mark.svg";
import useUIStore from "@/app/hooks/useUIStore";
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
      <Button
        className="fixed top-2 right-2 sm:top-20 sm:right-20"
        onClick={() => {
          setScreen("start");
          handleOnboarded();
        }}
      >
        Continue As Guest
      </Button>
      <div className="flex flex-col items-center gap-5 py-20 sm:p-0">
        <h1 className="m-0 uppercase text-4xl sm:text-6xl text-center">
          Welcome to Loot Survivor
        </h1>
        <div className="flex flex-col sm:flex-row sm:mt-20 gap-2 sm:gap-10 px-2 sm:p-0 justify-center items-center">
          <div className="flex flex-col items-center justify-between border border-terminal-green p-2 sm:p-5 text-center gap-2 sm:gap-10 z-1 h-[250px] sm:h-[425px] 2xl:h-[500px] w-full sm:w-1/3">
            <h4 className="m-0 uppercase text-3xl">Login</h4>
            <Profile className="sm:hidden 2xl:block fill-current h-12 sm:h-32" />
            <p className="sm:text-xl">
              Dive into the full immersion of Loot Survivor by logging in now!
              Join the Mainnet for a chance to win real funds and exciting
              prizes.
            </p>
            <div className="flex flex-col gap-2">
              <Button
                size={"lg"}
                onClick={() => {
                  setLoginScreen(true);
                  setNetwork("sepolia");
                }}
              >
                Login to Sepolia
              </Button>
            </div>
          </div>
          <div className="flex flex-col items-center justify-between border border-terminal-green p-2 sm:p-5 text-center gap-2 sm:gap-10 z-1 h-[250px] sm:h-[425px] 2xl:h-[500px] w-full sm:w-1/3">
            <h4 className="m-0 uppercase text-3xl">Play As Guest</h4>
            <QuestionMark className="sm:hidden 2xl:block fill-current h-12 sm:h-32" />
            <p className="sm:text-xl">
              Looking for a hassle-free gaming experience? Play as a Guest,
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
                Continue as Guest
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Intro;
