// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./Address.sol";
import "./ITRC20.sol";
import "./SafeMath.sol";

contract RupeeT is ITRC20 {
    using SafeMath for uint256;
    using Address for address;

    string private _name =  "RupeeT";
    string private _symbol =  "RUPT";
    uint8 private _decimals = 2;
    uint256 private _totalSupply = 0;

    address private _king;
    address private _queen = address(0);
    address private _prince = address(0);
    address private _jack = address(0);

    // contract specific variables
    uint256 token_counter = 1;
    uint256 jack_token = 0;
    uint256 jack_token_allowed_till;
    uint256 prince_token = 0;
    uint256 prince_token_allowed_till;
    uint256 queen_token = 0;
    uint256 queen_token_allowed_till;

    mapping(address => bool) private _blocked_addresses;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    // Modifiers
    modifier onlyKing() {
        require(_king == msg.sender, "Rupeet : This function is only accesible by King.");
        _;
    }

    modifier onlyQueen() {
        require(_queen == msg.sender, "Rupeet : This function is only accesible by Queen.");
        _;
    }

    modifier onlyPrince() {
        require(_prince == msg.sender, "Rupeet : This function is only accesible by Prince.");
        _;
    }

    modifier onlyJack() {
        require(_jack == msg.sender, "Rupeet : This function is only accesible by Jack.");
        _;
    }

    // Constructor
    constructor() {
        _king = msg.sender;
        emit OwnershipTransferred(address(0), _king);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // External + Public Functions
    function getOwner() external view returns (address) {
        return _king;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0),"Rupeet : Not allowed to 0 wallet");
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "Rupeet : Not allowed to 0 wallet");
        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Rupeet : Not allowed to 0 wallet");
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(_allowed[from][msg.sender] >= value, "Rupeet : Allowed limit is set lower than requested");
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // Internal Functions
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "Rupeet : Not allowed to 0 wallet");
        require(to != from, "Rupeet : Self transfer not allowed.");

        // In case of new governance declaration
        require(
            _queen != address(0) ,
            "Rupeet : Transactions are on hold until new king, queen, prince, jack will declare"
        );
        require(
            _prince != address(0),
            "Rupeet : Transactions are on hold until new king, queen, prince, jack will declare"
        );
        require(
            _jack != address(0),
            "Rupeet : Transactions are on hold until new king, queen, prince, jack will declare"
        );

        // Kings and Queens dont require money
        require(_queen != to, "Rupeet : Not allowed to send transaction to governance wallets");
        require(_prince != to, "Rupeet : Not allowed to send transaction to governance wallets");
        require(_jack != to, "Rupeet : Not allowed to send transaction to governance wallets");

        require(
            _blocked_addresses[from] != true,
            "Rupeet : Your account is blocked"
        );

        if (from != _king){
            require(
                _balances[from] >= value + (value/1000),
                "Rupeet : Not enought balance to cover amount + 0.1% burning"
            );
        }

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
        if (from != _king){
            _burn(from, (value/1000));
        }
        if ( to == _king ) {
            _burn(to, value);
        }
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0), "Rupeet : Not allowed to 0 wallet");
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Mint(account, value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "Rupeet : Not allowed to 0 wallet");
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Burn(account, value);
        emit Transfer(account, address(0), value);
    }

    // Contract Specific Functions
    function kingMint(uint256 amount) public onlyKing returns (bool) {
        _mint(_king, amount * 10**2);
        return true;
    }

    function createJackTokenForSacrifice() public onlyJack returns (uint256) {
        token_counter = token_counter + 1;
        jack_token = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, token_counter)));
        jack_token_allowed_till = block.timestamp + 300;
        return jack_token;
    }

    function createPrinceTokenForSacrifice(uint256 jtoken) public onlyPrince returns (uint256) {
        require(jack_token != 0, "Rupeet : No Jack Token Available");
        require(jtoken == jack_token, "Rupeet : Un-Authorised Jack Token");
        require(jack_token_allowed_till >= block.timestamp, "Rupeet : Jack Token Expire");
        token_counter = token_counter + 1;
        prince_token = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, token_counter)));
        prince_token_allowed_till = block.timestamp + 300;
        jack_token = 0;
        jack_token_allowed_till = 0;
        return prince_token;
    }

    function killKingAndSacrifice(address newking, uint256 ptoken) public onlyQueen returns (bool) {
        require(prince_token != 0, "Rupeet : No Prince Token Available");
        require(ptoken == prince_token, "Rupeet : Un-Authorised Prince Token");
        require(prince_token_allowed_till >= block.timestamp, "Rupeet : Prince Token Expire");
        _king = newking;
        _queen = address(0);
        _prince = address(0);
        _jack = address(0);
        prince_token = 0;
        prince_token_allowed_till = 0;
        return true;
    }

    function declareQueen(address newqueen) public onlyKing returns (bool) {
        _queen = newqueen;
        return true;
    }

    function declarePrince(address newprince) public onlyKing returns (bool) {
        _prince = newprince;
        return true;
    }

    function declareJack(address newjack) public onlyQueen returns (bool) {
        _jack = newjack;
        return true;
    }

    function createQueenTokenForWalletBlockOrUnblock() public onlyQueen returns (uint256) {
        token_counter = token_counter + 1;
        queen_token = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, token_counter)));
        queen_token_allowed_till = block.timestamp + 300;
        return queen_token;
    }

    function createPrinceTokenForWalletBlockOrUnblock(uint256 qtoken) public onlyPrince returns (uint256) {
        require(queen_token != 0, "Rupeet : No Queen Token Available");
        require(qtoken == queen_token, "Rupeet : Un-Authorised Queen Token");
        require(queen_token_allowed_till >= block.timestamp, "Rupeet : Queen Token Expire");
        token_counter = token_counter + 1;
        prince_token = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, token_counter)));
        prince_token_allowed_till = block.timestamp + 300;
        queen_token = 0;
        queen_token_allowed_till = 0;
        return prince_token;
    }

    function blockWallet(address blockaddress, uint256 ptoken) public onlyJack returns (bool) {
        require(prince_token != 0, "Rupeet : No Prince Token Available");
        require(ptoken == prince_token, "Rupeet : Un-Authorised Prince Token");
        require(prince_token_allowed_till >= block.timestamp, "Rupeet : Prince Token Expire");
        _blocked_addresses[blockaddress] = true;
        prince_token = 0;
        prince_token_allowed_till = 0;
        return true;
    }

    function unblockWallet(address unblockaddress, uint256 ptoken) public onlyJack returns (bool) {
        require(prince_token != 0, "Rupeet : No Prince Token Available");
        require(ptoken == prince_token, "Rupeet : Un-Authorised Prince Token");
        require(prince_token_allowed_till >= block.timestamp, "Rupeet : Prince Token Expire");
        _blocked_addresses[unblockaddress] = false;
        prince_token = 0;
        prince_token_allowed_till = 0;
        return true;
    }
}
