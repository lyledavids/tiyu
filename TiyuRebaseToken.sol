pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./SafeMathInt.sol";

contract RebaseToken {
    string public name = "Rebase Token";
    string public symbol = "RT";
    address owner_;

    using SafeMath for uint256;
    using SafeMathInt for int256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = type(uint256).max;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 50 * 10 ** 6 * 10 ** DECIMALS;

    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant MAX_SUPPLY = type(uint128).max; // (2^128) - 1

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    mapping(address => mapping(address => uint256)) private _allowedFragments;

    modifier onlyOwner() {
        require(msg.sender == owner_,"It's not use by owner.");
        _;
    }

    constructor() public  {
        owner_ = msg.sender;
    }

    function initialize() public onlyOwner {

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[owner_] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        emit Transfer(address(0x0), owner_, _totalSupply);
    }

    function rebase(uint256 epoch, int256 supplyDelta)
            external
            onlyOwner
            returns (uint256)
        {
            if (supplyDelta == 0) {
                emit LogRebase(epoch, _totalSupply);
                return _totalSupply;
            }

            if (supplyDelta < 0) {
                _totalSupply = _totalSupply.sub(uint256(supplyDelta.abs()));
            } else {
                _totalSupply = _totalSupply.add(uint256(supplyDelta));
            }

            if (_totalSupply > MAX_SUPPLY) {
                _totalSupply = MAX_SUPPLY;
            }

            _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) external view  returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function scaledBalanceOf(address who) external view returns (uint256) {
        return _gonBalances[who];
    }

    function scaledTotalSupply() external pure returns (uint256) {
        return TOTAL_GONS;
    }

    function transfer(address to, uint256 value)
        external
        returns (bool)
    {
        uint256 gonValue = value.mul(_gonsPerFragment);

        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external  returns (bool) {

        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);

        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external  returns (bool) {
        _allowedFragments[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }
    
}
