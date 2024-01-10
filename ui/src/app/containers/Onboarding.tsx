import { useState, useEffect } from "react";
import Image from "next/image";
import { MdClose } from "react-icons/md";
import { CompleteIcon, InfoIcon } from "@/app/components/icons/Icons";
import { Button } from "@/app/components/buttons/Button";
import { getWalletConnectors } from "@/app/lib/connectors";
import { useAccount, useConnect, useDisconnect } from "@starknet-react/core";
import useUIStore from "@/app/hooks/useUIStore";
import { ETH_PREFUND_AMOUNT } from "../lib/burner";
import Eth from "public/icons/eth-2.svg";
import Lords from "public/icons/lords.svg";
import Arcade from "public/icons/arcade.svg";
import { indexAddress, formatCurrency } from "../lib/utils";

type Section = "connect" | "eth" | "lords" | "arcade";

const openInNewTab = (url: string) => {
  const newWindow = window.open(url, "_blank", "noopener,noreferrer");
  if (newWindow) newWindow.opener = null;
};

const sectionContent = (section: Section) => {
  switch (section) {
    case "connect":
      return (
        <div className="flex flex-col gap-10 items-center text-center text-lg">
          <p>
            Starknet is an non-EVM Ethereum L2 that supports seperate wallets.
          </p>
          <p>Please install a wallet from the list below:</p>
          <div className="flex flex-row my-2">
            <Button
              onClick={() => openInNewTab("https://braavos.app/")}
              className="m-2"
            >
              Get Braavos
            </Button>
            <Button
              onClick={() => openInNewTab("https://www.argent.xyz/argent-x/")}
              className="m-2"
            >
              Get ArgentX
            </Button>
          </div>
        </div>
      );
    case "eth":
      return (
        <div className="flex flex-col gap-10 items-center text-center text-lg">
          <p>
            ETH is required to pay gas for transactions on the Starknet network.
          </p>
          <p>This step will complete once you have at least 0.001 ETH.</p>
        </div>
      );
    case "lords":
      return (
        <div className="flex flex-col items-center justify-between text-center text-lg">
          <p>LORDS is the native token of LOOT SURVIVOR & Realms.World.</p>
          <p>
            You will be required to enter LORDS at the price calculated from
            demand of the game.
          </p>
          <p>This step will complete once you have at least 27.225 LORDS.</p>
        </div>
      );
    case "arcade":
      return (
        <div className="flex flex-col p-5 gap-10 items-center justify-between text-center text-xl">
          <p>
            In order to get signerless txs you must create an Arcade Account.
          </p>
          <p>
            An Arcade Account is an acount which keys are stored in the browser.
            The game can then sign txs without the need for the users wallet to
            popup, saving time.
          </p>
          <p>
            In order to create the Arcade Account you will be asked to sign 2
            transactions:
          </p>
          <ul className="list-disc text-left">
            <li>Prefund the Account with LORDS & ETH</li>
            <li>
              Set permissions to allow the Arcade to play LOOT SURVIVOR and
              withdraw to your main wallet
            </li>
          </ul>
        </div>
      );
    default:
      return "Default content for unknown section";
  }
};

interface InfoBoxProps {
  section: Section | undefined;
  setSection: (section: Section | undefined) => void;
}

const InfoBox = ({ section, setSection }: InfoBoxProps) => {
  return (
    <div className="fixed w-1/2 h-1/2 top-1/4 bg-terminal-black border border-terminal-green flex flex-col items-center p-10 z-30">
      <button
        className="absolute top-2 right-2 cursor-pointer text-terminal-green"
        onClick={() => {
          setSection(undefined);
        }}
      >
        <MdClose size={50} />
      </button>
      <span className="w-10">
        <InfoIcon />
      </span>
      {sectionContent(section!)}
    </div>
  );
};

interface OnboardingProps {
  ethBalance: bigint;
  lordsBalance: bigint;
  costToPlay: bigint;
  mintLords: () => Promise<void>;
}

