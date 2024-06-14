import { useAccount } from "@starknet-react/core";
import { useDojo } from "@/app/dojo/useDojo";
import useUIStore from "@/app/hooks/useUIStore";
import { Account } from "starknet";

export default function useNetworkAccount() {
  const network = useUIStore((state) => state.network);
  const {
    account: starknetAccount,
    status: starknetStatus,
    isConnected: starknetIsConnected,
  } = useAccount();
  const {
    account: { account: katanaAccount },
  } = useDojo();
  const account =
    network === "sepolia" || network === "mainnet"
      ? starknetAccount
      : (katanaAccount as Account);
  const address = account?.address;
  const status =
    network === "sepolia" || network === "mainnet"
      ? starknetStatus
      : "connected";
  const isConnected =
    network === "sepolia" || network === "mainnet" ? starknetIsConnected : true;

  return {
    account,
    address,
    status,
    isConnected,
  };
}
