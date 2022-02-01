// solhint-disable no-unused-vars
// SPDX-License-Identifier: agpl-3.0

pragma solidity =0.8.11;

/////////////////////////////////////////////////////
/// PLEASE DO NOT USE THIS CONTRACT IN PRODUCTION ///
/////////////////////////////////////////////////////

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
     * @notice Lido and stETH token proxy
     * @dev https://github.com/lidofinance/lido-dao
     */
    address public constant lidoTokenProxy = address(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);

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
        //require(gateway != address(0), "Invalid gateway address");
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
        require(_underlyingToken.isContract(), "!isContract");
        maxDepositPoolPct[_underlyingToken] = _maxDepositPoolPct;
        emit LogMaxDepositPoolPct(maxDepositPoolPct[_underlyingToken], msg.sender);
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositAmount(
        address _miniChef,
        address _underlyingToken,
        uint256 _maxDepositAmount
    ) external override onlyRiskOperator {
        require(_miniChef.isContract(), "!_miniChef.isContract()");
        require(_underlyingToken.isContract(), "!_underlyingToken.isContract()");
        maxDepositAmount[_miniChef][_underlyingToken] = _maxDepositAmount;
        emit LogMaxDepositAmount(maxDepositAmount[_miniChef][_underlyingToken], msg.sender);
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
    function getUnderlyingTokens(address, address) public pure override returns (address[] memory _underlyingTokens) {
        _underlyingTokens = new address[](1);
        _underlyingTokens[0] = WETH;
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateAmountInLPToken(
        address,
        address,
        uint256 _depositAmount
    ) public view override returns (uint256) {
        return ILidoDeposit(lidoTokenProxy).getSharesByPooledEth(_depositAmount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateRedeemableLPTokenAmount(
        address payable,
        address,
        address,
        uint256 _redeemAmount
    ) public view override returns (uint256 _amount) {
        return ILidoDeposit(lidoTokenProxy).getPooledEthByShares(_redeemAmount);
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
        address,
        address,
        uint256 _amount
    ) public view override returns (bytes[] memory _codes) {
        if (_amount > 0) {
            _codes = new bytes[](2);
            _codes[0] = abi.encode(WETH, abi.encodeWithSignature("approve(address,uint256)", gateway, _amount));
            _codes[1] = abi.encode(
                gateway,
                abi.encodeWithSignature("depositETH(address,address,uint256)", _vault, lidoTokenProxy, _amount)
            );
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawSomeCodes(
        address payable _vault,
        address,
        address,
        uint256 _amount
    ) public view override returns (bytes[] memory _codes) {
        if (_amount > 0) {
            uint256 pooledEthAmount = ILidoDeposit(lidoTokenProxy).getPooledEthByShares(_amount);
            _codes = new bytes[](2);
            _codes[0] = abi.encode(
                lidoTokenProxy,
                abi.encodeWithSignature("approve(address,uint256)", gateway, pooledEthAmount)
            );
            _codes[1] = abi.encode(
                gateway,
                abi.encodeWithSignature("withdrawETH(address,address,uint256)", _vault, lidoTokenProxy, pooledEthAmount)
            );
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getPoolValue(address, address) public view override returns (uint256) {
        return IERC20(lidoTokenProxy).totalSupply();
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolToken(address, address) public pure override returns (address) {
        return lidoTokenProxy;
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
        address
    ) public view override returns (uint256) {
        return ILidoDeposit(lidoTokenProxy).sharesOf(_vault);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getSomeAmountInToken(
        address,
        address,
        uint256 _liquidityPoolTokenAmount
    ) public view override returns (uint256) {
        if (_liquidityPoolTokenAmount > 0) {
            // getPooledEthByShares = shares[account] * _getTotalPooledEther() / _getTotalShares()
            _liquidityPoolTokenAmount = ILidoDeposit(lidoTokenProxy).getPooledEthByShares(_liquidityPoolTokenAmount);
        }
        return _liquidityPoolTokenAmount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getRewardToken(address) public pure override returns (address) {
        return address(0);
    }
}
