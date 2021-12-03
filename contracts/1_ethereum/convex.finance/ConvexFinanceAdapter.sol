// solhint-disable no-unused-vars
// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/////////////////////////////////////////////////////
/// PLEASE DO NOT USE THIS CONTRACT IN PRODUCTION ///
/////////////////////////////////////////////////////

//  libraries
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

//  interfaces
import { IAdapter } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapter.sol";
import { IAdapterStaking } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterStaking.sol";
import { IAdapterHarvestReward } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterHarvestReward.sol";
import { IConvexDeposit } from "./interfaces/IConvexDeposit.sol";
import { IConvexStake } from "./interfaces/IConvexStake.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICurvePoolInfo } from "./interfaces/ICurvePoolInfo.sol";
import { ICurveStableSwap } from "./interfaces/ICurveStableSwap.sol";
import { ICurveStableSwap2, ICurveStableSwap3, ICurveStableSwap4 } from "./interfaces/ICurveStableSwap.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @title Adapter for Convex.finance protocol
 * @author niklr
 * @dev Abstraction layer to convex finance's pools.
 * We assume the pool data to have liquidityPoolToken and liquidityPool's address to be same.
 */

contract ConvexFinanceAdapter is IAdapter, IAdapterHarvestReward, IAdapterStaking {
    using SafeMath for uint256;

    struct PoolData {
        uint256 id;
        address swap;
        address zap;
    }

    struct PoolCoinData {
        address coinRef;
        uint256 coinRefIndex;
        address[] coins;
        address underlyingCoinRef;
        uint256 underlyingCoinRefIndex;
        address[] underlyingCoins;
    }

    struct DepositInfo {
        address destination;
        uint256 coinsAmount;
        address coinRef;
        uint256 coinRefIndex;
    }

    /** @notice Maps liquidityPoolToken to poolData */
    mapping(address => PoolData) public lpTokenToPoolData;
    /** @notice Maps swap address to poolCoinData */
    mapping(address => PoolCoinData) public swapToPoolCoinData;

    /** @notice Uniswap V2 router contract address */
    address public constant uniswapV2Router02 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    /** @notice preferred coin for swaps */
    address public constant prefCoin = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    // https://curve.readthedocs.io/registry-registry.html
    // https://github.com/curvefi/curve-pool-registry
    address public constant curveRegistry = address(0x7D86446dDb609eD0F5f8684AcF30380a356b2B4c);
    address public constant curvePoolInfo = address(0xe64608E223433E8a03a1DaaeFD8Cb638C14B552C);

    // deposit pool
    address public constant BOOSTER_DEPOSIT_POOL = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    // lpTokens
    address public constant COMPOUND_LP_TOKEN = address(0x32512Bee3848bfcBb7bEAf647aa697a100f3b706);
    address public constant USDT_LP_TOKEN = address(0xA1c3492b71938E144ad8bE4c2fB6810b01A43dD8);
    address public constant YPOOL_LP_TOKEN = address(0x0928F6753880A03628eB0be07b77992c8af37874);
    address public constant BUSD_LP_TOKEN = address(0x59bB786F222d3f0f00B0dA31B799Fff80D552940);
    address public constant SUSD_LP_TOKEN = address(0x11D200ef1409cecA8D6d23e6496550f707772F11);
    address public constant PAX_LP_TOKEN = address(0x2eA94b0d3349A284488ACF2934E494b2f58ef647);
    address public constant REN_LP_TOKEN = address(0x74b79021Ea6De3f0D1731fb8BdfF6eE7DF10b8Ae);
    address public constant SBTC_LP_TOKEN = address(0xbA723E335eC2939D52a2efcA2a8199cb4CB93cC3);
    address public constant HBTC_LP_TOKEN = address(0x33c00bF8CFDf42929E0884d230A55F963221f8f3);
    address public constant THREE_POOL_LP_TOKEN = address(0x30D9410ED1D5DA1F6C8391af5338C93ab8d4035C);
    address public constant GUSD_LP_TOKEN = address(0x15c2471ef46Fa721990730cfa526BcFb45574576);
    address public constant HUSD_LP_TOKEN = address(0xe4de776C0eA0974bfA39B8cbB9491091C8cDc1ff);
    address public constant USDK_LP_TOKEN = address(0x47941F99F4371CC26637CaEdBbd8Ba5F4bfE5149);
    address public constant USDN_LP_TOKEN = address(0x3689f325E88c2363274E5F3d44b6DaB8f9e1f524);
    address public constant MUSD_LP_TOKEN = address(0xd34d466233c5195193dF712936049729140DBBd7);
    address public constant RSV_LP_TOKEN = address(0x8b876C2C02B1f2Ac6Ec207B7f2f06034A4316A87);
    address public constant TBTC_LP_TOKEN = address(0x36CED690A1516861f26755b978EE62c1157CFFF9);
    address public constant DUSD_LP_TOKEN = address(0x06f4fFa5C3636AaA5C30B3DB97bfd1cd9Ac24A19);
    address public constant PBTC_LP_TOKEN = address(0x21Cce64289407081744F087950b9DB32906470fC);
    address public constant BBTC_LP_TOKEN = address(0x2E1f902b9067b5fDd7AF29ef05D4fF6212588388);
    address public constant OBTC_LP_TOKEN = address(0xc1C030139eEc070Ed8FD092CC8C273C638A18bBe);
    address public constant UST_LP_TOKEN = address(0x67c4f788FEB82FAb27E3007daa3d7b90959D5b89);
    address public constant EURS_LP_TOKEN = address(0xd7E2b9494c529b42Dea53EF6a237C16502E6A927);
    address public constant SETH_LP_TOKEN = address(0xAF1d4C576bF55f6aE493AEebAcC3a227675e5B98);
    address public constant AAVE_LP_TOKEN = address(0x23F224C37C3A69A058d86a54D3f561295A93d542);
    address public constant STETH_LP_TOKEN = address(0x9518c9063eB0262D791f38d8d6Eb0aca33c63ed0);
    address public constant SAAVE_LP_TOKEN = address(0x09CCD0892b696AB21436e51588a7a7f8b649733d);
    address public constant ANKRETH_LP_TOKEN = address(0x7E96955b66c89B931BBDAf187740Cc0fF2602F21);
    address public constant USDP_LP_TOKEN = address(0x7a5dC1FA2e1B10194bD2e2e9F1A224971A681444);
    address public constant IRONBANK_LP_TOKEN = address(0x912EC00eaEbf3820a9B0AC7a5E15F381A1C91f22);
    address public constant LINK_LP_TOKEN = address(0xD37969740d78C94C648d74671B8BE31eF43c30aB);
    address public constant TUSD_LP_TOKEN = address(0x0A2eA49EB5F9e23058deffD509D13DDd553c2A19);
    address public constant FRAX_LP_TOKEN = address(0xbE0F6478E0E4894CFb14f32855603A083A57c7dA);
    address public constant LUSD_LP_TOKEN = address(0xFB9B2f06FDb404Fd3E2278E9A9edc8f252F273d0);
    address public constant BUSDVTWO__LP_TOKEN = address(0x02D784f98A312aF3e2771297Feff1Da8273e4F29);
    address public constant RETH_LP_TOKEN = address(0x7ADd8D0E923CB692DF6bC65d96d510f0E2fC37af);
    address public constant ALUSD_LP_TOKEN = address(0xCA3D9F45FfA69ED454E66539298709cb2dB8cA61);
    address public constant TRICRYPTO_LP_TOKEN = address(0x18684099414dcEF486F4FA5b4e44e6eA53C8c554);
    address public constant TRICRYPTOTWO__LP_TOKEN = address(0x903C9974aAA431A765e60bC07aF45f0A1B3b61fb);
    address public constant EURT_LP_TOKEN = address(0x2b2175AC371Ec2900AC39fb87452340F65CC9895);
    address public constant MIM_LP_TOKEN = address(0xabB54222c2b77158CC975a2b715a3d703c256F05);

    constructor() public {
        lpTokenToPoolData[COMPOUND_LP_TOKEN] = PoolData({
            id: 0,
            swap: address(0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56),
            zap: address(0x0000000000000000000000000000000000000000) // DepositZap.calc_token_amount is missing
        });
        lpTokenToPoolData[USDT_LP_TOKEN] = PoolData({
            id: 1,
            swap: address(0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C),
            zap: address(0x0000000000000000000000000000000000000000) // DepositZap.calc_token_amount is missing
        });
        lpTokenToPoolData[YPOOL_LP_TOKEN] = PoolData({
            id: 2,
            swap: address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51),
            zap: address(0x0000000000000000000000000000000000000000) // DepositZap.calc_token_amount is missing
        });
        lpTokenToPoolData[BUSD_LP_TOKEN] = PoolData({
            id: 3,
            swap: address(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27),
            zap: address(0x0000000000000000000000000000000000000000) // DepositZap.calc_token_amount is missing
        });
        lpTokenToPoolData[SUSD_LP_TOKEN] = PoolData({
            id: 4,
            swap: address(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD),
            zap: address(0x0000000000000000000000000000000000000000) // DepositZap.calc_token_amount is missing
        });
        lpTokenToPoolData[PAX_LP_TOKEN] = PoolData({
            id: 5,
            swap: address(0x06364f10B501e868329afBc005b3492902d6C763),
            zap: address(0x0000000000000000000000000000000000000000) // DepositZap.calc_token_amount is missing
        });
        lpTokenToPoolData[REN_LP_TOKEN] = PoolData({
            id: 6,
            swap: address(0x93054188d876f558f4a66B2EF1d97d16eDf0895B),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[SBTC_LP_TOKEN] = PoolData({
            id: 7,
            swap: address(0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[HBTC_LP_TOKEN] = PoolData({
            id: 8,
            swap: address(0x4CA9b3063Ec5866A4B82E437059D2C43d1be596F),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[THREE_POOL_LP_TOKEN] = PoolData({
            id: 9,
            swap: address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[GUSD_LP_TOKEN] = PoolData({
            id: 10,
            swap: address(0x4f062658EaAF2C1ccf8C8e36D6824CDf41167956),
            zap: address(0x64448B78561690B70E17CBE8029a3e5c1bB7136e)
        });
        lpTokenToPoolData[HUSD_LP_TOKEN] = PoolData({
            id: 11,
            swap: address(0x3eF6A01A0f81D6046290f3e2A8c5b843e738E604),
            zap: address(0x09672362833d8f703D5395ef3252D4Bfa51c15ca)
        });
        lpTokenToPoolData[USDK_LP_TOKEN] = PoolData({
            id: 12,
            swap: address(0x3E01dD8a5E1fb3481F0F589056b428Fc308AF0Fb),
            zap: address(0xF1f85a74AD6c64315F85af52d3d46bF715236ADc)
        });
        lpTokenToPoolData[USDN_LP_TOKEN] = PoolData({
            id: 13,
            swap: address(0x0f9cb53Ebe405d49A0bbdBD291A65Ff571bC83e1),
            zap: address(0x094d12e5b541784701FD8d65F11fc0598FBC6332)
        });
        lpTokenToPoolData[MUSD_LP_TOKEN] = PoolData({
            id: 14,
            swap: address(0x8474DdbE98F5aA3179B3B3F5942D724aFcdec9f6),
            zap: address(0x803A2B40c5a9BB2B86DD630B274Fa2A9202874C2)
        });
        lpTokenToPoolData[RSV_LP_TOKEN] = PoolData({
            id: 15,
            swap: address(0xC18cC39da8b11dA8c3541C598eE022258F9744da),
            zap: address(0xBE175115BF33E12348ff77CcfEE4726866A0Fbd5)
        });
        lpTokenToPoolData[TBTC_LP_TOKEN] = PoolData({
            id: 16,
            swap: address(0xC25099792E9349C7DD09759744ea681C7de2cb66),
            zap: address(0xaa82ca713D94bBA7A89CEAB55314F9EfFEdDc78c)
        });
        lpTokenToPoolData[DUSD_LP_TOKEN] = PoolData({
            id: 17,
            swap: address(0x8038C01A0390a8c547446a0b2c18fc9aEFEcc10c),
            zap: address(0x61E10659fe3aa93d036d099405224E4Ac24996d0)
        });
        lpTokenToPoolData[PBTC_LP_TOKEN] = PoolData({
            id: 18,
            swap: address(0x7F55DDe206dbAD629C080068923b36fe9D6bDBeF),
            zap: address(0x11F419AdAbbFF8d595E7d5b223eee3863Bb3902C)
        });
        lpTokenToPoolData[BBTC_LP_TOKEN] = PoolData({
            id: 19,
            swap: address(0x071c661B4DeefB59E2a3DdB20Db036821eeE8F4b),
            zap: address(0xC45b2EEe6e09cA176Ca3bB5f7eEe7C47bF93c756)
        });
        lpTokenToPoolData[OBTC_LP_TOKEN] = PoolData({
            id: 20,
            swap: address(0xd81dA8D904b52208541Bade1bD6595D8a251F8dd),
            zap: address(0xd5BCf53e2C81e1991570f33Fa881c49EEa570C8D)
        });
        lpTokenToPoolData[UST_LP_TOKEN] = PoolData({
            id: 21,
            swap: address(0x890f4e345B1dAED0367A877a1612f86A1f86985f),
            zap: address(0xB0a0716841F2Fc03fbA72A891B8Bb13584F52F2d)
        });
        lpTokenToPoolData[EURS_LP_TOKEN] = PoolData({
            id: 22,
            swap: address(0x0Ce6a5fF5217e38315f87032CF90686C96627CAA),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[SETH_LP_TOKEN] = PoolData({
            id: 23,
            swap: address(0xc5424B857f758E906013F3555Dad202e4bdB4567),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[AAVE_LP_TOKEN] = PoolData({
            id: 24,
            swap: address(0xDeBF20617708857ebe4F679508E7b7863a8A8EeE),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[STETH_LP_TOKEN] = PoolData({
            id: 25,
            swap: address(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[SAAVE_LP_TOKEN] = PoolData({
            id: 26,
            swap: address(0xEB16Ae0052ed37f479f7fe63849198Df1765a733),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[ANKRETH_LP_TOKEN] = PoolData({
            id: 27,
            swap: address(0xA96A65c051bF88B4095Ee1f2451C2A9d43F53Ae2),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[USDP_LP_TOKEN] = PoolData({
            id: 28,
            swap: address(0x42d7025938bEc20B69cBae5A77421082407f053A),
            zap: address(0x3c8cAee4E09296800f8D29A68Fa3837e2dae4940)
        });
        lpTokenToPoolData[IRONBANK_LP_TOKEN] = PoolData({
            id: 29,
            swap: address(0x2dded6Da1BF5DBdF597C45fcFaa3194e53EcfeAF),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[LINK_LP_TOKEN] = PoolData({
            id: 30,
            swap: address(0xF178C0b5Bb7e7aBF4e12A4838C7b7c5bA2C623c0),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[TUSD_LP_TOKEN] = PoolData({
            id: 31,
            swap: address(0xEcd5e75AFb02eFa118AF914515D6521aaBd189F1),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[FRAX_LP_TOKEN] = PoolData({
            id: 32,
            swap: address(0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[LUSD_LP_TOKEN] = PoolData({
            id: 33,
            swap: address(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[BUSDVTWO__LP_TOKEN] = PoolData({
            id: 34,
            swap: address(0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[RETH_LP_TOKEN] = PoolData({
            id: 35,
            swap: address(0xF9440930043eb3997fc70e1339dBb11F341de7A8),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[ALUSD_LP_TOKEN] = PoolData({
            id: 36,
            swap: address(0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[TRICRYPTO_LP_TOKEN] = PoolData({
            id: 37,
            swap: address(0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[TRICRYPTOTWO__LP_TOKEN] = PoolData({
            id: 38,
            swap: address(0xD51a44d3FaE010294C616388b506AcdA1bfAAE46),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[EURT_LP_TOKEN] = PoolData({
            id: 39,
            swap: address(0xFD5dB7463a3aB53fD211b4af195c5BCCC1A03890),
            zap: address(0x0000000000000000000000000000000000000000)
        });
        lpTokenToPoolData[MIM_LP_TOKEN] = PoolData({
            id: 40,
            swap: address(0x5a6A4D54456819380173272A5E8E9B9904BdF41B),
            zap: address(0x0000000000000000000000000000000000000000)
        });
    }

    /**
     * @inheritdoc IAdapter
     */
    function getDepositAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (bytes[] memory _codes) {
        uint256 _amount = IERC20(_underlyingToken).balanceOf(_vault);
        return getDepositSomeCodes(_vault, _underlyingToken, _liquidityPool, _amount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (bytes[] memory _codes) {
        uint256 _redeemAmount = getLiquidityPoolTokenBalance(_vault, _underlyingToken, _liquidityPool);
        return getWithdrawSomeCodes(_vault, _underlyingToken, _liquidityPool, _redeemAmount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getUnderlyingTokens(address _liquidityPool, address)
        public
        view
        override
        returns (address[] memory _underlyingTokens)
    {
        _underlyingTokens = new address[](1);
        _underlyingTokens[0] = _getPoolInfo(_liquidityPool).lptoken;
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateAmountInLPToken(
        address,
        address,
        uint256 _depositAmount
    ) public view override returns (uint256) {
        return _depositAmount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateRedeemableLPTokenAmount(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) public view override returns (uint256 _amount) {
        uint256 _liquidityPoolTokenBalance = getLiquidityPoolTokenBalance(_vault, _underlyingToken, _liquidityPool);
        uint256 _balanceInToken = getAllAmountInToken(_vault, _underlyingToken, _liquidityPool);
        // can have unintentional rounding errors
        _amount = (_liquidityPoolTokenBalance.mul(_redeemAmount)).div(_balanceInToken);
    }

    /**
     * @inheritdoc IAdapter
     */
    function isRedeemableAmountSufficient(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) public view override returns (bool) {
        uint256 _balanceInToken = getAllAmountInToken(_vault, _underlyingToken, _liquidityPool);
        return _balanceInToken >= _redeemAmount;
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getClaimRewardTokenCode(address payable, address _liquidityPool)
        public
        view
        override
        returns (bytes[] memory _codes)
    {
        address _stakingVault = _getPoolInfo(_liquidityPool).crvRewards;
        _codes = new bytes[](1);
        // Claims both the CRV and CVX reward tokens
        // https://github.com/convex-eth/platform/blob/main/contracts/contracts/BaseRewardPool.sol#L281
        _codes[0] = abi.encode(_stakingVault, abi.encodeWithSignature("getReward()"));
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getHarvestAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (bytes[] memory _codes) {
        uint256 _rewardTokenAmount = IERC20(getRewardToken(_liquidityPool)).balanceOf(_vault);
        return getHarvestSomeCodes(_vault, _underlyingToken, _liquidityPool, _rewardTokenAmount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function canStake(address) public view override returns (bool) {
        return true;
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function getStakeAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (bytes[] memory _codes) {
        uint256 _depositAmount = getLiquidityPoolTokenBalance(_vault, _underlyingToken, _liquidityPool);
        return getStakeSomeCodes(_liquidityPool, _depositAmount);
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function getUnstakeAllCodes(address payable _vault, address _liquidityPool)
        public
        view
        override
        returns (bytes[] memory _codes)
    {
        uint256 _redeemAmount = getLiquidityPoolTokenBalanceStake(_vault, _liquidityPool);
        return getUnstakeSomeCodes(_liquidityPool, _redeemAmount);
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function calculateRedeemableLPTokenAmountStake(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) public view override returns (uint256 _amount) {
        address _stakingVault = _getPoolInfo(_liquidityPool).crvRewards;
        uint256 _liquidityPoolTokenBalance = IConvexStake(_stakingVault).balanceOf(_vault);
        uint256 _balanceInToken = getAllAmountInTokenStake(_vault, _underlyingToken, _liquidityPool);
        // can have unintentional rounding errors
        _amount = (_liquidityPoolTokenBalance.mul(_redeemAmount)).div(_balanceInToken);
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function isRedeemableAmountSufficientStake(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) public view override returns (bool) {
        uint256 _balanceInTokenStake = getAllAmountInTokenStake(_vault, _underlyingToken, _liquidityPool);
        return _balanceInTokenStake >= _redeemAmount;
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function getUnstakeAndWithdrawAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (bytes[] memory _codes) {
        uint256 _unstakeAmount = getLiquidityPoolTokenBalanceStake(_vault, _liquidityPool);
        return getUnstakeAndWithdrawSomeCodes(_vault, _underlyingToken, _liquidityPool, _unstakeAmount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getDepositSomeCodes(
        address payable,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _amount
    ) public view override returns (bytes[] memory _codes) {
        if (_amount > 0) {
            uint256 _pid = lpTokenToPoolData[_liquidityPool].id;
            _codes = new bytes[](2);
            _codes[0] = abi.encode(
                _underlyingToken,
                abi.encodeWithSignature("approve(address,uint256)", BOOSTER_DEPOSIT_POOL, _amount)
            );
            _codes[1] = abi.encode(
                BOOSTER_DEPOSIT_POOL,
                abi.encodeWithSignature("deposit(uint256,uint256,bool)", _pid, _amount, false) // bool = stake
            );
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawSomeCodes(
        address payable,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _shares
    ) public view override returns (bytes[] memory _codes) {
        if (_shares > 0) {
            uint256 _pid = lpTokenToPoolData[_liquidityPool].id;
            _codes = new bytes[](1);
            _codes[0] = abi.encode(
                BOOSTER_DEPOSIT_POOL,
                abi.encodeWithSignature("withdraw(uint256,uint256)", _pid, _shares)
            );
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getPoolValue(address _liquidityPool, address) public view override returns (uint256) {
        IConvexDeposit.PoolInfo memory poolInfo = _getPoolInfo(_liquidityPool);
        return IERC20(poolInfo.gauge).balanceOf(IConvexDeposit(BOOSTER_DEPOSIT_POOL).staker());
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolToken(address, address _liquidityPool) public view override returns (address) {
        return _getPoolInfo(_liquidityPool).token;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getAllAmountInToken(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (uint256) {
        return
            getSomeAmountInToken(
                _underlyingToken,
                _liquidityPool,
                getLiquidityPoolTokenBalance(_vault, _underlyingToken, _liquidityPool)
            );
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolTokenBalance(
        address payable _vault,
        address,
        address _liquidityPool
    ) public view override returns (uint256) {
        return IERC20(getLiquidityPoolToken(address(0), _liquidityPool)).balanceOf(_vault);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getSomeAmountInToken(
        address,
        address,
        uint256 _liquidityPoolTokenAmount
    ) public view override returns (uint256) {
        return _liquidityPoolTokenAmount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getRewardToken(address _liquidityPool) public view override returns (address) {
        return IConvexStake(_getPoolInfo(_liquidityPool).crvRewards).rewardToken();
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getUnclaimedRewardTokenAmount(
        address payable _vault,
        address _liquidityPool,
        address
    ) public view override returns (uint256) {
        return IConvexStake(_getPoolInfo(_liquidityPool).crvRewards).earned(_vault);
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getHarvestSomeCodes(
        address payable _vault,
        address,
        address _liquidityPool,
        uint256 _rewardTokenAmount
    ) public view override returns (bytes[] memory _codes) {
        return _getHarvestCodes(_vault, getRewardToken(_liquidityPool), _liquidityPool, _rewardTokenAmount);
    }

    /* solhint-disable no-empty-blocks */

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getAddLiquidityCodes(address payable, address) public view override returns (bytes[] memory) {}

    /* solhint-enable no-empty-blocks */

    /**
     * @inheritdoc IAdapterStaking
     */
    function getStakeSomeCodes(address _liquidityPool, uint256 _shares)
        public
        view
        override
        returns (bytes[] memory _codes)
    {
        if (_shares > 0) {
            address _stakingVault = _getPoolInfo(_liquidityPool).crvRewards;
            address _liquidityPoolToken = getLiquidityPoolToken(address(0), _liquidityPool);
            _codes = new bytes[](2);
            _codes[0] = abi.encode(
                _liquidityPoolToken,
                abi.encodeWithSignature("approve(address,uint256)", _stakingVault, _shares)
            );
            _codes[1] = abi.encode(_stakingVault, abi.encodeWithSignature("stake(uint256)", _shares));
        }
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function getUnstakeSomeCodes(address _liquidityPool, uint256 _shares)
        public
        view
        override
        returns (bytes[] memory _codes)
    {
        if (_shares > 0) {
            address _stakingVault = _getPoolInfo(_liquidityPool).crvRewards;
            _codes = new bytes[](1);
            _codes[0] = abi.encode(
                _stakingVault,
                abi.encodeWithSignature("withdraw(uint256,bool)", _shares, true) // bool = claim
            );
        }
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function getAllAmountInTokenStake(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (uint256) {
        address _stakingVault = _getPoolInfo(_liquidityPool).crvRewards;
        uint256 b = IConvexStake(_stakingVault).balanceOf(_vault);
        uint256 _unclaimedReward = getUnclaimedRewardTokenAmount(_vault, _liquidityPool, _underlyingToken);
        if (_unclaimedReward > 0) {
            b = b.add(
                getRewardBalanceInUnderlyingTokens(getRewardToken(_liquidityPool), _liquidityPool, _unclaimedReward)
            );
        }
        return b;
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function getLiquidityPoolTokenBalanceStake(address payable _vault, address _liquidityPool)
        public
        view
        override
        returns (uint256)
    {
        return IConvexStake(_getPoolInfo(_liquidityPool).crvRewards).balanceOf(_vault);
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function getUnstakeAndWithdrawSomeCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) public view override returns (bytes[] memory _codes) {
        if (_redeemAmount > 0) {
            _codes = new bytes[](2);
            _codes[0] = getUnstakeSomeCodes(_liquidityPool, _redeemAmount)[0];
            _codes[1] = getWithdrawSomeCodes(_vault, _underlyingToken, _liquidityPool, _redeemAmount)[0];
        }
    }

    /**
     * @dev Sets the pool coin data based on the Curve Registry: Pool Info
     * @param _liquidityPool Liquidity pool's contract address
     */
    function setPoolCoinData(address _liquidityPool) public {
        PoolData memory _poolData = lpTokenToPoolData[_liquidityPool];
        address _swap = _poolData.swap;
        require(_swap != address(0), "_swap");
        ICurvePoolInfo.PoolCoins memory _coinData = ICurvePoolInfo(curvePoolInfo).get_pool_coins(_swap);
        uint256 _coinsAmount;
        uint256 _underlyingCoinsAmount;
        for (uint256 i = 0; i < 8; i++) {
            if (_coinData.coins[i] != address(0)) {
                _coinsAmount++;
            }
            if (_coinData.underlying_coins[i] != address(0)) {
                _underlyingCoinsAmount++;
            }
        }
        address[] memory _coins = new address[](_coinsAmount);
        address[] memory _underlyingCoins = new address[](_underlyingCoinsAmount);
        PoolCoinData memory _poolCoinData = PoolCoinData({
            coinRef: address(0),
            coinRefIndex: 0,
            coins: _coins,
            underlyingCoinRef: address(0),
            underlyingCoinRefIndex: 0,
            underlyingCoins: _underlyingCoins
        });
        _fillPoolCoinData(_coinData, _poolCoinData);
        require(_poolCoinData.coins.length > 0, "coins.length");
        require(_poolCoinData.underlyingCoins.length > 0, "underlyingCoins.length");
        require(_poolCoinData.coinRef != address(0), "coinRef");
        require(_poolCoinData.underlyingCoinRef != address(0), "underlyingCoinRef");
        swapToPoolCoinData[_swap] = _poolCoinData;
    }

    function _fillPoolCoinData(ICurvePoolInfo.PoolCoins memory _coinData, PoolCoinData memory _poolCoinData)
        internal
        pure
    {
        uint256 _coinIndex;
        uint256 _underlyingCoinIndex;
        for (uint256 i = 0; i < 8; i++) {
            if (_coinData.coins[i] != address(0)) {
                if (_coinIndex == 0) {
                    _poolCoinData.coinRef = _coinData.coins[i];
                    _poolCoinData.coinRefIndex = i;
                }
                _poolCoinData.coins[_coinIndex] = _coinData.coins[i];
                _coinIndex++;
            }
            if (_coinData.underlying_coins[i] != address(0)) {
                if (_underlyingCoinIndex == 0 || _coinData.underlying_coins[i] == prefCoin) {
                    //if (_underlyingCoinIndex == 0) {
                    _poolCoinData.underlyingCoinRef = _coinData.underlying_coins[i];
                    _poolCoinData.underlyingCoinRefIndex = i;
                }
                _poolCoinData.underlyingCoins[_underlyingCoinIndex] = _coinData.underlying_coins[i];
                _underlyingCoinIndex++;
            }
        }
    }

    /**
     * @dev Get the underlying token amount equivalent to reward token amount
     * @param _rewardToken Reward token address
     * @param _liquidityPool Liquidity pool's contract address
     * @param _amount reward token balance amount
     * @return equivalent reward token balance in Underlying token value
     */
    function getRewardBalanceInUnderlyingTokens(
        address _rewardToken,
        address _liquidityPool,
        uint256 _amount
    ) public view returns (uint256) {
        PoolData memory _poolData = lpTokenToPoolData[_liquidityPool];
        DepositInfo memory _depositInfo = _getDepositInfo(_poolData);
        uint256 _swapTokenAmount = _getSwapTokenAmount(_rewardToken, _depositInfo.coinRef, _amount);
        uint256 _rewardTokenBalance = _calcCoinRefDepositAmount(_poolData, _swapTokenAmount);
        return _rewardTokenBalance;
    }

    /**
     * @dev Get the coin reference amount equivalent to reward token amount
     * @param _rewardToken Reward token address
     * @param _liquidityPool Liquidity pool's contract address
     * @param _amount reward token balance amount
     * @return equivalent reward token balance in coin reference value
     */
    function getSwapTokenAmounts(
        address _rewardToken,
        address _liquidityPool,
        uint256 _amount
    ) public view returns (uint256[] memory) {
        PoolData memory _poolData = lpTokenToPoolData[_liquidityPool];
        DepositInfo memory _depositInfo = _getDepositInfo(_poolData);
        uint256[] memory _swapAmounts = IUniswapV2Router02(uniswapV2Router02).getAmountsOut(
            _amount,
            _getPath(_rewardToken, _depositInfo.coinRef)
            //_getPath(_rewardToken, address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)) // USDC
            //_getPath(_rewardToken, address(0x6B175474E89094C44Da98b954EedeAC495271d0F)) // DAI
        );
        return _swapAmounts;
    }

    /**
     * @dev Get the final token amount equivalent to initial token amount
     * @param _initialToken The token to be swapped with
     * @param _finalToken The token to be swapped for
     * @param _amount initial token balance amount
     * @return equivalent initial token balance in final token value
     */
    function _getSwapTokenAmount(
        address _initialToken,
        address _finalToken,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256[] memory _swapAmounts = IUniswapV2Router02(uniswapV2Router02).getAmountsOut(
            _amount,
            _getPath(_initialToken, _finalToken)
        );
        return _swapAmounts[_swapAmounts.length - 1];
    }

    /**
     * @dev Estimate the amount of tokens minted on a deposit
     * @param _poolData The pool data
     * @param _coinRefAmount Coin reference amount to deposit
     * @return Returns the expected amount of tokens minted
     */
    function _calcCoinRefDepositAmount(PoolData memory _poolData, uint256 _coinRefAmount)
        internal
        view
        returns (uint256)
    {
        DepositInfo memory _depositInfo = _getDepositInfo(_poolData);
        if (_depositInfo.coinsAmount == 2) {
            uint256[2] memory _amounts;
            _amounts[_depositInfo.coinRefIndex] = _coinRefAmount;
            return ICurveStableSwap2(_depositInfo.destination).calc_token_amount(_amounts, true);
        } else if (_depositInfo.coinsAmount == 3) {
            uint256[3] memory _amounts;
            _amounts[_depositInfo.coinRefIndex] = _coinRefAmount;
            return ICurveStableSwap3(_depositInfo.destination).calc_token_amount(_amounts, true);
        } else if (_depositInfo.coinsAmount == 4) {
            uint256[4] memory _amounts;
            _amounts[_depositInfo.coinRefIndex] = _coinRefAmount;
            return ICurveStableSwap4(_depositInfo.destination).calc_token_amount(_amounts, true);
        }
    }

    /**
     * @dev Get the codes for harvesting the tokens using uniswap router
     * @param _vault Vault contract address
     * @param _rewardToken Reward token address
     * @param _liquidityPool Liquidity pool's contract address
     * @param _rewardTokenAmount reward token amount to harvest
     * @return _codes List of harvest codes for harvesting reward tokens
     */
    function _getHarvestCodes(
        address payable _vault,
        address _rewardToken,
        address _liquidityPool,
        uint256 _rewardTokenAmount
    ) internal view returns (bytes[] memory _codes) {
        if (_rewardTokenAmount > 0) {
            PoolData memory _poolData = lpTokenToPoolData[_liquidityPool];
            DepositInfo memory _depositInfo = _getDepositInfo(_poolData);
            uint256 _swapTokenAmount = _getSwapTokenAmount(_rewardToken, _depositInfo.coinRef, _rewardTokenAmount);
            if (_swapTokenAmount > 0) {
                _codes = new bytes[](4);
                _codes[0] = abi.encode(
                    _rewardToken,
                    abi.encodeWithSignature("approve(address,uint256)", uniswapV2Router02, _rewardTokenAmount)
                );
                _codes[1] = abi.encode(
                    uniswapV2Router02,
                    abi.encodeWithSignature(
                        "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                        _rewardTokenAmount,
                        uint256(0),
                        _getPath(_rewardToken, _depositInfo.coinRef),
                        _vault,
                        uint256(-1)
                    )
                );
                bytes[] memory _addLiquidityCodes = _getAddLiquidityCodes(_liquidityPool, _swapTokenAmount);
                _codes[2] = _addLiquidityCodes[0];
                _codes[3] = _addLiquidityCodes[1];
            }
        }
    }

    /**
     * @dev Get the codes for adding liquidity
     * @param _liquidityPool Liquidity pool's contract address
     * @param _coinRefAmount Coin reference amount to add as liquidity
     * @return _codes List of codes for adding liquidity
     */
    function _getAddLiquidityCodes(address _liquidityPool, uint256 _coinRefAmount)
        internal
        view
        returns (bytes[] memory _codes)
    {
        if (_coinRefAmount > 0) {
            _codes = new bytes[](2);
            PoolData memory _poolData = lpTokenToPoolData[_liquidityPool];
            DepositInfo memory _depositInfo = _getDepositInfo(_poolData);
            _codes[0] = abi.encode(
                _depositInfo.coinRef,
                abi.encodeWithSignature("approve(address,uint256)", _depositInfo.destination, _coinRefAmount)
            );
            if (_depositInfo.coinsAmount == 2) {
                uint256[2] memory _amounts;
                _amounts[_depositInfo.coinRefIndex] = _coinRefAmount;
                _codes[1] = abi.encode(
                    _depositInfo.destination,
                    abi.encodeWithSignature("add_liquidity(uint256[2],uint256)", _amounts, uint256(0))
                );
            } else if (_depositInfo.coinsAmount == 3) {
                uint256[3] memory _amounts;
                _amounts[_depositInfo.coinRefIndex] = _coinRefAmount;
                _codes[1] = abi.encode(
                    _depositInfo.destination,
                    abi.encodeWithSignature("add_liquidity(uint256[3],uint256)", _amounts, uint256(0))
                );
            } else if (_depositInfo.coinsAmount == 4) {
                uint256[4] memory _amounts;
                _amounts[_depositInfo.coinRefIndex] = _coinRefAmount;
                _codes[1] = abi.encode(
                    _depositInfo.destination,
                    abi.encodeWithSignature("add_liquidity(uint256[4],uint256)", _amounts, uint256(0))
                );
            }
        }
    }

    /**
     * @dev Get the info needed to interact with Curve's StableSwap or DepositZap contract
     * @param _poolData The pool data
     * @return Returns the deposit address and the amount of coins
     */
    function _getDepositInfo(PoolData memory _poolData) internal view returns (DepositInfo memory) {
        PoolCoinData memory _poolCoinData = swapToPoolCoinData[_poolData.swap];
        // By default use zap address as deposit address and the underlying coins
        DepositInfo memory _depositInfo = DepositInfo({
            destination: _poolData.zap,
            coinsAmount: _poolCoinData.underlyingCoins.length,
            coinRef: _poolCoinData.underlyingCoinRef,
            coinRefIndex: _poolCoinData.underlyingCoinRefIndex
        });
        // If zap address is empty -> use swap address and coins
        if (_depositInfo.destination == address(0)) {
            _depositInfo.destination = _poolData.swap;
            _depositInfo.coinsAmount = _poolCoinData.coins.length;
            _depositInfo.coinRef = _poolCoinData.coinRef;
            _depositInfo.coinRefIndex = _poolCoinData.coinRefIndex;
        }
        return _depositInfo;
    }

    /**
     * @dev Constructs the path for token swap on Uniswap
     * @param _initialToken The token to be swapped with
     * @param _finalToken The token to be swapped for
     * @return _path The array of tokens in the sequence to be swapped for
     */
    function _getPath(address _initialToken, address _finalToken) internal pure returns (address[] memory _path) {
        require(_initialToken != address(0), "_initialToken");
        require(_finalToken != address(0), "_finalToken");
        address _weth = IUniswapV2Router02(uniswapV2Router02).WETH();
        _path = new address[](3);
        _path[0] = _initialToken;
        _path[1] = _weth;
        _path[2] = _finalToken;
    }

    /**
     * @dev Get the pool information
     * @param _liquidityPool Liquidity pool's contract address
     * @return Returns the pool information
     */
    function _getPoolInfo(address _liquidityPool) internal view returns (IConvexDeposit.PoolInfo memory) {
        uint256 _pid = lpTokenToPoolData[_liquidityPool].id;
        return IConvexDeposit(BOOSTER_DEPOSIT_POOL).poolInfo(_pid);
    }
}
