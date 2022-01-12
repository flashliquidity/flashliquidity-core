pragma solidity =0.5.16;

import './interfaces/IFlashLiquidityFactory.sol';
import './interfaces/IERC20.sol';
import './FlashLiquidityPair.sol';

contract FlashLiquidityFactory is IFlashLiquidityFactory {
    address public feeTo;
    address public feeToSetter;
    address public flashbotSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter,address _flashbotSetter) public {
        feeToSetter = _feeToSetter;
        flashbotSetter = _flashbotSetter;
    }
    
    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(FlashLiquidityPair).creationCode);
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'FlashLiquidity: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'FlashLiquidity: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'FlashLiquidity: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(FlashLiquidityPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IFlashLiquidityPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'FlashLiquidity: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'FlashLiquidity: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
    
    function setFlashbot(address pair, address _flashBot) external {
        require(msg.sender == flashbotSetter, 'FlashLiquidity: FORBIDDEN');
        IFlashLiquidityPair(pair).setFlashbot(_flashBot);
    }

    function setFlashbotSetter(address _flashbotSetter) external {
        require(msg.sender == flashbotSetter, 'FlashLiquidity: FORBIDDEN');
        flashbotSetter = _flashbotSetter;
    }
}
