import { Contract } from "starknet";

interface TopUpProps {
  ethBalance: bigint;
  lordsBalance: bigint;
  costToPlay: bigint;
  mintLords: (lordsAmount: number) => Promise<void>;
  gameContract: Contract;
  lordsContract: Contract;
  ethContract: Contract;
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
  showTopUpDialog,
}: TopUpProps) => {
  return (
    <>
      <div className="flex flex-col items-center gap-5 py-20 sm:p-0">
        <h1 className="m-0 uppercase text-6xl text-center">Top Up Required</h1>
      </div>
    </>
  );
};

export default TopUp;
