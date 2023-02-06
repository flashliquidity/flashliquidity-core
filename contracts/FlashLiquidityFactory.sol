pragma solidity =0.5.16;

import './interfaces/IFlashLiquidityFactory.sol';
import './interfaces/IERC20.sol';
import './FlashLiquidityPair.sol';

contract FlashLiquidityFactory is IFlashLiquidityFactory {
    address public feeTo;
    address public feeToSetter;
    address public pairManagerSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter,address _pairManagerSetter) public {
        feeToSetter = _feeToSetter;
        pairManagerSetter = _pairManagerSetter;
    }
    
    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(FlashLiquidityPair).creationCode);
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'PAIR_EXISTS'); // single check is sufficient
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
        require(msg.sender == feeToSetter, 'FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
    
    function setPairManager(address _pair, address _manager) external {
        require(msg.sender == pairManagerSetter, 'FORBIDDEN');
        IFlashLiquidityPair(_pair).setManager(_manager);
    }

    function setPairManagerSetter(address _pairManagerSetter) external {
        require(msg.sender == pairManagerSetter, 'FORBIDDEN');
        pairManagerSetter = _pairManagerSetter;
    }
}
