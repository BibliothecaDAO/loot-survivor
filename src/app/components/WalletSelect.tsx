import { Button } from "./Button";
import { useConnectors } from "@starknet-react/core";

const WalletSelect = () => {
  const { connectors, connect } = useConnectors();
  return (
    <div className="flex flex-col p-8 h-screen max-h-screen">
      <div className="w-full h-6 my-2 bg-terminal-green" />
      <div className="flex flex-col">
        <h1>ABOUT</h1>
        <div className="flex text-lg">
          <p className="p-4">
            Welcome, brave traveler! Prepare to embark on an extraordinary
            journey through the mystic lands of Eldarath, a high fantasy realm
            where Dragons, Ogres, Skeletons, and Phoenixes roam free, vying for
            supremacy amidst the remnants of a fallen empire. As a lone
            survivor, you are destined to traverse this beguiling world,
            battling fearsome beasts, unearthing lost relics, and uncovering
            secrets hidden within the mists of time.
          </p>
        </div>
      </div>
      <div className="flex flex-col gap-5 m-auto w-1/2">
        {connectors.map((connector) => (
          <Button
            onClick={() => connect(connector)}
            key={connector.id()}
            className="w-full"
          >
            Connect {connector.id()}
          </Button>
        ))}
      </div>
      <div className="w-full h-6 my-2 bg-terminal-green" />
    </div>
  );
};

export default WalletSelect;
