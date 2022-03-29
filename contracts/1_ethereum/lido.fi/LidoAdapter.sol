// SPDX-License-Identifier: agpl-3.0

pragma solidity =0.8.11;

//  libraries
import { Address } from "@openzeppelin/contracts-0.8.x/utils/Address.sol";

//  helper contracts
import { LidoEthGateway } from "./LidoEthGateway.sol";
import { AdapterModifiersBase } from "../../utils/AdapterModifiersBase.sol";

//  interfaces
import { ILidoDeposit } from "@optyfi/defi-legos/ethereum/lido/contracts/ILidoDeposit.sol";
import { IERC20 } from "@openzeppelin/contracts-0.8.x/token/ERC20/IERC20.sol";
import { IAdapter } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapter.sol";
import "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterInvestLimit.sol";

/**
 * @title Adapter for Lido protocol
 * @author niklr
 * @dev Abstraction layer to lido's pools
 */

contract LidoAdapter is IAdapter, IAdapterInvestLimit, AdapterModifiersBase {
    using Address for address;

    /** @notice max deposit value datatypes */
    MaxExposure public maxDepositProtocolMode;

    /**
     * @notice Wrapped Ether token
     * @dev https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code
     */
    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // Address of deployed LidoEthGateway contract
    address public gateway;

    /** @notice max deposit's protocol value in percentage */
    uint256 public maxDepositProtocolPct; // basis points

    /** @notice  Maps liquidityPool to max deposit value in percentage */
    mapping(address => uint256) public maxDepositPoolPct; // basis points

    /** @notice  Maps liquidityPool to max deposit value in absolute value for a specific token */
    mapping(address => mapping(address => uint256)) public maxDepositAmount;

    constructor(address _registry) AdapterModifiersBase(_registry) {
        maxDepositProtocolPct = uint256(10000); // 100%
        maxDepositProtocolMode = MaxExposure.Pct;
        gateway = address(new LidoEthGateway());
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositPoolPct(address _underlyingToken, uint256 _maxDepositPoolPct)
        external
        override
        onlyRiskOperator
    {
        maxDepositPoolPct[_underlyingToken] = _maxDepositPoolPct;
        emit LogMaxDepositPoolPct(maxDepositPoolPct[_underlyingToken], msg.sender);
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositAmount(
        address _liquidityPool,
        address _underlyingToken,
        uint256 _maxDepositAmount
    ) external override onlyRiskOperator {
        maxDepositAmount[_liquidityPool][_underlyingToken] = _maxDepositAmount;
        emit LogMaxDepositAmount(maxDepositAmount[_liquidityPool][_underlyingToken], msg.sender);
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
        address,
        address _liquidityPool
    ) public view override returns (bytes[] memory _codes) {
        uint256 _redeemAmount = getLiquidityPoolTokenBalance(_vault, address(0), _liquidityPool);
        return getWithdrawSomeCodes(_vault, address(0), _liquidityPool, _redeemAmount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getUnderlyingTokens(address, address) public pure override returns (address[] memory _underlyingTokens) {
        _underlyingTokens = new address[](1);
        _underlyingTokens[0] = WETH;
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateAmountInLPToken(
        address,
        address _liquidityPool,
        uint256 _depositAmount
    ) public view override returns (uint256) {
        return ILidoDeposit(_liquidityPool).getSharesByPooledEth(_depositAmount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateRedeemableLPTokenAmount(
        address payable, // solhint-disable-line no-unused-vars
        address,
        address _liquidityPool,
        uint256 _redeemAmount
    ) public view override returns (uint256 _amount) {
        return ILidoDeposit(_liquidityPool).getPooledEthByShares(_redeemAmount);
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
     * @inheritdoc IAdapter
     */
    function canStake(address) public pure override returns (bool) {
        return false;
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositProtocolMode(MaxExposure _mode) public override onlyRiskOperator {
        maxDepositProtocolMode = _mode;
        emit LogMaxDepositProtocolMode(maxDepositProtocolMode, msg.sender);
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositProtocolPct(uint256 _maxDepositProtocolPct) public override onlyRiskOperator {
        maxDepositProtocolPct = _maxDepositProtocolPct;
        emit LogMaxDepositProtocolPct(maxDepositProtocolPct, msg.sender);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getDepositSomeCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _amount
    ) public view override returns (bytes[] memory _codes) {
        uint256 _depositAmount = _getDepositAmount(_liquidityPool, _underlyingToken, _amount);
        if (_depositAmount > 0) {
            _codes = new bytes[](2);
            _codes[0] = abi.encode(WETH, abi.encodeWithSignature("approve(address,uint256)", gateway, _depositAmount));
            _codes[1] = abi.encode(
                gateway,
                abi.encodeWithSignature("depositETH(address,address,uint256)", _vault, _liquidityPool, _depositAmount)
            );
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawSomeCodes(
        address payable _vault,
        address,
        address _liquidityPool,
        uint256 _amount
    ) public view override returns (bytes[] memory _codes) {
        if (_amount > 0) {
            _codes = new bytes[](2);
            _codes[0] = abi.encode(
                _liquidityPool,
                abi.encodeWithSignature("approve(address,uint256)", gateway, _amount)
            );
            _codes[1] = abi.encode(
                gateway,
                abi.encodeWithSignature("withdrawETH(address,address,uint256)", _vault, _liquidityPool, _amount)
            );
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getPoolValue(address _liquidityPool, address) public view override returns (uint256) {
        return IERC20(_liquidityPool).totalSupply();
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolToken(address, address _liquidityPool) public pure override returns (address) {
        return _liquidityPool;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getAllAmountInToken(
        address payable _vault,
        address,
        address _liquidityPool
    ) public view override returns (uint256) {
        return
            getSomeAmountInToken(
                address(0),
                _liquidityPool,
                getLiquidityPoolTokenBalance(_vault, address(0), _liquidityPool)
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
        return ILidoDeposit(_liquidityPool).sharesOf(_vault);
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
            // getPooledEthByShares = shares[account] * _getTotalPooledEther() / _getTotalShares()
            _liquidityPoolTokenAmount = ILidoDeposit(_liquidityPool).getPooledEthByShares(_liquidityPoolTokenAmount);
        }
        return _liquidityPoolTokenAmount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getRewardToken(address) public pure override returns (address) {
        return address(0);
    }

    function _getDepositAmount(
        address _liquidityPool,
        address _underlyingToken,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 _limit = maxDepositProtocolMode == MaxExposure.Pct
            ? _getMaxDepositAmountByPct(_liquidityPool)
            : maxDepositAmount[_liquidityPool][_underlyingToken];
        return _amount > _limit ? _limit : _amount;
    }

    function _getMaxDepositAmountByPct(address _liquidityPool) internal view returns (uint256) {
        uint256 _poolValue = getPoolValue(_liquidityPool, address(0));
        uint256 _poolPct = maxDepositPoolPct[_liquidityPool];
        uint256 _limit = _poolPct == 0
            ? (_poolValue * maxDepositProtocolPct) / (uint256(10000))
            : (_poolValue * _poolPct) / (uint256(10000));
        return _limit;
    }
}
