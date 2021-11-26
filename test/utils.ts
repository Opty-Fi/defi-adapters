import { TransactionRequest } from "@ethersproject/providers";
import { BigNumber } from "ethers";

export function getOverrideOptions(): TransactionRequest {
  return {
    gasPrice: 1_000_000_00,
  };
}

export function ignoreRoundingError(bn: BigNumber): string {
  return bn.toString().substr(0, bn.toString().length - 2);
}
