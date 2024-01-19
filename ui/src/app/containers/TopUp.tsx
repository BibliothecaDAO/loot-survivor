import { useState, useEffect, ChangeEvent } from "react";
import { MdClose } from "react-icons/md";
import {
  CompleteIcon,
  InfoIcon,
  SoundOffIcon,
  SoundOnIcon,
} from "@/app/components/icons/Icons";
import { Button } from "@/app/components/buttons/Button";
import { getArcadeConnectors, getWalletConnectors } from "@/app/lib/connectors";
import {
  useAccount,
  useConnect,
  useDisconnect,
  Connector,
  ConnectVariables,
} from "@starknet-react/core";
import {
  Account,
  AccountInterface,
  Contract,
  DeclareTransactionReceiptResponse,
  RevertedTransactionReceiptResponse,
  RejectedTransactionReceiptResponse,
} from "starknet";
import { ETH_PREFUND_AMOUNT } from "@/app/lib/burner";
import Eth from "public/icons/eth-2.svg";
import Arcade from "public/icons/arcade.svg";
import { formatCurrency, displayAddress } from "@/app/lib/utils";
import { useBurner } from "@/app/lib/burner";
import ArcadeLoader from "@/app/components/animations/ArcadeLoader";
import useUIStore, { ScreenPage } from "@/app/hooks/useUIStore";
import { useUiSounds, soundSelector } from "@/app/hooks/useUiSound";
import { ETH_INCREMENT } from "@/app/lib/constants";
import Storage from "@/app/lib/storage";
import { BurnerStorage } from "@/app/types";

type Section = "connect" | "eth" | "lords" | "arcade";

const openInNewTab = (url: string) => {
  const newWindow = window.open(url, "_blank", "noopener,noreferrer");
  if (newWindow) newWindow.opener = null;
};

interface SectionContentProps {
  section: Section;
  setSection: (section: Section) => void;
  step: number;
  address: string | undefined;
  walletConnectors: Connector[];
  disconnect: () => void;
  connect: (args?: ConnectVariables | undefined) => void;
  eth: number;
  lords: number;
  lordsGameCost: number;
  onMainnet: boolean;
  network: string;
  mintLords: (lordsAmount: number) => Promise<void>;
  prefundGames: number;
  setPrefundGames: (games: number) => void;
  setFullDeployment: (value: boolean) => void;
  connector: Connector | undefined;
  create: (
    connector: Connector,
    lordsAmount: number
  ) => Promise<Account | undefined>;
  listConnectors: () => any[];
  updateConnectors: () => void;
  handleOnboarded: () => void;
  setScreen: (value: ScreenPage) => void;
  masterConnected: boolean;
  topUpEth: (
    address: string,
    account: AccountInterface,
    ethAmount?: number | undefined
  ) => Promise<
    | DeclareTransactionReceiptResponse
    | RevertedTransactionReceiptResponse
    | RejectedTransactionReceiptResponse
    | undefined
  >;
  isToppingUpEth: boolean;
  topUpAccount: string;
  setTopUpAccount: (account: string) => void;
  walletAccount: AccountInterface;
  arcadeConnector: Connector;
  showTopUpDialog: (value: boolean) => void;
}

