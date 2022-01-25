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
import { ILidoDeposit } from "@optyfi/defi-legos/ethereum/lido/contracts/ILidoDeposit.sol";
import { ICurveETHSwapV1 } from "@optyfi/defi-legos/ethereum/curve/contracts/ICurveETHSwapV1.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWETH9 } from "../../utils/interfaces/IWETH9.sol";

contract LidoEthGateway {
    using SafeMath for uint256;

    /**
     * @notice Wrapped Ether token
     * @dev https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code
     */
    IWETH9 public constant WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /**
     * @notice Pool used to swap between ETH and stETH (direct withdraw from Lido contract is not possible yet)
     * @dev https://github.com/curvefi/curve-contract/tree/master/contracts/pools/steth
     */
    ICurveETHSwapV1 public constant curveStableSwapStEth = ICurveETHSwapV1(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

    /**
     * @notice Optional address used as referral on deposit
     */
    address public constant referralAddress = address(0xF75Ad89a40909FA0592e96899E038afa8f8B2BaE);

    function depositETH(
        address _vault,
        address _liquidityPool,
        uint256 _amount
    ) external {
        // Moves WETH from the vault to this gateway. The amount has to be approved first.
        IERC20(address(WETH)).transferFrom(_vault, address(this), _amount);
        // Converts WETH to ETH
        WETH.withdraw(_amount);
        // Adds ETH to the Lido pool
        ILidoDeposit(_liquidityPool).submit{ value: address(this).balance }(referralAddress);
        // Moves LP token from this gateway to the vault.
        IERC20(_liquidityPool).transfer(_vault, IERC20(_liquidityPool).balanceOf(address(this)));
    }

    function withdrawETH(
        address _vault,
        address _liquidityPool,
        uint256 _amount
    ) external {
        // Moves LP tokens from the vault to this gateway. The amount has to be approved first.
        IERC20(_liquidityPool).transferFrom(_vault, address(this), _amount);
        // Approves Curve to spend LP tokens
        IERC20(_liquidityPool).approve(address(curveStableSwapStEth), _amount);

        // Performs an exchange from StETH to ETH
        curveStableSwapStEth.exchange(
            int128(1),
            int128(0),
            IERC20(_liquidityPool).balanceOf(address(this)),
            uint256(0)
        );
        // Converts ETH to WETH
        WETH.deposit{ value: address(this).balance }();
        // Moves WETH from this gateway to the vault.
        IERC20(address(WETH)).transfer(_vault, IERC20(address(WETH)).balanceOf(address(this)));
    }

    /**
     * @dev Calculate the minimum amount to receive after swap (assuming ETH & stETH are traded 1:1)
     * @param _amount The amount of tokens to swap
     * @return Returns the minimum amount to receive after swap
     */
    function calculateMinAmountAfterSwap(uint256 _amount) public pure returns (uint256) {
        if (_amount > 0) {
            uint256 slippage = _amount.mul(9).div(1000); // 0.9%
            _amount = _amount.sub(slippage);
        }
        return _amount;
    }

    /* solhint-disable no-empty-blocks */
    receive() external payable {}
    /* solhint-enable no-empty-blocks */
}
