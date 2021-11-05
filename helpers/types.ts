export type eNetwork =
  | eEthereumNetwork
  | ePolygonNetwork
  | eXDaiNetwork
  | eAvalancheNetwork
  | eArbitrumNetwork
  | eFantomNetwork
  | eBinanceSmartChainNetwork
  | eOptimisticEthereumNetwork;

export enum eEthereumNetwork {
  main = "main",
  hardhat = "hardhat",
  kovan = "kovan",
  ropsten = "ropsten",
  goerli = "goerli",
  rinkeby = "rinkeby",
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
  rinkeby_arbitrum1 = "rinkeby_arbitrum1",
}

export enum eFantomNetwork {
  fantom = "fantom",
  fantom_test = "fantom_test",
}

export enum eBinanceSmartChainNetwork {
  bsc = "bsc",
  bsc_test = "bsc_test",
}

export enum eOptimisticEthereumNetwork {
  oethereum = "oethereum",
  kovan_oethereum = "kovan_oethereum",
  goerli_oethereum = "goerli_oethereum",
}

export enum EthereumNetworkNames {
  main = "main",
  kovan = "kovan",
  ropsten = "ropsten",
  goerli = "goerli",
  rinkeby = "rinkeby",
  matic = "matic",
  mumbai = "mumbai",
  xdai = "xdai",
  avalanche = "avalanche",
  fuji = "fuji",
  arbitrum1 = "arbitrum1",
  rinkeby_arbitrum1 = "rinkeby_arbitrum1",
  fantom = "fantom",
  fantom_test = "fantom_test",
  bsc = "bsc",
  bsc_test = "bsc_test",
  oethereum = "oethereum",
  kovan_oethereum = "kovan_oethereum",
  goerli_oethereum = "goerli_oethereum",
}

export type iParamsPerNetwork<T> =
  | iEthereumParamsPerNetwork<T>
  | iPolygonParamsPerNetwork<T>
  | iXDaiParamsPerNetwork<T>
  | iAvalancheParamsPerNetwork<T>
  | iArbitrumParamsPerNetwork<T>
  | iFantomParamsPerNetwork<T>
  | iBinanceSmartChainParamsPerNetwork<T>
  | iOptimisticEthereumParamsPerNetwork<T>;

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
  [eEthereumNetwork.rinkeby]: T;
  [eEthereumNetwork.goerli]: T;
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
  [eArbitrumNetwork.rinkeby_arbitrum1]: T;
}

export interface iFantomParamsPerNetwork<T> {
  [eFantomNetwork.fantom]: T;
  [eFantomNetwork.fantom_test]: T;
}

export interface iBinanceSmartChainParamsPerNetwork<T> {
  [eBinanceSmartChainNetwork.bsc]: T;
  [eBinanceSmartChainNetwork.bsc_test]: T;
}

export interface iOptimisticEthereumParamsPerNetwork<T> {
  [eOptimisticEthereumNetwork.oethereum]: T;
  [eOptimisticEthereumNetwork.kovan_oethereum]: T;
  [eOptimisticEthereumNetwork.goerli_oethereum]: T;
}
