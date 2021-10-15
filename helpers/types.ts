export type eNetwork =
  | eEthereumNetwork
  | ePolygonNetwork
  | eXDaiNetwork
  | eAvalancheNetwork
  | eArbitrumNetwork
  | eFantomNetwork
  | eBinanceSmartChainNetwork;

export enum eEthereumNetwork {
  main = "main",
  hardhat = "hardhat",
  kovan = "kovan",
  ropsten = "ropsten",
}

export enum ePolygonNetwork {
  matic = "matic",
  mumbai = "mumbai",
}

export enum eXDaiNetwork {
  xdai = "xdai",
}

export enum eAvalancheNetwork {
  avalanche = "avalanche",
  fuji = "fuji",
}

export enum eArbitrumNetwork {
  arbitrum1 = "arbitrum1",
  rinkarby = "rinkarby",
}

export enum eFantomNetwork {
  fantom = "fantom",
  fantom_test = "fantom_test",
}

export enum eBinanceSmartChainNetwork {
  bsc = "bsc",
  bsc_test = "bsc_test",
}

export enum EthereumNetworkNames {
  kovan = "kovan",
  ropsten = "ropsten",
  main = "main",
  matic = "matic",
  mumbai = "mumbai",
  xdai = "xdai",
  avalanche = "avalanche",
  fuji = "fuji",
  arbitrum1 = "arbitrum1",
  rinkarby = "rinkarby",
  fantom = "fantom",
  fantom_test = "fantom_test",
  bsc = "bsc",
  bsc_test = "bsc_test",
}

export type iParamsPerNetwork<T> =
  | iEthereumParamsPerNetwork<T>
  | iPolygonParamsPerNetwork<T>
  | iXDaiParamsPerNetwork<T>
  | iAvalancheParamsPerNetwork<T>
  | iArbitrumParamsPerNetwork<T>
  | iFantomParamsPerNetwork<T>
  | iBinanceSmartChainParamsPerNetwork<T>;

export interface iParamsPerNetworkAll<T>
  extends iEthereumParamsPerNetwork<T>,
    iPolygonParamsPerNetwork<T>,
    iXDaiParamsPerNetwork<T>,
    iAvalancheParamsPerNetwork<T>,
    iArbitrumParamsPerNetwork<T>,
    iFantomParamsPerNetwork<T>,
    iBinanceSmartChainParamsPerNetwork<T> {}

export interface iEthereumParamsPerNetwork<T> {
  [eEthereumNetwork.kovan]: T;
  [eEthereumNetwork.ropsten]: T;
  [eEthereumNetwork.main]: T;
  [eEthereumNetwork.hardhat]: T;
}

export interface iPolygonParamsPerNetwork<T> {
  [ePolygonNetwork.matic]: T;
  [ePolygonNetwork.mumbai]: T;
}

export interface iXDaiParamsPerNetwork<T> {
  [eXDaiNetwork.xdai]: T;
}

export interface iAvalancheParamsPerNetwork<T> {
  [eAvalancheNetwork.avalanche]: T;
  [eAvalancheNetwork.fuji]: T;
}

export interface iArbitrumParamsPerNetwork<T> {
  [eArbitrumNetwork.arbitrum1]: T;
  [eArbitrumNetwork.rinkarby]: T;
}

export interface iFantomParamsPerNetwork<T> {
  [eFantomNetwork.fantom]: T;
  [eFantomNetwork.fantom_test]: T;
}

export interface iBinanceSmartChainParamsPerNetwork<T> {
  [eBinanceSmartChainNetwork.bsc]: T;
  [eBinanceSmartChainNetwork.bsc_test]: T;
}
