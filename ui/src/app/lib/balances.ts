import { CallData, uint256, Contract } from "starknet";
import { balanceSchema } from "./utils";

export const fetchBalances = async (
  accountName: string,
  ethContract?: Contract,
  lordsContract?: Contract,
  gameContract?: Contract
): Promise<bigint[]> => {
  const ethResult = await ethContract!.call(
    "balanceOf",
    CallData.compile({ account: accountName })
  );
  const lordsBalanceResult = await lordsContract!.call(
    "balance_of",
    CallData.compile({
      account: accountName,
    })
  );
  const lordsAllowanceResult = await lordsContract!.call(
    "allowance",
    CallData.compile({
      owner: accountName,
      spender: gameContract?.address ?? "",
    })
  );
  return [
    uint256.uint256ToBN(balanceSchema.parse(ethResult).balance),
    lordsBalanceResult as bigint,
    lordsAllowanceResult as bigint,
  ];
};
