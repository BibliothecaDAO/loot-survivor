import { Contract, CallData, uint256 } from "starknet";
import { z } from "zod";

const MAX_RETRIES = 10;
const RETRY_DELAY = 2000; // 2 seconds

export const fetchBalanceWithRetry = async (
  contract: Contract,
  accountName: string,
  retryCount: number = 0
): Promise<bigint> => {
  try {
    const result = await contract!.call(
      "balanceOf",
      CallData.compile({ account: accountName })
    );
    return uint256.uint256ToBN(balanceSchema.parse(result).balance);
  } catch (error) {
    if (retryCount < MAX_RETRIES) {
      await new Promise((resolve) => setTimeout(resolve, RETRY_DELAY)); // delay before retry
      return fetchBalanceWithRetry(contract, accountName, retryCount + 1);
    } else {
      throw new Error(`Failed to fetch balance after ${MAX_RETRIES} retries.`);
    }
  }
};

export const uint256Schema = z.object({
  low: z.bigint(),
  high: z.bigint(),
});

export const balanceSchema = z.object({
  balance: uint256Schema,
});
