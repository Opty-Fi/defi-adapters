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
import { IConvexDeposit } from "../interfaces/convex.finance/IConvexDeposit.sol";
import { IConvexStake } from "../interfaces/convex.finance/IConvexStake.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAdapter } from "../interfaces/opty/defiAdapters/IAdapter.sol";
import { IAdapterHarvestReward } from "../interfaces/opty/defiAdapters/IAdapterHarvestReward.sol";
import { IAdapterStaking } from "../interfaces/opty/defiAdapters/IAdapterStaking.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @title Adapter for Convex.finance protocol
 * @author niklr
 * @dev Abstraction layer to convex finance's pools.
 * We assume the pool data to have liquidityPoolToken and liquidityPool's address to be same.
 */

contract ConvexFinanceAdapter is IAdapter, IAdapterHarvestReward, IAdapterStaking {
    using SafeMath for uint256;

    /** @notice Maps liquidityPoolToken to poolIdentifier */
    mapping(address => uint256) public lpTokenToPoolId;

    /**
     * @notice Uniswap V2 router contract address
     */
    address public constant uniswapV2Router02 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

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
        lpTokenToPoolId[COMPOUND_LP_TOKEN] = 0;
        lpTokenToPoolId[USDT_LP_TOKEN] = 1;
        lpTokenToPoolId[YPOOL_LP_TOKEN] = 2;
        lpTokenToPoolId[BUSD_LP_TOKEN] = 3;
        lpTokenToPoolId[SUSD_LP_TOKEN] = 4;
        lpTokenToPoolId[PAX_LP_TOKEN] = 5;
        lpTokenToPoolId[REN_LP_TOKEN] = 6;
        lpTokenToPoolId[SBTC_LP_TOKEN] = 7;
        lpTokenToPoolId[HBTC_LP_TOKEN] = 8;
        lpTokenToPoolId[THREE_POOL_LP_TOKEN] = 9;
        lpTokenToPoolId[GUSD_LP_TOKEN] = 10;
        lpTokenToPoolId[HUSD_LP_TOKEN] = 11;
        lpTokenToPoolId[USDK_LP_TOKEN] = 12;
        lpTokenToPoolId[USDN_LP_TOKEN] = 13;
        lpTokenToPoolId[MUSD_LP_TOKEN] = 14;
        lpTokenToPoolId[RSV_LP_TOKEN] = 15;
        lpTokenToPoolId[TBTC_LP_TOKEN] = 16;
        lpTokenToPoolId[DUSD_LP_TOKEN] = 17;
        lpTokenToPoolId[PBTC_LP_TOKEN] = 18;
        lpTokenToPoolId[BBTC_LP_TOKEN] = 19;
        lpTokenToPoolId[OBTC_LP_TOKEN] = 20;
        lpTokenToPoolId[UST_LP_TOKEN] = 21;
        lpTokenToPoolId[EURS_LP_TOKEN] = 22;
        lpTokenToPoolId[SETH_LP_TOKEN] = 23;
        lpTokenToPoolId[AAVE_LP_TOKEN] = 24;
        lpTokenToPoolId[STETH_LP_TOKEN] = 25;
        lpTokenToPoolId[SAAVE_LP_TOKEN] = 26;
        lpTokenToPoolId[ANKRETH_LP_TOKEN] = 27;
        lpTokenToPoolId[USDP_LP_TOKEN] = 28;
        lpTokenToPoolId[IRONBANK_LP_TOKEN] = 29;
        lpTokenToPoolId[LINK_LP_TOKEN] = 30;
        lpTokenToPoolId[TUSD_LP_TOKEN] = 31;
        lpTokenToPoolId[FRAX_LP_TOKEN] = 32;
        lpTokenToPoolId[LUSD_LP_TOKEN] = 33;
        lpTokenToPoolId[BUSDVTWO__LP_TOKEN] = 34;
        lpTokenToPoolId[RETH_LP_TOKEN] = 35;
        lpTokenToPoolId[ALUSD_LP_TOKEN] = 36;
        lpTokenToPoolId[TRICRYPTO_LP_TOKEN] = 37;
        lpTokenToPoolId[TRICRYPTOTWO__LP_TOKEN] = 38;
        lpTokenToPoolId[EURT_LP_TOKEN] = 39;
        lpTokenToPoolId[MIM_LP_TOKEN] = 40;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getDepositAllCodes(
        address payable _vault,
        address[] memory _underlyingTokens,
        address _liquidityPool
    ) public view override returns (bytes[] memory _codes) {
        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = IERC20(_underlyingTokens[0]).balanceOf(_vault);
        return getDepositSomeCodes(_vault, _underlyingTokens, _liquidityPool, _amounts);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawAllCodes(
        address payable _vault,
        address[] memory _underlyingTokens,
        address _liquidityPool
    ) public view override returns (bytes[] memory _codes) {
        uint256 _redeemAmount = getLiquidityPoolTokenBalance(_vault, _underlyingTokens[0], _liquidityPool);
        return getWithdrawSomeCodes(_vault, _underlyingTokens, _liquidityPool, _redeemAmount);
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
        address[] memory _underlyingTokens,
        address _liquidityPool
    ) public view override returns (bytes[] memory _codes) {
        uint256 _depositAmount = getLiquidityPoolTokenBalance(_vault, _underlyingTokens[0], _liquidityPool);
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
        address[] memory _underlyingTokens,
        address _liquidityPool
    ) public view override returns (bytes[] memory _codes) {
        uint256 _unstakeAmount = getLiquidityPoolTokenBalanceStake(_vault, _liquidityPool);
        return getUnstakeAndWithdrawSomeCodes(_vault, _underlyingTokens, _liquidityPool, _unstakeAmount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getDepositSomeCodes(
        address payable,
        address[] memory _underlyingTokens,
        address _liquidityPool,
        uint256[] memory _amounts
    ) public view override returns (bytes[] memory _codes) {
        if (_amounts[0] > 0) {
            uint256 _pid = lpTokenToPoolId[_liquidityPool];
            _codes = new bytes[](3);
            _codes[0] = abi.encode(
                _underlyingTokens[0],
                abi.encodeWithSignature("approve(address,uint256)", BOOSTER_DEPOSIT_POOL, uint256(0))
            );
            _codes[1] = abi.encode(
                _underlyingTokens[0],
                abi.encodeWithSignature("approve(address,uint256)", BOOSTER_DEPOSIT_POOL, _amounts[0])
            );
            _codes[2] = abi.encode(
                BOOSTER_DEPOSIT_POOL,
                abi.encodeWithSignature("deposit(uint256,uint256,bool)", _pid, _amounts[0], false) // bool = stake
            );
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawSomeCodes(
        address payable,
        address[] memory,
        address _liquidityPool,
        uint256 _shares
    ) public view override returns (bytes[] memory _codes) {
        if (_shares > 0) {
            uint256 _pid = lpTokenToPoolId[_liquidityPool];
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
        return IERC20(poolInfo.lptoken).balanceOf(poolInfo.gauge);
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
        address _underlyingToken,
        address _liquidityPool,
        uint256 _rewardTokenAmount
    ) public view override returns (bytes[] memory _codes) {
        return _getHarvestCodes(_vault, getRewardToken(_liquidityPool), _underlyingToken, _rewardTokenAmount);
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
            _codes = new bytes[](3);
            _codes[0] = abi.encode(
                _liquidityPoolToken,
                abi.encodeWithSignature("approve(address,uint256)", _stakingVault, uint256(0))
            );
            _codes[1] = abi.encode(
                _liquidityPoolToken,
                abi.encodeWithSignature("approve(address,uint256)", _stakingVault, _shares)
            );
            _codes[2] = abi.encode(_stakingVault, abi.encodeWithSignature("stake(uint256)", _shares));
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
                _getRewardBalanceInUnderlyingTokens(getRewardToken(_liquidityPool), _underlyingToken, _unclaimedReward)
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
        address[] memory _underlyingTokens,
        address _liquidityPool,
        uint256 _redeemAmount
    ) public view override returns (bytes[] memory _codes) {
        if (_redeemAmount > 0) {
            _codes = new bytes[](2);
            _codes[0] = getUnstakeSomeCodes(_liquidityPool, _redeemAmount)[0];
            _codes[1] = getWithdrawSomeCodes(_vault, _underlyingTokens, _liquidityPool, _redeemAmount)[0];
        }
    }

    /**
     * @dev Get the codes for harvesting the tokens using uniswap router
     * @param _vault Vault contract address
     * @param _rewardToken Reward token address
     * @param _underlyingToken Token address acting as underlying Asset for the vault contract
     * @param _rewardTokenAmount reward token amount to harvest
     * @return _codes List of harvest codes for harvesting reward tokens
     */
    function _getHarvestCodes(
        address payable _vault,
        address _rewardToken,
        address _underlyingToken,
        uint256 _rewardTokenAmount
    ) internal view returns (bytes[] memory _codes) {
        if (_rewardTokenAmount > 0) {
            uint256[] memory _amounts = IUniswapV2Router02(uniswapV2Router02).getAmountsOut(
                _rewardTokenAmount,
                _getPath(_rewardToken, _underlyingToken)
            );
            if (_amounts[_amounts.length - 1] > 0) {
                _codes = new bytes[](3);
                _codes[0] = abi.encode(
                    _rewardToken,
                    abi.encodeWithSignature("approve(address,uint256)", uniswapV2Router02, uint256(0))
                );
                _codes[1] = abi.encode(
                    _rewardToken,
                    abi.encodeWithSignature("approve(address,uint256)", uniswapV2Router02, _rewardTokenAmount)
                );
                _codes[2] = abi.encode(
                    uniswapV2Router02,
                    abi.encodeWithSignature(
                        "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                        _rewardTokenAmount,
                        uint256(0),
                        _getPath(_rewardToken, _underlyingToken),
                        _vault,
                        uint256(-1)
                    )
                );
            }
        }
    }

    /**
     * @dev Constructs the path for token swap on Uniswap
     * @param _initialToken The token to be swapped with
     * @param _finalToken The token to be swapped for
     * @return _path The array of tokens in the sequence to be swapped for
     */
    function _getPath(address _initialToken, address _finalToken) internal pure returns (address[] memory _path) {
        address _weth = IUniswapV2Router02(uniswapV2Router02).WETH();
        if (_finalToken == _weth) {
            _path = new address[](2);
            _path[0] = _initialToken;
            _path[1] = _weth;
        } else if (_initialToken == _weth) {
            _path = new address[](2);
            _path[0] = _weth;
            _path[1] = _finalToken;
        } else {
            _path = new address[](3);
            _path[0] = _initialToken;
            _path[1] = _weth;
            _path[2] = _finalToken;
        }
    }

    /**
     * @dev Get the underlying token amount equivalent to reward token amount
     * @param _rewardToken Reward token address
     * @param _underlyingToken Token address acting as underlying Asset for the vault contract
     * @param _amount reward token balance amount
     * @return equivalent reward token balance in Underlying token value
     */
    function _getRewardBalanceInUnderlyingTokens(
        address _rewardToken,
        address _underlyingToken,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256[] memory _amountsA = IUniswapV2Router02(uniswapV2Router02).getAmountsOut(
            _amount,
            _getPath(_rewardToken, _underlyingToken)
        );
        return _amountsA[_amountsA.length - 1];
    }

    /**
     * @dev Get the pool information
     * @param _liquidityPool Liquidity pool's contract address
     * @return Returns the pool information
     */
    function _getPoolInfo(address _liquidityPool) internal view returns (IConvexDeposit.PoolInfo memory) {
        uint256 _pid = lpTokenToPoolId[_liquidityPool];
        return IConvexDeposit(BOOSTER_DEPOSIT_POOL).poolInfo(_pid);
    }
}