const SectionContent = ({
  section,
  setSection,
  step,
  address,
  walletConnectors,
  disconnect,
  connect,
  eth,
  lords,
  lordsGameCost,
  onMainnet,
  network,
  mintLords,
  prefundGames,
  setPrefundGames,
  setFullDeployment,
  connector,
  create,
  listConnectors,
  updateConnectors,
  handleOnboarded,
  setScreen,
  masterConnected,
  topUpEth,
  isToppingUpEth,
  topUpAccount,
  setTopUpAccount,
  walletAccount,
  arcadeConnector,
  showTopUpDialog,
}: SectionContentProps) => {
  const [inputValue, setInputValue] = useState(0);

  const handleChange = (
    e: ChangeEvent<HTMLInputElement | HTMLSelectElement>
  ) => {
    const { value } = e.target;
    setInputValue(parseInt(value));
  };

  const handleIncrement = () => {
    const newInputValue =
      inputValue + (onMainnet ? ETH_INCREMENT : ETH_INCREMENT / 10);
    if (newInputValue >= 0) {
      setInputValue(newInputValue);
    }
  };

  const handleDecrement = () => {
    const newInputValue =
      inputValue - (onMainnet ? ETH_INCREMENT : ETH_INCREMENT / 10);
    if (newInputValue >= 0) {
      setInputValue(newInputValue);
    }
  };

  const notEnoughDefaultBalance = eth < (onMainnet ? 0.01 : 0.001) * 10 ** 18;
  const notEnoughCustomBalance = eth < inputValue * 10 ** 18;

  switch (section) {
    case "connect":
      return (
        <div className="relative z-1">
          {step !== 1 && (
            <>
              <div className="absolute top-0 left-0 right-0 bottom-0 h-full w-full bg-black opacity-50 z-10" />
              {step > 1 && (
                <div className="absolute flex flex-col w-1/2 top-1/4 right-1/4 z-20 items-center text-xl text-center">
                  <p>Connected {displayAddress(address!)}</p>
                  <CompleteIcon />
                </div>
              )}
            </>
          )}
          <div className="flex flex-col items-center justify-between sm:border sm:border-terminal-green p-5 text-center gap-10 z-1 h-[500px] sm:h-[425px] 2xl:h-[500px]">
            <h4 className="m-0 uppercase text-3xl">Connect Starknet Wallet</h4>
            <p className="sm:hidden 2xl:block text-xl sm:text-base">
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
            <div className="hidden sm:flex flex-col">
              {walletConnectors.map((connector, index) => (
                <Button
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
            <div className="sm:hidden flex flex-col gap-2">
              {walletConnectors.map((connector, index) => (
                <Button
                  size={"lg"}
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
      );
    case "eth":
      return (
        <div className="relative z-1">
          {step !== 2 && (
            <>
              <div className="absolute top-0 left-0 right-0 bottom-0 h-full w-full bg-black opacity-50 z-10" />
              {step > 2 ? (
                <div className="absolute flex flex-col w-1/2 top-1/4 right-1/4 z-20 items-center">
                  <span className="flex flex-row text-center text-xl">
                    You have {formatCurrency(eth)} ETH
                  </span>
                  <CompleteIcon />
                </div>
              ) : (
                <div className="absolute w-1/2 top-1/4 right-1/4 z-20 text-center text-2xl uppercase">
                  Complete {step}
                </div>
              )}
            </>
          )}
          <div className="flex flex-col items-center justify-between sm:border sm:border-terminal-green p-5 text-center gap-5 h-[500px] sm:h-[425px] 2xl:h-[500px]">
            <h4 className="m-0 uppercase text-3xl">Get ETH</h4>
            <Eth className="sm:hidden 2xl:block h-16" />
            {onMainnet ? (
              <p className="text-xl sm:text-base">
                We are on <span className="uppercase">{network}</span> so you
                are required to bridge from Ethereum or directly purchase
                through one of the wallets.
              </p>
            ) : (
              <p className="text-xl sm:text-base">
                We are on <span className="uppercase">{network}</span> so you
                are able to get some test ETH from the faucet.
              </p>
            )}
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
                    ? window.open("https://starkgate.starknet.io//", "_blank")
                    : window.open(
                        "https://faucet.goerli.starknet.io/",
                        "_blank"
                      )
                }
              >
                {onMainnet ? "Bridge Eth" : "Get ETH"}
              </Button>
            </span>
          </div>
        </div>
      );
    case "arcade":
      return (
        <div className="relative z-1">
          {step !== 3 && (
            <>
              <div className="absolute top-0 left-0 right-0 bottom-0 h-full w-full bg-black opacity-50 z-10" />
              <div className="absolute w-1/2 top-1/4 right-1/4 z-20 text-center text-2xl uppercase">
                Complete {step}
              </div>
            </>
          )}
          <div className="flex flex-col items-center justify-between sm:border sm:border-terminal-green p-5 text-center sm:gap-2 2xl:gap-5 h-[500px] sm:h-[425px] 2xl:h-[500px]">
            <h4 className="m-0 uppercase text-3xl">Top Up</h4>
            <Arcade className="sm:hidden 2xl:block fill-current h-16" />
            <p>Top up the Arcade Account with the acquired ETH.</p>
            <Button
              disabled={!masterConnected || isToppingUpEth}
              onClick={async () => {
                if (!notEnoughDefaultBalance) {
                  await topUpEth(topUpAccount, walletAccount!);
                  setTopUpAccount("");
                  disconnect();
                  connect({ connector: arcadeConnector! });
                  showTopUpDialog(false);
                } else {
                  onMainnet
                    ? window.open("https://starkgate.starknet.io//", "_blank")
                    : window.open(
                        "https://faucet.goerli.starknet.io/",
                        "_blank"
                      );
                }
              }}
            >
              {masterConnected
                ? notEnoughDefaultBalance
                  ? "Get ETH"
                  : onMainnet
                  ? "Top Up 0.01ETH"
                  : "Top Up 0.001ETH"
                : "Connect Master"}
            </Button>
            <p className="m-2 text-sm xl:text-xl 2xl:text-2xl">
              Top Up Custom Amount
            </p>
            <div className="flex flex-row items-center justify-center gap-1">
              <input
                type="number"
                min={0}
                value={inputValue}
                onChange={handleChange}
                className="p-1 w-12 bg-terminal-black border border-terminal-green"
                onWheel={(e) => e.preventDefault()} // Disable mouse wheel for the input
                disabled={!masterConnected}
              />
              <div className="flex flex-col">
                <Button
                  size="xxxs"
                  className="text-black"
                  onClick={handleIncrement}
                  disabled={!masterConnected}
                >
                  +
                </Button>
                <Button
                  size="xxxs"
                  className="text-black"
                  onClick={handleDecrement}
                  disabled={!masterConnected}
                >
                  -
                </Button>
              </div>
            </div>
            <div className="flex flex-col w-full items-center">
              <span className="flex flex-row gap-2">
                <Eth className="w-2" />
                {onMainnet ? "0.001 ETH Required" : "0.0001 ETH Required"}
              </span>
              <span className="w-3/4 h-10">
                <Button
                  size={"fill"}
                  disabled={
                    !masterConnected || isToppingUpEth || inputValue === 0
                  }
                  onClick={async () => {
                    if (!notEnoughCustomBalance) {
                      await topUpEth(topUpAccount, walletAccount!, inputValue);
                      setTopUpAccount("");
                      disconnect();
                      connect({ connector: arcadeConnector! });
                      showTopUpDialog(false);
                    } else {
                      onMainnet
                        ? window.open(
                            "https://starkgate.starknet.io//",
                            "_blank"
                          )
                        : window.open(
                            "https://faucet.goerli.starknet.io/",
                            "_blank"
                          );
                    }
                  }}
                >
                  {masterConnected
                    ? notEnoughCustomBalance
                      ? "Get ETH"
                      : "Top Up Custom"
                    : "Connect Master"}
                </Button>
              </span>
            </div>
          </div>
        </div>
      );
    default:
      return <></>;
  }
};

const sectionInfo = (section: Section, lordsGameCost: number) => {
  switch (section) {
    case "connect":
      return (
        <div className="flex flex-col gap-10 items-center text-center text-xl">
          <p>
            Starknet is an non-EVM Ethereum L2 that supports seperate wallets.
          </p>
          <p>Please install a wallet from the list below:</p>
          <div className="flex flex-row my-2">
            <Button
              size={"lg"}
              onClick={() => openInNewTab("https://braavos.app/")}
              className="m-2"
            >
              Get Braavos
            </Button>
            <Button
              size={"lg"}
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
  lordsGameCost: number;
}

const InfoBox = ({ section, setSection, lordsGameCost }: InfoBoxProps) => {
  return (
    <div className="fixed w-full sm:w-1/2 h-1/2 top-1/4 bg-terminal-black border border-terminal-green flex flex-col items-center p-10 z-30">
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
      {sectionInfo(section!, lordsGameCost)}
    </div>
  );
};

interface TopUpProps {
  ethBalance: bigint;
  lordsBalance: bigint;
  costToPlay: bigint;
  mintLords: (lordsAmount: number) => Promise<void>;
  gameContract: Contract;
  lordsContract: Contract;
  ethContract: Contract;
  updateConnectors: () => void;
  showTopUpDialog: (value: boolean) => void;
}

const TopUp = ({
  ethBalance,
  lordsBalance,
  costToPlay,
  mintLords,
  gameContract,
  lordsContract,
  ethContract,
  updateConnectors,
  showTopUpDialog,
}: TopUpProps) => {
  const { account, address, connector } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const walletConnectors = getWalletConnectors(connectors);
  const arcadeConnectors = getArcadeConnectors(connectors);

  const isMuted = useUIStore((state) => state.isMuted);
  const setIsMuted = useUIStore((state) => state.setIsMuted);
  const topUpAccount = useUIStore((state) => state.topUpAccount);
  const setTopUpAccount = useUIStore((state) => state.setTopUpAccount);

  const { play: clickPlay } = useUiSounds(soundSelector.click);

  const {
    create,
    isPrefunding,
    isDeploying,
    isSettingPermissions,
    listConnectors,
    showLoader,
    topUpEth,
    isToppingUpEth,
  } = useBurner({
    walletAccount: account,
    gameContract,
    lordsContract,
    ethContract,
  });

  const [section, setSection] = useState<Section | undefined>();
  const [fullDeployment, setFullDeployment] = useState(false);

  const [step, setStep] = useState(1);

  const handleOnboarded = useUIStore((state) => state.handleOnboarded);
  const setScreen = useUIStore((state) => state.setScreen);

  const eth = Number(ethBalance);
  const lords = Number(lordsBalance);
  const lordsGameCost = Number(costToPlay);
  const [prefundGames, setPrefundGames] = useState(1);

  const checkEnoughEth = eth >= parseInt(ETH_PREFUND_AMOUNT);
  const checkEnoughLords = lords > lordsGameCost;

  const network = process.env.NEXT_PUBLIC_NETWORK;
  const onMainnet = process.env.NEXT_PUBLIC_NETWORK === "mainnet";

  let storage: BurnerStorage = Storage.get("burners") || {};
  const masterConnected = address === storage[topUpAccount]?.masterAccount;

  const arcadeConnector = arcadeConnectors.find(
    (connector) => connector.name === topUpAccount
  );

  useEffect(() => {
    if (account && checkEnoughEth) {
      setStep(3);
    } else if (masterConnected) {
      setStep(2);
    } else {
      setStep(1);
    }
  }, [account, checkEnoughEth, checkEnoughLords]);

  return (
    <div className="min-h-screen container flex flex-col items-center">
      <ArcadeLoader
        isPrefunding={isPrefunding}
        isDeploying={isDeploying}
        isSettingPermissions={isSettingPermissions}
        fullDeployment={fullDeployment}
        showLoader={showLoader}
      />
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
      <Button
        className="fixed top-2 right-2 sm:top-20 sm:right-20"
        onClick={() => {
          setScreen("start");
          showTopUpDialog(false);
        }}
      >
        Take me back
      </Button>
      <div className="flex flex-col items-center gap-5 py-20 sm:p-0">
        <h1 className="m-0 uppercase text-6xl text-center">Top Up Required</h1>
        <p className="hidden sm:block text-lg">
          You have run out of ETH for gas on your Arcade Account, follow the
          steps below to top up:
        </p>
        <div className="hidden sm:flex flex-row justify-center h-5/6 gap-5">
          <div className="flex flex-col items-center w-1/4">
            <h2 className="m-0">1</h2>
            <SectionContent
              section={"connect"}
              setSection={setSection}
              step={step}
              address={address}
              walletConnectors={walletConnectors}
              disconnect={disconnect}
              connect={connect}
              eth={eth}
              lords={lords}
              lordsGameCost={lordsGameCost}
              onMainnet={onMainnet}
              network={network!}
              mintLords={mintLords}
              prefundGames={prefundGames}
              setPrefundGames={setPrefundGames}
              setFullDeployment={setFullDeployment}
              connector={connector}
              create={create}
              listConnectors={listConnectors}
              updateConnectors={updateConnectors}
              handleOnboarded={handleOnboarded}
              setScreen={setScreen}
              masterConnected={masterConnected}
              topUpEth={topUpEth}
              isToppingUpEth={isToppingUpEth}
              topUpAccount={topUpAccount}
              setTopUpAccount={setTopUpAccount}
              walletAccount={account!}
              arcadeConnector={arcadeConnector!}
              showTopUpDialog={showTopUpDialog}
            />
          </div>
          <div className="flex flex-col items-center w-1/4">
            <h2 className="m-0">2</h2>
            <SectionContent
              section={"eth"}
              setSection={setSection}
              step={step}
              address={address}
              walletConnectors={walletConnectors}
              disconnect={disconnect}
              connect={connect}
              eth={eth}
              lords={lords}
              lordsGameCost={lordsGameCost}
              onMainnet={onMainnet}
              network={network!}
              mintLords={mintLords}
              prefundGames={prefundGames}
              setPrefundGames={setPrefundGames}
              setFullDeployment={setFullDeployment}
              connector={connector}
              create={create}
              listConnectors={listConnectors}
              updateConnectors={updateConnectors}
              handleOnboarded={handleOnboarded}
              setScreen={setScreen}
              masterConnected={masterConnected}
              topUpEth={topUpEth}
              isToppingUpEth={isToppingUpEth}
              topUpAccount={topUpAccount}
              setTopUpAccount={setTopUpAccount}
              walletAccount={account!}
              arcadeConnector={arcadeConnector!}
              showTopUpDialog={showTopUpDialog}
            />
          </div>
          <div className="flex flex-col items-center w-1/4">
            <h2 className="m-0">3</h2>
            <SectionContent
              section={"arcade"}
              setSection={setSection}
              step={step}
              address={address}
              walletConnectors={walletConnectors}
              disconnect={disconnect}
              connect={connect}
              eth={eth}
              lords={lords}
              lordsGameCost={lordsGameCost}
              onMainnet={onMainnet}
              network={network!}
              mintLords={mintLords}
              prefundGames={prefundGames}
              setPrefundGames={setPrefundGames}
              setFullDeployment={setFullDeployment}
              connector={connector}
              create={create}
              listConnectors={listConnectors}
              updateConnectors={updateConnectors}
              handleOnboarded={handleOnboarded}
              setScreen={setScreen}
              masterConnected={masterConnected}
              topUpEth={topUpEth}
              isToppingUpEth={isToppingUpEth}
              topUpAccount={topUpAccount}
              setTopUpAccount={setTopUpAccount}
              walletAccount={account!}
              arcadeConnector={arcadeConnector!}
              showTopUpDialog={showTopUpDialog}
            />
          </div>
        </div>
        <div className="sm:hidden">
          {step == 1 && (
            <SectionContent
              section={"connect"}
              setSection={setSection}
              step={step}
              address={address}
              walletConnectors={walletConnectors}
              disconnect={disconnect}
              connect={connect}
              eth={eth}
              lords={lords}
              lordsGameCost={lordsGameCost}
              onMainnet={onMainnet}
              network={network!}
              mintLords={mintLords}
              prefundGames={prefundGames}
              setPrefundGames={setPrefundGames}
              setFullDeployment={setFullDeployment}
              connector={connector}
              create={create}
              listConnectors={listConnectors}
              updateConnectors={updateConnectors}
              handleOnboarded={handleOnboarded}
              setScreen={setScreen}
              masterConnected={masterConnected}
              topUpEth={topUpEth}
              isToppingUpEth={isToppingUpEth}
              topUpAccount={topUpAccount}
              setTopUpAccount={setTopUpAccount}
              walletAccount={account!}
              arcadeConnector={arcadeConnector!}
              showTopUpDialog={showTopUpDialog}
            />
          )}
          {step == 2 && (
            <SectionContent
              section={"eth"}
              setSection={setSection}
              step={step}
              address={address}
              walletConnectors={walletConnectors}
              disconnect={disconnect}
              connect={connect}
              eth={eth}
              lords={lords}
              lordsGameCost={lordsGameCost}
              onMainnet={onMainnet}
              network={network!}
              mintLords={mintLords}
              prefundGames={prefundGames}
              setPrefundGames={setPrefundGames}
              setFullDeployment={setFullDeployment}
              connector={connector}
              create={create}
              listConnectors={listConnectors}
              updateConnectors={updateConnectors}
              handleOnboarded={handleOnboarded}
              setScreen={setScreen}
              masterConnected={masterConnected}
              topUpEth={topUpEth}
              isToppingUpEth={isToppingUpEth}
              topUpAccount={topUpAccount}
              setTopUpAccount={setTopUpAccount}
              walletAccount={account!}
              arcadeConnector={arcadeConnector!}
              showTopUpDialog={showTopUpDialog}
            />
          )}
          {step == 3 && (
            <SectionContent
              section={"arcade"}
              setSection={setSection}
              step={step}
              address={address}
              walletConnectors={walletConnectors}
              disconnect={disconnect}
              connect={connect}
              eth={eth}
              lords={lords}
              lordsGameCost={lordsGameCost}
              onMainnet={onMainnet}
              network={network!}
              mintLords={mintLords}
              prefundGames={prefundGames}
              setPrefundGames={setPrefundGames}
              setFullDeployment={setFullDeployment}
              connector={connector}
              create={create}
              listConnectors={listConnectors}
              updateConnectors={updateConnectors}
              handleOnboarded={handleOnboarded}
              setScreen={setScreen}
              masterConnected={masterConnected}
              topUpEth={topUpEth}
              isToppingUpEth={isToppingUpEth}
              topUpAccount={topUpAccount}
              setTopUpAccount={setTopUpAccount}
              walletAccount={account!}
              arcadeConnector={arcadeConnector!}
              showTopUpDialog={showTopUpDialog}
            />
          )}
        </div>
        <div className="sm:hidden flex items-center justify-center w-full h-1/5">
          <div className="flex flex-row justify-between items-center w-1/2 h-full">
            <div
              className={`flex justify-center items-center w-8 h-8 sm:w-12 sm:h-12 ${
                step >= 1
                  ? "bg-terminal-green text-terminal-black"
                  : "border border-terminal-green"
              }`}
            >
              {step > 1 ? <CompleteIcon /> : 1}
            </div>
            <div
              className={`flex justify-center items-center w-8 h-8 sm:w-12 sm:h-12  ${
                step >= 2
                  ? "bg-terminal-green text-terminal-black"
                  : "border border-terminal-green"
              }`}
            >
              {step > 2 ? <CompleteIcon /> : 2}
            </div>
            <div
              className={`flex justify-center items-center w-8 h-8 sm:w-12 sm:h-12  ${
                step >= 3
                  ? "bg-terminal-green text-terminal-black"
                  : "border border-terminal-green"
              }`}
            >
              3
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TopUp;
