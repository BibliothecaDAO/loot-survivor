import { Button } from "./buttons/Button";

export const MainnetDialog = () => {
  return (
    <>
      <div className="fixed inset-0 opacity-80 bg-terminal-black z-40" />
      <div className="fixed text-center sm:top-1/8 sm:left-1/8 sm:left-1/4 sm:w-3/4 sm:w-1/2 h-3/4 border-4 bg-terminal-black z-50 border-terminal-green p-4 overflow-y-auto">
        <h3 className="mt-4">Mainnet</h3>
        <p className="m-2 text-sm xl:text-xl 2xl:text-2xl">
          You are on the mainnet site! We have not launched currently, please
          use testnet.
        </p>
        <a href="https://goerli-survivor.realms.world">
          <Button>Go To Testnet</Button>
        </a>
      </div>
    </>
  );
};
