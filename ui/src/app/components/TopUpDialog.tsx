import { Contract } from "starknet";

interface TopUpDialogProps {
  ethContract: Contract;
  getEthBalance: () => Promise<void>;
  ethBalance: number;
}

export const TopUpDialog = ({
  ethContract,
  getEthBalance,
  ethBalance,
}: TopUpDialogProps) => {
  return (
    <>
      <div className="fixed inset-0 opacity-80 bg-terminal-black z-40" />
      <div className="fixed text-center sm:top-1/8 sm:left-1/8 sm:left-1/4 sm:w-3/4 sm:w-1/2 h-3/4 border-4 bg-terminal-black z-50 border-terminal-green p-4 overflow-y-auto">
        <h3 className="mt-4">Top Up Required</h3>
      </div>
    </>
  );
};
