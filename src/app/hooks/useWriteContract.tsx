import {
  useAccount,
  useContract,
  useContractWrite,
} from "@starknet-react/core";
import { useMemo, useState } from "react";

export const useWriteContract = () => {
  // const { address } = useAccount();

  const [calls, setCalls] = useState<any>([]);

  const addToCalls = ({ contractAddress, selector, calldata }: any) => {
    const tx = {
      contractAddress: contractAddress,
      entrypoint: selector,
      calldata: calldata,
    };

    setCalls((calls: any) => [...calls, tx]);
  };

  // useMemo(() => {
  //   const tx = {
  //     contractAddress: contractAddress,
  //     entrypoint: selector,
  //     calldata: calldata,
  //   };

  //   setCalls((calls: any) => [...calls, tx]);
  // }, [address]);

  const { write } = useContractWrite({ calls });

  return { write, calls, addToCalls };
};