const Onboarding = ({
  ethBalance,
  lordsBalance,
  costToPlay,
  mintLords,
}: OnboardingProps) => {
  const { account, address, connector } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const walletConnectors = getWalletConnectors(connectors);

  const [section, setSection] = useState<Section | undefined>();

  const [step, setStep] = useState(1);

  const setScreen = useUIStore((state) => state.setScreen);

  const eth = Number(ethBalance);
  const lords = Number(lordsBalance);
  const lordsGameCost = Number(costToPlay);
  const [prefundGames, setPrefundGames] = useState(1);

  const checkEnoughEth = eth >= parseInt(ETH_PREFUND_AMOUNT);
  const checkEnoughLords = lords > lordsGameCost;

  const network = "mainnet";
  const onMainnet = network === "mainnet";

  useEffect(() => {
    if (account && checkEnoughEth && checkEnoughLords) {
      setStep(4);
    } else if (account && checkEnoughEth) {
      setStep(3);
    } else if (account) {
      setStep(2);
    } else {
      setStep(1);
    }
  }, [account, checkEnoughEth, checkEnoughLords]);

  return (
    <div className="min-h-screen container flex flex-col items-center">
      {section && <InfoBox section={section} setSection={setSection} />}
      <div className="flex flex-col items-center gap-5">
        <h1 className="m-0 uppercase">Welcome to Loot Survivor</h1>
        <p className="text-lg">
          A fully on-chain arcade game on Starknet. Follow the steps below to
          get setup smoothly:
        </p>
        <div className="flex flex-row h-5/6 gap-5">
          <div className="flex flex-col items-center w-1/4">
            <h2>1</h2>
            <div className="relative z-1">
              {step !== 1 && (
                <>
                  <div className="absolute top-0 left-0 right-0 bottom-0 h-full w-full bg-black opacity-50 z-10" />
                  {step > 1 && (
                    <div className="absolute w-1/2 top-1/4 right-1/4 z-20">
                      <CompleteIcon />
                    </div>
                  )}
                </>
              )}
              <div className="flex flex-col items-center justify-between border border-terminal-green p-5 text-center gap-10 z-1 sm:h-[500px]">
                <h4 className="m-0 uppercase">Connect Starknet Wallet</h4>
                <p>
                  In order to play LOOT SURVIVOR you are required to connect a
                  Starknet wallet.
                </p>
                <span
                  className="flex items-center justify-center border border-terminal-green w-1/2 p-2 cursor-pointer"
                  onClick={() => setSection("connect")}
                >
                  <span className="flex flex-row items-center gap-2">
                    <p className="uppercase">No Wallet</p>
                    <span className="w-8">
                      <InfoIcon />
                    </span>
                  </span>
                </span>
                <div className="flex flex-col">
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
                        : connector.id === "argentWebWallet"
                        ? "Login With Email"
                        : "Login with Argent Mobile"}
                    </Button>
                  ))}
                </div>
              </div>
            </div>
          </div>
          <div className="flex flex-col items-center w-1/4">
            <h2>2</h2>
            <div className="relative z-1">
              {step !== 2 && (
                <>
                  <div className="absolute top-0 left-0 right-0 bottom-0 h-full w-full bg-black opacity-50 z-10" />
                  {step > 2 ? (
                    <div className="absolute w-1/2 top-1/4 right-1/4 z-20">
                      <CompleteIcon />
                    </div>
                  ) : (
                    <div className="absolute w-1/2 top-1/4 right-1/4 z-20 text-center text-2xl uppercase">
                      Complete {step}
                    </div>
                  )}
                </>
              )}
              <div className="flex flex-col items-center justify-between border border-terminal-green p-5 text-center gap-5 sm:h-[500px]">
                <h4 className="m-0 uppercase">Get ETH</h4>
                <Eth className="h-5 sm:h-16" />
                <p>
                  We are on <span className="uppercase">{network}</span> so you
                  are required to bridge from Ethereum or directly purchase
                  through one of the wallets.
                </p>
                <span
                  className="flex items-center justify-center border border-terminal-green w-1/2 p-2 cursor-pointer"
                  onClick={() => setSection("eth")}
                >
                  <span className="flex flex-row items-center gap-2">
                    <p className="uppercase">More Info</p>
                    <span className="w-8">
                      <InfoIcon />
                    </span>
                  </span>
                </span>
                <span className="w-3/4 h-10">
                  <Button
                    size={"fill"}
                    onClick={() =>
                      onMainnet
                        ? window.open(
                            "https://starkgate.starknet.io//",
                            "_blank"
                          )
                        : window.open(
                            "https://faucet.goerli.starknet.io/",
                            "_blank"
                          )
                    }
                  >
                    Bridge Eth
                  </Button>
                </span>
              </div>
            </div>
          </div>
          <div className="flex flex-col items-center w-1/4">
            <h2>3</h2>
            <div className="relative z-1">
              {step !== 3 && (
                <>
                  <div className="absolute top-0 left-0 right-0 bottom-0 h-full w-full bg-black opacity-50 z-10" />
                  {step > 3 ? (
                    <div className="absolute w-1/2 top-1/4 right-1/4 z-20">
                      <CompleteIcon />
                    </div>
                  ) : (
                    <div className="absolute w-1/2 top-1/4 right-1/4 z-20 text-center text-2xl uppercase">
                      Complete {step}
                    </div>
                  )}
                </>
              )}
              <div className="flex flex-col items-center justify-between border border-terminal-green p-5 text-center gap-5 sm:h-[500px]">
                <h4 className="m-0 uppercase">Get Lords</h4>
                <Lords className="fill-current h-5 sm:h-16" />
                <p>
                  We are on <span className="uppercase">{network}</span> so you
                  are required to purchase LORDS from an exchange.
                </p>
                <span
                  className="flex items-center justify-center border border-terminal-green w-1/2 p-2 cursor-pointer"
                  onClick={() => setSection("lords")}
                >
                  <span className="flex flex-row items-center gap-2">
                    <p className="uppercase">More Info</p>
                    <span className="w-8">
                      <InfoIcon />
                    </span>
                  </span>
                </span>
                <span className="w-3/4 h-10">
                  <Button
                    size={"fill"}
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
                  >
                    Buy Lords
                  </Button>
                </span>
              </div>
            </div>
          </div>
          <div className="flex flex-col items-center w-1/4">
            <h2>4</h2>
            <div className="relative z-1">
              {step !== 4 && (
                <>
                  <div className="absolute top-0 left-0 right-0 bottom-0 h-full w-full bg-black opacity-50 z-10" />
                  <div className="absolute w-1/2 top-1/4 right-1/4 z-20 text-center text-2xl uppercase">
                    Complete {step}
                  </div>
                </>
              )}
              <div className="flex flex-col items-center justify-between border border-terminal-green p-5 text-center gap-5 sm:h-[500px]">
                <h4 className="m-0 uppercase">Signerless Txs</h4>
                <Arcade className="fill-current h-5 sm:h-16" />
                <p>
                  Arcade Accounts offer signature free gameplay rather than
                  needing to sign each tx.
                </p>
                <span
                  className="flex items-center justify-center border border-terminal-green w-1/2 p-2 cursor-pointer"
                  onClick={() => setSection("arcade")}
                >
                  <span className="flex flex-row items-center gap-2">
                    <p className="uppercase">More Info</p>
                    <span className="w-8">
                      <InfoIcon />
                    </span>
                  </span>
                </span>
                <span className="flex flex-col gap-2">
                  <p className="uppercase text-xl">Games</p>
                  <span className="flex flex-row gap-2 text-xl">
                    <span
                      className={`border border-terminal-green h-10 w-10 flex items-center justify-center cursor-pointer ${
                        prefundGames == 1 &&
                        "bg-terminal-green text-terminal-black"
                      }`}
                      onClick={() => setPrefundGames(1)}
                    >
                      1
                    </span>
                    <span
                      className={`border border-terminal-green h-10 w-10 flex items-center justify-center cursor-pointer ${
                        prefundGames == 5 &&
                        "bg-terminal-green text-terminal-black"
                      }`}
                      onClick={() => setPrefundGames(5)}
                    >
                      5
                    </span>
                    <span
                      className={`border border-terminal-green h-10 w-10 flex items-center justify-center cursor-pointer ${
                        prefundGames == 10 &&
                        "bg-terminal-green text-terminal-black"
                      }`}
                      onClick={() => setPrefundGames(10)}
                    >
                      10
                    </span>
                    <span
                      className={`border border-terminal-green h-10 w-10 flex items-center justify-center cursor-pointer ${
                        prefundGames == 25 &&
                        "bg-terminal-green text-terminal-black"
                      }`}
                      onClick={() => setPrefundGames(25)}
                    >
                      25
                    </span>
                  </span>
                </span>
                <div className="flex flex-col w-full items-center">
                  <span className="flex flex-row gap-2">
                    <Eth className="w-2" />
                    0.001 ETH Required
                  </span>
                  <span className="flex flex-row gap-2">
                    <Lords className="fill-current w-2" />
                    {formatCurrency(lordsGameCost * prefundGames)} LORDS
                    Required
                  </span>
                  <span className="w-3/4 h-10">
                    <Button size={"fill"}>Deploy</Button>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="flex flex-row items-center gap-10">
          <p className="uppercase text-xl">
            We recommend you read the docs before using funds
          </p>
          <span className="w-20 h-10">
            <Button size={"fill"}>Docs</Button>
          </span>
        </div>
      </div>
    </div>
  );
};

export default Onboarding;
