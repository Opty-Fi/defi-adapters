import { TransactionRequest } from "@ethersproject/providers";

export function getOverrideOptions(): TransactionRequest {
  return {
    gasPrice: 1_000_000_00,
  };
}
