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
      <div className="fixed flex flex-col gap-20 justify-center items-center top-[5%] left-[5%] h-[90%] w-[90%] uppercase text-center border border-red-500 bg-terminal-black z-50">
        <p className="text-4xl">
          You are not on {process.env.NEXT_PUBLIC_NETWORK}!
        </p>
        <p className="text-xl">
          Please switch to the correct network before continuing.
        </p>
      </div>
    );
  } else {
    return null;
  }
}
