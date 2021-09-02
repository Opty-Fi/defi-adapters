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
import { IBeefyDeposit } from "../interfaces/beefy.finance/IBeefyDeposit.sol";
import { IBeefyFarm } from "../interfaces/beefy.finance/IBeefyFarm.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAdapter } from "../interfaces/opty/defiAdapters/IAdapter.sol";
import { IAdapterHarvestReward } from "../interfaces/opty/defiAdapters/IAdapterHarvestReward.sol";
import { IAdapterStaking } from "../interfaces/opty/defiAdapters/IAdapterStaking.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @title Adapter for Beefy.finance protocol
 * @author Opty.fi
 * @dev Abstraction layer to Beefy finance's pools
 */

contract BeefyFinanceAdapter is
    IAdapter,
    IAdapterHarvestReward,
    IAdapterStaking //REPLACE IAdapterHarvest..
{
    using SafeMath for uint256;

    /** @notice Maps liquidityPool to staking vault */
    mapping(address => address) public liquidityPoolToStakingVault;

    mapping(address => address) public stakingVaultToRewardToken;

    /**
     * @notice Uniswap V2 router contract address
     */
    address public constant quickswapV2Router02 = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff); //Quickswap Router on Polygon
    // One can deposit LP tokens into these pools on Beefy
    address public constant DAI_DEPOSIT_POOL = address(0x9B36ECeaC46B70ACfB7C2D6F3FD51aEa87C31018);
    address public constant USDC_DEPOSIT_POOL = address(0xE71f3C11D4535a7F8c5FB03FDA57899B2C9c721F);
    address public constant WETH_DEPOSIT_POOL = address(0x77276a7c9Ff3a6cbD334524d6F1f6219D039ac0E);
    address public constant WBTC_DEPOSIT_POOL = address(0xD3395577febc6AdaB25490a69955ebC47040766C);
    address public constant BIFI_DEPOSIT_POOL = address(0xfEcf784F48125ccb7d8855cdda7C5ED6b5024Cb3);

    // staking vaults
    address public constant BIFI_STAKE_VAULT = address(0xDeB0a777ba6f59C78c654B8c92F80238c8002DD2);
    address public constant MOO_POLYGON_BIFI_STAKE_VAULT = address(0x71a4449dD18177A1a19fEF671558964f10AF4be8);
    //there are no other active staking pools at the moment - the only thing you can stake is BIFI for MATIC

    address public constant BIFI = address(0xFbdd194376de19a88118e84E279b977f165d01b8);
    address public constant MATIC = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address public constant WATCH = address(0x09211Dc67f9fe98Fb7bBB91Be0ef05f4a12FA2b2);

    constructor() public {
        liquidityPoolToStakingVault[BIFI] = BIFI_STAKE_VAULT;
        liquidityPoolToStakingVault[BIFI_DEPOSIT_POOL] = MOO_POLYGON_BIFI_STAKE_VAULT;
        //these are the only two that are active right now

        stakingVaultToRewardToken[BIFI_STAKE_VAULT] = MATIC;
        stakingVaultToRewardToken[MOO_POLYGON_BIFI_STAKE_VAULT] = WATCH;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getDepositAllCodes(
        address payable _vault, //the address we're depositing from
        address[] memory _underlyingTokens, //address of the LP tokens we're depositing
        address _liquidityPool //address of the liquidity pool we're depositing to
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
        _underlyingTokens[0] = IBeefyDeposit(_liquidityPool).want();
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateAmountInLPToken(
        address,
        address _liquidityPool,
        uint256 _depositAmount
    ) public view override returns (uint256) {
        return
            _depositAmount.mul(10**IBeefyDeposit(_liquidityPool).decimals()).div(
                IBeefyDeposit(_liquidityPool).getPricePerFullShare()
            );
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
        _amount = (_liquidityPoolTokenBalance.mul(_redeemAmount)).div(_balanceInToken).add(1);
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
    //Claims reward from staking vault, in reward token
    function getClaimRewardTokenCode(address payable, address _liquidityPool)
        public
        view
        override
        returns (bytes[] memory _codes)
    {
        address _stakingVault = liquidityPoolToStakingVault[_liquidityPool];
        _codes = new bytes[](1);
        _codes[0] = abi.encode(_stakingVault, abi.encodeWithSignature("getReward()")); //BIFI vault does have a getReward() fn
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
    function canStake(address _address) public view override returns (bool) {
        if (_address == BIFI) return true;
        else return false;
        //this is the current situation - may change in future as staking vaults get added/activated
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
        address _stakingVault = liquidityPoolToStakingVault[_liquidityPool];
        uint256 _liquidityPoolTokenBalance = IBeefyFarm(_stakingVault).balanceOf(_vault);
        uint256 _balanceInToken = getAllAmountInTokenStake(_vault, _underlyingToken, _liquidityPool);
        // can have unintentional rounding errors
        _amount = (_liquidityPoolTokenBalance.mul(_redeemAmount)).div(_balanceInToken).add(1);
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
            _codes = new bytes[](3);
            _codes[0] = abi.encode(
                _underlyingTokens[0],
                abi.encodeWithSignature("approve(address,uint256)", _liquidityPool, uint256(0))
            ); //maybe there are two pools in case in some cases we wanted to deposit two tokens?
            _codes[1] = abi.encode(
                _underlyingTokens[0],
                abi.encodeWithSignature("approve(address,uint256)", _liquidityPool, _amounts[0])
            );
            _codes[2] = abi.encode(_liquidityPool, abi.encodeWithSignature("deposit(uint256)", _amounts[0]));
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawSomeCodes(
        address payable,
        address[] memory _underlyingTokens,
        address _liquidityPool,
        uint256 _shares
    ) public view override returns (bytes[] memory _codes) {
        if (_shares > 0) {
            _codes = new bytes[](1);
            _codes[0] = abi.encode(
                getLiquidityPoolToken(_underlyingTokens[0], _liquidityPool), //this fn just returns _liquidityPool - is here because we have to use the other input?
                abi.encodeWithSignature("withdraw(uint256)", _shares)
            );
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    //what's going on here? a way to get how many LP tokens user holds? Or TOTAL pool value? Why use IHarvestDeposit?
    function getPoolValue(address _liquidityPool, address) public view override returns (uint256) {
        return IBeefyDeposit(_liquidityPool).balance();
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolToken(address, address _liquidityPool) public view override returns (address) {
        return _liquidityPool;
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
        address, //WHAT IS THIS? Didn't even know you could do this...
        address _liquidityPool
    ) public view override returns (uint256) {
        return IERC20(_liquidityPool).balanceOf(_vault);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getSomeAmountInToken(
        address,
        address _liquidityPool,
        uint256 _liquidityPoolTokenAmount
    ) public view override returns (uint256) {
        if (_liquidityPoolTokenAmount > 0) {
            _liquidityPoolTokenAmount = _liquidityPoolTokenAmount
                .mul(IBeefyDeposit(_liquidityPool).getPricePerFullShare())
                .div(10**IBeefyDeposit(_liquidityPool).decimals());
        }
        return _liquidityPoolTokenAmount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getRewardToken(address _liquidityPool) public view override returns (address) {
        return stakingVaultToRewardToken[liquidityPoolToStakingVault[_liquidityPool]];
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getUnclaimedRewardTokenAmount(
        address payable _vault,
        address _liquidityPool,
        address
    ) public view override returns (uint256) {
        return IBeefyFarm(liquidityPoolToStakingVault[_liquidityPool]).earned(_vault); //this should work fine
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getHarvestSomeCodes(
        //what does this exactly do? and how is it different from claiming?
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
            address _stakingVault = liquidityPoolToStakingVault[_liquidityPool];
            address _liquidityPoolToken = getLiquidityPoolToken(address(0), _liquidityPool); //this will return BIFI if you put in BIFI
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
            // there is a stake(uint256) on the BeefyRewardPool, but it's amount not shares - material?
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
            address _stakingVault = liquidityPoolToStakingVault[_liquidityPool];
            _codes = new bytes[](1);
            _codes[0] = abi.encode(_stakingVault, abi.encodeWithSignature("withdraw(uint256)", _shares));
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
        address _stakingVault = liquidityPoolToStakingVault[_liquidityPool];
        address rewardToken = getRewardToken(_liquidityPool);
        uint256 b = IBeefyFarm(_stakingVault).balanceOf(_vault);
        if (b > 0) {
            b = b.mul(IBeefyDeposit(_liquidityPool).getPricePerFullShare()).div(
                10**IBeefyDeposit(_liquidityPool).decimals()
            );
        }
        uint256 _unclaimedReward = getUnclaimedRewardTokenAmount(_vault, _liquidityPool, _underlyingToken);
        if (_unclaimedReward > 0) {
            b = b.add(_getRewardBalanceInUnderlyingTokens(rewardToken, _underlyingToken, _unclaimedReward));
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
        address _stakingVault = liquidityPoolToStakingVault[_liquidityPool];
        return IBeefyFarm(_stakingVault).balanceOf(_vault);
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
            //it won't be possible to 'withdraw' from BIFI - this is the edge case here!
        }
    }

    /**
     * @dev Get the codes for harvesting the tokens using uniswap router - i.e. swapping back into the underlying
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
            uint256[] memory _amounts = IUniswapV2Router02(quickswapV2Router02).getAmountsOut(
                _rewardTokenAmount,
                _getPath(_rewardToken, _underlyingToken)
            );
            if (_amounts[_amounts.length - 1] > 0) {
                _codes = new bytes[](3);
                _codes[0] = abi.encode(
                    _rewardToken,
                    abi.encodeWithSignature("approve(address,uint256)", quickswapV2Router02, uint256(0))
                );
                _codes[1] = abi.encode(
                    _rewardToken,
                    abi.encodeWithSignature("approve(address,uint256)", quickswapV2Router02, _rewardTokenAmount)
                );
                _codes[2] = abi.encode(
                    quickswapV2Router02,
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
        address _weth = IUniswapV2Router02(quickswapV2Router02).WETH(); //not sure this will work on quickswap?
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
        uint256[] memory _amountsA = IUniswapV2Router02(quickswapV2Router02).getAmountsOut(
            _amount,
            _getPath(_rewardToken, _underlyingToken)
        );
        return _amountsA[_amountsA.length - 1];
    }
}
