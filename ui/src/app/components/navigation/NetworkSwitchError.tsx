import { useAccount } from "@starknet-react/core";

export interface NetworkSwitchErrorProps {
  isWrongNetwork: boolean;
}

export default function NetworkSwitchError({
  isWrongNetwork,
}: NetworkSwitchErrorProps) {
  const { account } = useAccount();
  if (account && isWrongNetwork) {
    return (
      <div className="fixed flex flex-col items-center top-10 w-[90%] sm:left-3/8 sm:right-3/8 sm:w-1/4 uppercase text-center border border-terminal-green bg-terminal-black z-50">
        <p>You are not on Goerli network!</p>
        <p>Please switch network to avoid risks with funds</p>
      </div>
    );
  } else {
    return null;
  }
}
