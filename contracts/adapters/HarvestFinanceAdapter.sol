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
import { IHarvestDeposit } from "../interfaces/harvest.finance/IHarvestDeposit.sol";
import { IHarvestFarm } from "../interfaces/harvest.finance/IHarvestFarm.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAdapter } from "../interfaces/opty/defiAdapters/IAdapter.sol";
import { IAdapterHarvestReward } from "../interfaces/opty/defiAdapters/IAdapterHarvestReward.sol";
import { IAdapterStaking } from "../interfaces/opty/defiAdapters/IAdapterStaking.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @title Adapter for Harvest.finance protocol
 * @author Opty.fi
 * @dev Abstraction layer to harvest finance's pools
 */

contract HarvestFinanceAdapter is IAdapter, IAdapterHarvestReward, IAdapterStaking {
    using SafeMath for uint256;

    /** @notice Maps liquidityPool to staking vault */
    mapping(address => address) public liquidityPoolToStakingVault;

    /**
     * @notice Uniswap V2 router contract address
     */
    address public constant uniswapV2Router02 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    // deposit pools
    address public constant TBTC_SBTC_CRV_DEPOSIT_POOL = address(0x640704D106E79e105FDA424f05467F005418F1B5);
    address public constant THREE_CRV_DEPOSIT_POOL = address(0x71B9eC42bB3CB40F017D8AD8011BE8e384a95fa5);
    address public constant YDAI_YUSDC_YUSDT_YTUSD_DEPOSIT_POOL = address(0x0FE4283e0216F94f5f9750a7a11AC54D3c9C38F3);
    address public constant F_DAI_DEPOSIT_POOL = address(0xab7FA2B2985BCcfC13c6D86b1D5A17486ab1e04C);
    address public constant F_USDC_DEPOSIT_POOL = address(0xf0358e8c3CD5Fa238a29301d0bEa3D63A17bEdBE);
    address public constant F_USDT_DEPOSIT_POOL = address(0x053c80eA73Dc6941F518a68E2FC52Ac45BDE7c9C);
    address public constant F_TUSD_DEPOSIT_POOL = address(0x7674622c63Bee7F46E86a4A5A18976693D54441b);
    address public constant F_CRV_REN_WBTC_DEPOSIT_POOL = address(0x9aA8F427A17d6B0d91B6262989EdC7D45d6aEdf8);
    address public constant F_WBTC_DEPOSIT_POOL = address(0x5d9d25c7C457dD82fc8668FFC6B9746b674d4EcB);
    address public constant F_RENBTC_DEPOSIT_POOL = address(0xC391d1b08c1403313B0c28D47202DFDA015633C4);
    address public constant F_WETH_DEPOSIT_POOL = address(0xFE09e53A81Fe2808bc493ea64319109B5bAa573e);
    address public constant F_CDAI_CUSDC_DEPOSIT_POOL = address(0x998cEb152A42a3EaC1f555B1E911642BeBf00faD);
    address public constant F_USDN_THREE_CRV_DEPOSIT_POOL = address(0x683E683fBE6Cf9b635539712c999f3B3EdCB8664);
    address public constant F_YDAI_YUSDC_YUSDT_YBUSD_DEPOSIT_POOL = address(0x4b1cBD6F6D8676AcE5E412C78B7a59b4A1bbb68a);

    // staking vaults
    address public constant TBTC_SBTC_CRV_STAKE_VAULT = address(0x017eC1772A45d2cf68c429A820eF374f0662C57c);
    address public constant THREE_CRV_STAKE_VAULT = address(0x27F12d1a08454402175b9F0b53769783578Be7d9);
    address public constant YDAI_YUSDC_YUSDT_YTUSD_STAKE_VAULT = address(0x6D1b6Ea108AA03c6993d8010690264BA96D349A8);
    address public constant F_DAI_STAKE_VAULT = address(0x15d3A64B2d5ab9E152F16593Cdebc4bB165B5B4A);
    address public constant F_USDC_STAKE_VAULT = address(0x4F7c28cCb0F1Dbd1388209C67eEc234273C878Bd);
    address public constant F_USDT_STAKE_VAULT = address(0x6ac4a7AB91E6fD098E13B7d347c6d4d1494994a2);
    address public constant F_TUSD_STAKE_VAULT = address(0xeC56a21CF0D7FeB93C25587C12bFfe094aa0eCdA);
    address public constant F_CRV_RENBTC_STAKE_VAULT = address(0xA3Cf8D1CEe996253FAD1F8e3d68BDCba7B3A3Db5);
    address public constant F_WBTC_STAKE_VAULT = address(0x917d6480Ec60cBddd6CbD0C8EA317Bcc709EA77B);
    address public constant F_RENBTC_STAKE_VAULT = address(0x7b8Ff8884590f44e10Ea8105730fe637Ce0cb4F6);
    address public constant F_WETH_STAKE_VAULT = address(0x3DA9D911301f8144bdF5c3c67886e5373DCdff8e);
    address public constant F_CDAI_CUSDC_STAKE_VAULT = address(0xC0f51a979e762202e9BeF0f62b07F600d0697DE1);
    address public constant F_USDN_THREE_CRV_STAKE_VAULT = address(0xef4Da1CE3f487DA2Ed0BE23173F76274E0D47579);
    address public constant F_YDAI_YUSDC_YUSDT_YBUSD_STAKE_VAULT = address(0x093C2ae5E6F3D2A897459aa24551289D462449AD);

    /** @notice Harvest.finance's reward token address */
    address public constant rewardToken = address(0xa0246c9032bC3A600820415aE600c6388619A14D);

    constructor() public {
        liquidityPoolToStakingVault[TBTC_SBTC_CRV_DEPOSIT_POOL] = TBTC_SBTC_CRV_STAKE_VAULT;
        liquidityPoolToStakingVault[THREE_CRV_DEPOSIT_POOL] = THREE_CRV_STAKE_VAULT;
        liquidityPoolToStakingVault[YDAI_YUSDC_YUSDT_YTUSD_DEPOSIT_POOL] = YDAI_YUSDC_YUSDT_YTUSD_STAKE_VAULT;
        liquidityPoolToStakingVault[F_DAI_DEPOSIT_POOL] = F_DAI_STAKE_VAULT;
        liquidityPoolToStakingVault[F_USDC_DEPOSIT_POOL] = F_USDC_STAKE_VAULT;
        liquidityPoolToStakingVault[F_USDT_DEPOSIT_POOL] = F_USDT_STAKE_VAULT;
        liquidityPoolToStakingVault[F_TUSD_DEPOSIT_POOL] = F_TUSD_STAKE_VAULT;
        liquidityPoolToStakingVault[F_CRV_REN_WBTC_DEPOSIT_POOL] = F_CRV_RENBTC_STAKE_VAULT;
        liquidityPoolToStakingVault[F_WBTC_DEPOSIT_POOL] = F_WBTC_STAKE_VAULT;
        liquidityPoolToStakingVault[F_RENBTC_DEPOSIT_POOL] = F_RENBTC_STAKE_VAULT;
        liquidityPoolToStakingVault[F_WETH_DEPOSIT_POOL] = F_WETH_STAKE_VAULT;
        liquidityPoolToStakingVault[F_CDAI_CUSDC_DEPOSIT_POOL] = F_CDAI_CUSDC_STAKE_VAULT;
        liquidityPoolToStakingVault[F_USDN_THREE_CRV_DEPOSIT_POOL] = F_USDN_THREE_CRV_STAKE_VAULT;
        liquidityPoolToStakingVault[F_YDAI_YUSDC_YUSDT_YBUSD_DEPOSIT_POOL] = F_YDAI_YUSDC_YUSDT_YBUSD_STAKE_VAULT;
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
        _underlyingTokens[0] = IHarvestDeposit(_liquidityPool).underlying();
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
            _depositAmount.mul(10**IHarvestDeposit(_liquidityPool).decimals()).div(
                IHarvestDeposit(_liquidityPool).getPricePerFullShare()
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
    function getClaimRewardTokenCode(address payable, address _liquidityPool)
        public
        view
        override
        returns (bytes[] memory _codes)
    {
        address _stakingVault = liquidityPoolToStakingVault[_liquidityPool];
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
        address _stakingVault = liquidityPoolToStakingVault[_liquidityPool];
        uint256 _liquidityPoolTokenBalance = IHarvestFarm(_stakingVault).balanceOf(_vault);
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
            );
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
                getLiquidityPoolToken(_underlyingTokens[0], _liquidityPool),
                abi.encodeWithSignature("withdraw(uint256)", _shares)
            );
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getPoolValue(address _liquidityPool, address) public view override returns (uint256) {
        return IHarvestDeposit(_liquidityPool).underlyingBalanceWithInvestment();
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
        address,
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
                .mul(IHarvestDeposit(_liquidityPool).getPricePerFullShare())
                .div(10**IHarvestDeposit(_liquidityPool).decimals());
        }
        return _liquidityPoolTokenAmount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getRewardToken(address) public view override returns (address) {
        return rewardToken;
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getUnclaimedRewardTokenAmount(
        address payable _vault,
        address _liquidityPool,
        address
    ) public view override returns (uint256) {
        return IHarvestFarm(liquidityPoolToStakingVault[_liquidityPool]).earned(_vault);
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
            address _stakingVault = liquidityPoolToStakingVault[_liquidityPool];
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
        uint256 b = IHarvestFarm(_stakingVault).balanceOf(_vault);
        if (b > 0) {
            b = b.mul(IHarvestDeposit(_liquidityPool).getPricePerFullShare()).div(1e18);
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
        return IHarvestFarm(_stakingVault).balanceOf(_vault);
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
}
