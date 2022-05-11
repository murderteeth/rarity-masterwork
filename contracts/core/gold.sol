// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface rarity {
    function level(uint256) external view returns (uint256);

    function getApproved(uint256) external view returns (address);

    function ownerOf(uint256) external view returns (address);
}

contract rarity_gold {
    string public constant name = "Rarity Gold";
    string public constant symbol = "gold";
    uint8 public constant decimals = 18;

    uint256 public totalSupply = 0;

    rarity constant rm = rarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);

    mapping(uint256 => mapping(uint256 => uint256)) public allowance;
    mapping(uint256 => uint256) public balanceOf;

    mapping(uint256 => uint256) public claimed;

    event Transfer(uint256 indexed from, uint256 indexed to, uint256 amount);
    event Approval(uint256 indexed from, uint256 indexed to, uint256 amount);

    function wealth_by_level(uint256 level)
        public
        pure
        returns (uint256 wealth)
    {
        for (uint256 i = 1; i < level; i++) {
            wealth += i * 1000e18;
        }
    }

    function _isApprovedOrOwner(uint256 _summoner)
        internal
        view
        returns (bool)
    {
        return
            rm.getApproved(_summoner) == msg.sender ||
            rm.ownerOf(_summoner) == msg.sender;
    }

    function claimable(uint256 summoner)
        external
        view
        returns (uint256 amount)
    {
        require(_isApprovedOrOwner(summoner));
        uint256 _current_level = rm.level(summoner);
        uint256 _claimed_for = claimed[summoner] + 1;
        for (uint256 i = _claimed_for; i <= _current_level; i++) {
            amount += wealth_by_level(i);
        }
    }

    function claim(uint256 summoner) external {
        require(_isApprovedOrOwner(summoner));
        uint256 _current_level = rm.level(summoner);
        uint256 _claimed_for = claimed[summoner] + 1;
        for (uint256 i = _claimed_for; i <= _current_level; i++) {
            _mint(summoner, wealth_by_level(i));
        }
        claimed[summoner] = _current_level;
    }

    function _mint(uint256 dst, uint256 amount) internal {
        totalSupply += amount;
        balanceOf[dst] += amount;
        emit Transfer(dst, dst, amount);
    }

    function approve(
        uint256 from,
        uint256 spender,
        uint256 amount
    ) external returns (bool) {
        require(_isApprovedOrOwner(from));
        allowance[from][spender] = amount;

        emit Approval(from, spender, amount);
        return true;
    }

    function transfer(
        uint256 from,
        uint256 to,
        uint256 amount
    ) external returns (bool) {
        require(_isApprovedOrOwner(from));
        _transferTokens(from, to, amount);
        return true;
    }

    function transferFrom(
        uint256 executor,
        uint256 from,
        uint256 to,
        uint256 amount
    ) external returns (bool) {
        require(_isApprovedOrOwner(executor));
        uint256 spender = executor;
        uint256 spenderAllowance = allowance[from][spender];

        if (spender != from && spenderAllowance != type(uint256).max) {
            uint256 newAllowance = spenderAllowance - amount;
            allowance[from][spender] = newAllowance;

            emit Approval(from, spender, newAllowance);
        }

        _transferTokens(from, to, amount);
        return true;
    }

    function _transferTokens(
        uint256 from,
        uint256 to,
        uint256 amount
    ) internal {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
    }
}
