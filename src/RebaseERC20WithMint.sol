// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RebaseERC20WithMint is ERC20 {
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event Debug(string message, uint256);

    uint256 public constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = type(uint256).max;
    uint256 private constant INITIAL_TOTAL_SUPPLY = 1;

    // TOTAL_BASE_UNITS is a multiple of INITIAL_TOTAL_SUPPLY so that _baseUnitsPerSupply is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private TOTAL_BASE_UNITS =
        MAX_UINT256 - (MAX_UINT256 % INITIAL_TOTAL_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_BASE_UNITS + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = type(uint128).max; // (2^128) - 1

    uint256 private _totalSupply;
    uint256 private _baseUnitsPerSupply;
    mapping(address => uint256) private _baseUnitBalances;

    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() ERC20("MyToken", "MTK") {  

        // Simulate minting total supply to msg.sender. 
        _totalSupply = INITIAL_TOTAL_SUPPLY;
        emit Debug("_totalSupply: ", _totalSupply);
        _baseUnitsPerSupply = TOTAL_BASE_UNITS / _totalSupply; 
        emit Debug("_baseUnitsPerSupply: ", _baseUnitsPerSupply);
        uint256 value = _totalSupply; 
        uint256 baseUnitValue = value * _baseUnitsPerSupply; 
        _baseUnitBalances[msg.sender] = baseUnitValue;
        emit Debug("Base Unit Value: ", baseUnitValue);

    }

    function mint(address to, uint256 value) public {
        require(to != address(0), "ERC20: mint to the zero address");

        uint256 baseUnitValue = value * _baseUnitsPerSupply; 
        emit Debug("Base Unit Value: ", baseUnitValue);
        // _beforeTokenTransfer(address(0), to, baseUnitValue);

        // _totalSupply += value;
        // _baseUnitBalances[to] = _baseUnitBalances[to] + baseUnitValue;

        // emit Transfer(address(0), to, value);

        // _afterTokenTransfer(address(0), to, baseUnitValue);
    }
    /**
     * @param supplyDelta The number of new tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase(uint256 epoch, int256 supplyDelta)
        external
        returns (uint256)
    {
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply - uint256(-supplyDelta);
        } else {
            _totalSupply = _totalSupply + uint256(supplyDelta);
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _baseUnitsPerSupply = TOTAL_BASE_UNITS / _totalSupply;

        // From this point forward, _baseUnitsPerSupply is taken as the source of truth.
        // We recalculate a new _totalSupply to be in agreement with the _baseUnitsPerSupply
        // conversion rate.
        // This means our applied supplyDelta can deviate from the requested supplyDelta,
        // but this deviation is guaranteed to be < (_totalSupply^2)/(TOTAL_BASE_UNITS - _totalSupply).
        //
        // In the case of _totalSupply <= MAX_UINT128 (our current supply cap), this
        // deviation is guaranteed to be < 1, so we can omit this step. If the supply cap is
        // ever increased, it must be re-included.
        // _totalSupply = TOTAL_BASE_UNITS / _baseUnitsPerSupply)

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    /**
     * @return The total number of fragments.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) public view override returns (uint256) {
        return _baseUnitBalances[who] / _baseUnitsPerSupply;
    }

    /**
     * @param who The address to query.
     * @return The baseUnit balance of the specified address.
     */
    function scaledBalanceOf(address who) external view returns (uint256) {
        return _baseUnitBalances[who];
    }

    /**
     * @return the total number of baseUnits.
     */
    function scaledTotalSupply() external view returns (uint256) {
        return TOTAL_BASE_UNITS;
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value)
        public
        override
        
        returns (bool)
    {
        uint256 baseUnitValue = value * _baseUnitsPerSupply;
        _baseUnitBalances[msg.sender] = _baseUnitBalances[msg.sender] - baseUnitValue;
        _baseUnitBalances[to] = _baseUnitBalances[to] + baseUnitValue;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Transfer all of the sender's wallet balance to a specified address.
     * @param to The address to transfer to.
     * @return True on success, false otherwise.
     */
    function transferAll(address to) external  returns (bool) {
        uint256 baseUnitValue = _baseUnitBalances[msg.sender];
        uint256 value = baseUnitValue / _baseUnitsPerSupply;

        delete _baseUnitBalances[msg.sender];
        _baseUnitBalances[to] = _baseUnitBalances[to] + baseUnitValue;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowances[owner_][spender];
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override  returns (bool) {
        _allowances[from][msg.sender] = _allowances[from][msg.sender] - value; // Did i introduce a bug here?

        uint256 baseUnitValue = value * _baseUnitsPerSupply;
        _baseUnitBalances[from] = _baseUnitBalances[from] - baseUnitValue;
        _baseUnitBalances[to] = _baseUnitBalances[to] + baseUnitValue;

        emit Transfer(from, to, value);
        return true;
    }

    /**
     * @dev Transfer all balance tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     */
    function transferAllFrom(address from, address to) external  returns (bool) {
        uint256 baseUnitValue = _baseUnitBalances[from];
        uint256 value = baseUnitValue / _baseUnitsPerSupply;

        _allowances[from][msg.sender] = _allowances[from][msg.sender] - value;

        delete _baseUnitBalances[from];
        _baseUnitBalances[to] = _baseUnitBalances[to] + baseUnitValue;

        emit Transfer(from, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public override returns (bool) {
        _allowances[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        _allowances[msg.sender][spender] = _allowances[msg.sender][spender] + addedValue;

        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        uint256 oldValue = _allowances[msg.sender][spender];
        _allowances[msg.sender][spender] = (subtractedValue >= oldValue)
            ? 0
            : oldValue - subtractedValue;

        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }
}
