// SPDX-License-Identifier: MIT

// P1 - P3: OK
pragma solidity 0.6.12;


import "../interfaces/IFlashLiquidityERC20.sol";
import "../interfaces/IFlashLiquidityPair.sol";
import "../interfaces/IFlashLiquidityFactory.sol";
import "../../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "./Fliq.sol";

library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: TransferFrom failed");
    }
}

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

// T1 - T4: OK
contract OwnableData {
    // V1 - V5: OK
    address public owner;
    // V1 - V5: OK
    address public pendingOwner;
}

// T1 - T4: OK
contract Ownable is OwnableData {
    // E1: OK
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

interface IFlashBotSetter {
    function setFlashbot(address pair, address _flashBot) external;
    function setFlashbotSetter(address _flashbotSetter) external;
}

interface IFlashBotPair {
    function flashbot() external view returns (address);
}

contract Incentivizer is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable factory;
    address public immutable fliqWethStaking;
    address private immutable fliq;
    address private immutable weth;

    mapping(address => address) internal _bridges;

    event LogBridgeSet(address indexed token, address indexed bridge);
    event LogConvert(
        address indexed server,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1,
        uint256 amountFliqOut,
        uint256 amountFliqBurned
    );

    constructor(
        address _factory,
        address _fliqWethStaking,
        address _fliq,
        address _weth
    ) public {
        factory = _factory;
        fliqWethStaking = _fliqWethStaking;
        fliq = _fliq;
        weth = _weth;
    }

    function setFlashbotSetter(address _flashbotSetter) external onlyOwner {
        IFlashBotSetter(factory).setFlashbotSetter(_flashbotSetter);
    }

    function setFlashbot(address _pair, address _flashbot) external onlyOwner {
        IFlashBotSetter(factory).setFlashbot(_pair, _flashbot);
    }

    function bridgeFor(address token) public view returns (address bridge) {
        bridge = _bridges[token];
        if (bridge == address(0)) {
            bridge = weth;
        }
    }

    function setBridge(address token, address bridge) external onlyOwner {
        // Checks
        require(
            token != fliq && token != weth && token != bridge,
            "Incentivizer: Invalid bridge"
        );

        // Effects
        _bridges[token] = bridge;
        emit LogBridgeSet(token, bridge);
    }

    function convert(address token0, address token1) external onlyOwner {
        _convert(token0, token1);
    }

    function convertMultiple(
        address[] calldata token0,
        address[] calldata token1
    ) external onlyOwner {
        // TODO: This can be optimized a fair bit, but this is safer and simpler for now
        uint256 len = token0.length;
        for (uint256 i = 0; i < len; i++) {
            _convert(token0[i], token1[i]);
        }
    }

    function _convert(address token0, address token1) internal {
        IFlashLiquidityPair pair = IFlashLiquidityPair(
            IFlashLiquidityFactory(factory).getPair(token0, token1)
        );
        require(address(pair) != address(0), "Incentivizer: Invalid pair");
        IERC20(address(pair)).safeTransfer(
            address(pair),
            pair.balanceOf(address(this))
        );
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        if (token0 != pair.token0()) {
            (amount0, amount1) = (amount1, amount0);
        }

        (uint256 _fliqOut, uint256 _fliqBurned) = _convertStep(token0, token1, amount0, amount1);

        emit LogConvert(
            msg.sender,
            token0,
            token1,
            amount0,
            amount1,
            _fliqOut,
            _fliqBurned
        );
    }

    function _convertStep(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) internal returns (uint256 fliqOut, uint256 fliqBurned) {
        // Interactions
        if (token0 == token1) {
            uint256 amount = amount0.add(amount1);
            if (token0 == fliq) {
                FliqToken(fliq).burn(amount);
                fliqBurned = amount;
            } else if (token0 == weth) {
                fliqOut = _toFLIQ(weth, amount);
            } else {
                address bridge = bridgeFor(token0);
                amount = _swap(token0, bridge, amount, address(this));
                (fliqOut, fliqBurned) = _convertStep(bridge, bridge, amount, 0);
            }
        } else if (token0 == fliq) {
            // eg. SUSHI - ETH
            FliqToken(fliq).burn(amount0);
            fliqBurned = amount0;
            fliqOut = _toFLIQ(token1, amount1);
        } else if (token1 == fliq) {
            // eg. USDT - SUSHI
            FliqToken(fliq).burn(amount1);
            fliqBurned = amount1;
            fliqOut = _toFLIQ(token0, amount0);
        } else if (token0 == weth) {
            // eg. ETH - USDC
            fliqOut = _toFLIQ(
                weth,
                _swap(token1, weth, amount1, address(this)).add(amount0)
            );
        } else if (token1 == weth) {
            // eg. USDT - ETH
            fliqOut = _toFLIQ(
                weth,
                _swap(token0, weth, amount0, address(this)).add(amount1)
            );
        } else {
            // eg. MIC - USDT
            address bridge0 = bridgeFor(token0);
            address bridge1 = bridgeFor(token1);
            if (bridge0 == token1) {
                // eg. MIC - USDT - and bridgeFor(MIC) = USDT
                (fliqOut, fliqBurned) = _convertStep(
                    bridge0,
                    token1,
                    _swap(token0, bridge0, amount0, address(this)),
                    amount1
                );
            } else if (bridge1 == token0) {
                // eg. WBTC - DSD - and bridgeFor(DSD) = WBTC
                (fliqOut, fliqBurned) = _convertStep(
                    token0,
                    bridge1,
                    amount0,
                    _swap(token1, bridge1, amount1, address(this))
                );
            } else {
                (fliqOut, fliqBurned) = _convertStep(
                    bridge0,
                    bridge1, // eg. USDT - DSD - and bridgeFor(DSD) = WBTC
                    _swap(token0, bridge0, amount0, address(this)),
                    _swap(token1, bridge1, amount1, address(this))
                );
            }
        }
    }

    function _swap(
        address fromToken,
        address toToken,
        uint256 amountIn,
        address to
    ) internal returns (uint256 amountOut) {
        IFlashLiquidityPair pair = IFlashLiquidityPair(
            IFlashLiquidityFactory(factory).getPair(fromToken, toToken)
        );
        require(address(pair) != address(0), "Incentivizer: Cannot convert");
        
        address botAddr = IFlashBotPair(address(pair)).flashbot();
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 amountInWithFee = amountIn.mul(997);
        if (fromToken == pair.token0()) {
            amountOut =
                amountInWithFee.mul(reserve1) /
                reserve0.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            IFlashBotSetter(factory).setFlashbot(address(pair), address(this));
            pair.swap(0, amountOut, to, new bytes(0));
            IFlashBotSetter(factory).setFlashbot(address(pair), botAddr);
            // TODO: Add maximum slippage?
        } else {
            amountOut =
                amountInWithFee.mul(reserve0) /
                reserve1.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            IFlashBotSetter(factory).setFlashbot(address(pair), address(this));
            pair.swap(amountOut, 0, to, new bytes(0));
            IFlashBotSetter(factory).setFlashbot(address(pair), botAddr);
            // TODO: Add maximum slippage?
        }
    }

    function _toFLIQ(address token, uint256 amountIn)
        internal
        returns (uint256 amountOut)
    {
        amountOut = _swap(token, fliq, amountIn, fliqWethStaking);
    }
}