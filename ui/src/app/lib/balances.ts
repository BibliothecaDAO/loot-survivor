import { CallData, uint256, Contract } from "starknet";
import { balanceSchema } from "@/app/lib/utils";

export const fetchEthBalance = async (
  accountName: string,
  ethContract?: Contract
) => {
  const ethResult = await ethContract?.call(
    "balanceOf",
    CallData.compile({ account: accountName })
  );
  return ethResult
    ? uint256.uint256ToBN(balanceSchema.parse(ethResult).balance)
    : BigInt(0);
};

export const fetchBalances = async (
  accountName: string,
  ethContract?: Contract,
  lordsContract?: Contract,
  gameContract?: Contract
): Promise<bigint[]> => {
  const ethResult = await ethContract?.call(
    "balanceOf",
    CallData.compile({ account: accountName })
  );
  const lordsBalanceResult = await lordsContract?.call(
    "balance_of",
    CallData.compile({
      account: accountName,
    })
  );
  const lordsAllowanceResult = await lordsContract?.call(
    "allowance",
    CallData.compile({
      owner: accountName,
      spender: gameContract?.address ?? "",
    })
  );
  return [
    ethResult
      ? uint256.uint256ToBN(balanceSchema.parse(ethResult).balance)
      : BigInt(0),
    lordsBalanceResult as bigint,
    lordsAllowanceResult as bigint,
  ];
};
