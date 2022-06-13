// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "../interfaces/IERC20.sol";
import "../interfaces/IWrappedAToken.sol";
import "../interfaces/IUniswapV2Router01.sol";
import "../interfaces/ILiquidityHelper.sol";
import "../interfaces/IMasterChef.sol";

contract LiquidityHelper is ILiquidityHelper {
    error LengthMismatch();
    // pool 0 is single wapGHST staking
    uint256[] pools = [0,1,2,3,4,7];
    address GLTR;
    //0--fud
    //1--fomo
    //2--alpha
    //3--kek
    address[4] alchemicaTokens;
    //0--ghst-fud (pid 1)
    //1--ghst-fomo (pid 2)
    //2--ghst-alpha (pid 3)
    //3--ghst-kek (pid 4)
    //4--ghst-gltr (pid 7)
    address[] lpTokens;
    IMasterChef farm;
    IUniswapV2Router01 router;
    address GHST;
    address wapGHST;
    address owner;
    address operator;
    address recipient;
    bool poolGLTR = true;
    bool doStaking = true;
    uint256 minAmount = 100000000000000000; // do not set to 0, 1 means any amount
    uint256 singleGHSTPercent = 0;

    constructor(
        address _gltr,
        address[4] memory _alchemicaTokens,
        address[] memory _pairAddresses, //might be more than 4 pairs
        address _farmAddress,
        address _routerAddress,
        address _ghst,
        address _wrappedAmGhst,
        address _owner,
        address _operator,
        address _recipient
    ) {
        //approve GHST for deposit and wrap
        require(IERC20(_ghst).approve(_routerAddress, type(uint256).max));
        require(IERC20(_ghst).approve(_wrappedAmGhst, type(uint256).max));
        //approve wapGHST for deposit and staking
        require(IERC20(_wrappedAmGhst).approve(_routerAddress, type(uint256).max));
        require(IERC20(_wrappedAmGhst).approve(_farmAddress, type(uint256).max));
        //approve GLTR for deposit
        require(IERC20(_gltr).approve(_routerAddress, type(uint256).max));
        //approve alchemica for deposit
        for (uint256 i; i < _alchemicaTokens.length; i++) {
            require(
                IERC20(_alchemicaTokens[i]).approve(
                    _routerAddress,
                    type(uint256).max
                )
            );
        }
        //approve lp tokens for withdrawal
        for (uint256 i; i < _pairAddresses.length; i++) {
            require(
                IERC20(_pairAddresses[i]).approve(
                    _routerAddress,
                    type(uint256).max
                )
            );
        }
        //approve lp tokens for staking
        for (uint256 i; i < _pairAddresses.length; i++) {
            require(
                IERC20(_pairAddresses[i]).approve(
                    _farmAddress,
                    type(uint256).max
                )
            );
        }
        GLTR = _gltr;
        alchemicaTokens = _alchemicaTokens;
        lpTokens = _pairAddresses;
        farm = IMasterChef(_farmAddress);
        router = IUniswapV2Router01(_routerAddress);
        GHST = _ghst;
        wapGHST = _wrappedAmGhst;
        owner = _owner;
        operator = _operator;
        recipient = _recipient;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Not Operator");
        _;
    }

    modifier onlyOperatorOrOwner() {
        require(
            msg.sender == operator || msg.sender == owner,
            "Not Operator or Owner"
        );
        _;
    }

    function getStakingPoolBalance(uint256 _poolId)
        public
        view
        returns(IMasterChef.UserInfo memory ui)
    {
        ui = farm.userInfo(
            _poolId,
            address(this)
        );
        return (ui);
    }

    function getContractOwner() external view returns (address) {
        return owner;
    }

    function getPoolGLTR() external view returns (bool) {
        return poolGLTR;
    }

    function getDoStaking() external view returns (bool) {
        return doStaking;
    }

    function getOperator() external view returns (address) {
        return operator;
    }

    function getRecipient() external view returns (address) {
        return recipient;
    }

    function getMinAmount() external view returns (uint256) {
        return minAmount;
    }

    function getSingleGHSTPercent() external view returns (uint256) {
        return singleGHSTPercent;
    }

    function setApproval(address _token, address _spender) public onlyOwner {
        require(IERC20(_token).approve(_spender, type(uint256).max));
    }

    function setOperator(address _operator) external onlyOwner {
        assert(_operator != address(0));
        operator = _operator;
    }

    function setRecipient(address _recipient) external onlyOwner {
        assert(_recipient != address(0));
        recipient = _recipient;
    }

    function setPoolGLTR(bool _poolGLTR) external onlyOwner {
        poolGLTR = _poolGLTR;
    }

    function setDoStaking(bool _doStaking) external onlyOwner {
        doStaking = _doStaking;
    }

    function setMinAmount(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Minimum amount should be greater than 0");
        minAmount = _amount;
    }

    function setSingleGHSTPercent(uint256 _percent) external onlyOwner {
        require(_percent >= 0 && _percent < 100, "Percentage should between 1-99 or 0 to disable");
        singleGHSTPercent = _percent;
    }

    function transferOwnership(address _owner) external onlyOwner {
        assert(_owner != address(0));
        owner = _owner;
    }

    function transferTokenFromOwner(address _token, uint256 _amount) public onlyOwner {
        uint256 allowance = IERC20(_token).allowance(msg.sender, address(this));
        require(allowance >= _amount, "Insufficient allowance");
        require(
            IERC20(_token).transferFrom(
                msg.sender, 
                address(this),
                _amount
            )
        );
    }

    function returnTokens(
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external onlyOwner {
        if (_tokens.length != _amounts.length) revert LengthMismatch();
        for (uint256 i; i < _tokens.length; i++) {
            require(IERC20(_tokens[i]).transfer(owner, _amounts[i]));
        }
    }

    function stakePoolToken(StakePoolTokenArgs memory _args)
        public
        onlyOperatorOrOwner
    {
        farm.deposit(
            _args._poolId,
            _args._amount
        );
    }

    function batchStakePoolToken(StakePoolTokenArgs[] memory _args)
        external 
    {
        for (uint256 i; i < _args.length; i++) {
            stakePoolToken(_args[i]);
        }
    }

    function unstakePoolToken(UnstakePoolTokenArgs memory _args)
        public
        onlyOwner 
    {
        farm.withdraw(
            _args._poolId,
            _args._amount
        );
    }

    function batchUnstakePoolToken(UnstakePoolTokenArgs[] memory _args)
        external
    {
        for (uint256 i; i < _args.length; i++) {
            unstakePoolToken(_args[i]);
        }
    }

    function claimReward(uint256 _poolId)
        external
        onlyOperatorOrOwner
    {
        farm.harvest(_poolId);
    }

    function batchClaimReward(uint256[] memory _pools)
        external
    {
        farm.batchHarvest(_pools);
    }

    function swapTokenForGHST(SwapTokenForGHSTArgs memory _args)
        public
        onlyOperatorOrOwner
    {
        address[] memory path = new address[](2);
            path[0] = _args._token;
            path[1] = GHST;
        router.swapExactTokensForTokens(
            _args._amount,
            _args._amountMin,
            path,
            address(this),
            block.timestamp + 3000
        );
    }

    function batchSwapTokenForGHST(SwapTokenForGHSTArgs[] memory _args)
        external 
    {
        for (uint256 i; i < _args.length; i++) {
            swapTokenForGHST(_args[i]);
        }
    }

    function addLiquidity(AddLiquidityArgs memory _args) public onlyOperatorOrOwner {
        router.addLiquidity(
            _args._tokenA,
            _args._tokenB,
            _args._amountADesired,
            _args._amountBDesired,
            _args._amountAMin,
            _args._amountBMin,
            address(this),
            block.timestamp + 3000
        );
    }

    function batchAddLiquidity(AddLiquidityArgs[] memory _args) external {
        for (uint256 i; i < _args.length; i++) {
            addLiquidity(_args[i]);
        }
    }

    function removeLiquidity(RemoveLiquidityArgs memory _args)
        public
        onlyOwner
    {
        router.removeLiquidity(
            _args._tokenA,
            _args._tokenB,
            _args._liquidity,
            _args._amountAMin,
            _args._amountBMin,
            address(this),
            block.timestamp + 3000
        );
    }

    function batchRemoveLiquidity(RemoveLiquidityArgs[] memory _args)
        external
    {
        for (uint256 i; i < _args.length; i++) {
            removeLiquidity(_args[i]);
        }
    }

    function transferAllPoolableTokensFromOwner() external onlyOwner {
        uint256 balance;
        // transfer alchemica
        for (uint256 i; i < alchemicaTokens.length; i++) {
            balance = IERC20(alchemicaTokens[i]).balanceOf(msg.sender);
            if (balance > 0) {
                transferTokenFromOwner(alchemicaTokens[i], balance);
            }
        }
        // transfer GLTR if to be pooled
        if (poolGLTR) {
            balance = IERC20(GLTR).balanceOf(msg.sender);
            if (balance > 0) {
                transferTokenFromOwner(GLTR, balance);
            }
        }
    }

    function transferPercentageOfAllPoolableTokensFromOwner(uint256 _percent) external onlyOwner {
        require(_percent > 0 && _percent < 100, "Percentage need to be between 1-99");
        uint256 balance;
        uint256 amount;
        // transfer alchemica
        for (uint256 i; i < alchemicaTokens.length; i++) {
            balance = IERC20(alchemicaTokens[i]).balanceOf(msg.sender);
            if (balance > 0) {
                amount = balance*_percent/100;
                transferTokenFromOwner(alchemicaTokens[i], amount);
            }
        }
        // transfer GLTR if to be pooled
        if (poolGLTR) {
            balance = IERC20(GLTR).balanceOf(msg.sender);
            if (balance > 0) {
                amount = balance*_percent/100;
                transferTokenFromOwner(GLTR, amount);
            }
        }
    }

    function unpoolAllTokens() public onlyOwner {
        uint256 balance;
        RemoveLiquidityArgs memory arg;
        // remove liquidity from all alchmicas pools
        for (uint256 i; i < alchemicaTokens.length; i++) {
            balance = IERC20(lpTokens[i]).balanceOf(address(this));
            if (balance > 0) {
                arg = RemoveLiquidityArgs(
                    GHST,
                    alchemicaTokens[i],
                    balance,
                    0,
                    0
                ); 
                removeLiquidity(arg);
            }
        }
        // remove liquidity for gltr pool (5th pair)
        balance = IERC20(lpTokens[4]).balanceOf(address(this));
        if (balance > 0) {
            arg = RemoveLiquidityArgs(
                GHST,
                GLTR,
                balance,
                0,
                0
            ); 
            removeLiquidity(arg);
        }
    }

    function unstakeAllPools() public onlyOwner {
        uint256 pool;
        uint256 balance;
        UnstakePoolTokenArgs memory arg;
        for (uint256 i; i < pools.length; i++) {
            pool = pools[i];
            balance = getStakingPoolBalance(pool).amount;
            if (balance > 0) {
                arg = UnstakePoolTokenArgs(
                    pool,
                    balance
                ); 
                unstakePoolToken(arg);
            }
        }
    }

    function returnAllTokens() external onlyOwner {
        // unstake and claim from GLTR pools
        unstakeAllPools();
        uint256 balance;
        // return GHST
        balance = IERC20(GHST).balanceOf(address(this));
        if (balance > 0) {
            require(IERC20(GHST).transfer(owner, balance));
        }
        // return wapGHST
        balance = IERC20(wapGHST).balanceOf(address(this));
        if (balance > 0) {
            require(IERC20(wapGHST).transfer(owner, balance));
        }
        // return GLTR
        balance = IERC20(GLTR).balanceOf(address(this));
        if (balance > 0) {
            require(IERC20(GLTR).transfer(owner, balance));
        }
        // return alchemica
        for (uint256 i; i < alchemicaTokens.length; i++) {
            balance = IERC20(alchemicaTokens[i]).balanceOf(address(this));
            if (balance > 0) {
                require(IERC20(alchemicaTokens[i]).transfer(owner, balance));
            }
        }
        // return lp tokens
        for (uint256 i; i < lpTokens.length; i++) {
            balance = IERC20(lpTokens[i]).balanceOf(address(this));
            if (balance > 0) {
                require(IERC20(lpTokens[i]).transfer(owner, balance));
            }
        }
    }

    function swapPercentageOfAllAlchemicaTokensForGHST(uint256 _percent) public onlyOperatorOrOwner {
        require(_percent > 0 && _percent < 100, "Percentage need to be between 1-99");
        uint256 balance;
        uint256 amount;
        SwapTokenForGHSTArgs memory arg;
        // swap all alchemica tokens
        for (uint256 i; i < alchemicaTokens.length; i++) {
            balance = IERC20(alchemicaTokens[i]).balanceOf(address(this));
            if (balance >= minAmount) {
                amount = balance*_percent/100;
                // swap token for GHST
                arg = SwapTokenForGHSTArgs(
                    alchemicaTokens[i],
                    // swap half of the balance
                    amount,
                    0
                );
                swapTokenForGHST(arg);
            }
        }
    }

    function swapAllPoolableTokensForGHST() external onlyOwner {
        uint256 balance;
        SwapTokenForGHSTArgs memory arg;
        // swap all alchemica tokens for GHST
        for (uint256 i; i < alchemicaTokens.length; i++) {
            balance = IERC20(alchemicaTokens[i]).balanceOf(address(this));
            if (balance >= minAmount) {
                arg = SwapTokenForGHSTArgs(
                    alchemicaTokens[i],
                    balance,
                    0
                );
                swapTokenForGHST(arg);
            }
        }
        // swap GLTR for GHST
        balance = IERC20(GLTR).balanceOf(address(this));
        if (balance >= minAmount) {
            arg = SwapTokenForGHSTArgs(
                GLTR,
                balance,
                0
            );
            swapTokenForGHST(arg);
        }
    }

    // To save gas no explicit claiming is done in this function
    // because adding to the stake claims automatically but this
    // has some implications:
    // - if some token balance is lower than minAmount claiming will not be
    //   done for that pool
    // - if doStaking is set to false after some liquidities have been staked
    //   rewards will need to be claimed independently by calling claimReward
    // - if poolGLTR is true claimed GLTR will be autocompouned only next time
    //   this function is called
    function processAllTokens() external onlyOperatorOrOwner {
        SwapTokenForGHSTArgs memory swapArg;
        AddLiquidityArgs memory poolArg;
        uint256 balance;
        if (singleGHSTPercent > 0) {
            // swap alchemica for single staking first
            swapPercentageOfAllAlchemicaTokensForGHST(singleGHSTPercent);
            // wrap GHST
            IWrappedAToken(wapGHST).enterWithUnderlying(IERC20(GHST).balanceOf(address(this)));
            // stake GHST
            if (doStaking) {
                StakePoolTokenArgs memory stakeArg = StakePoolTokenArgs(
                    0, // pool 0 = single staking wapGHST for gltr
                    IERC20(wapGHST).balanceOf(address(this))
                );
                stakePoolToken(stakeArg);
            }
        }

        // swap, pool (and optionally stake) all the alchemica that is left
        // done one by one to always have the right amount of GHST for each
        for (uint256 i; i < alchemicaTokens.length; i++) {
            balance = IERC20(alchemicaTokens[i]).balanceOf(address(this));
            if (balance >= minAmount) {
                // swap tokens for GHST
                swapArg = SwapTokenForGHSTArgs(
                    alchemicaTokens[i],
                    // swap half
                    balance/2,
                    0
                );
                swapTokenForGHST(swapArg);
                // pool tokens with GHST
                poolArg = AddLiquidityArgs(
                    GHST,
                    alchemicaTokens[i],
                    IERC20(GHST).balanceOf(address(this)),
                    IERC20(alchemicaTokens[i]).balanceOf(address(this)),
                    0,
                    0
                );
                addLiquidity(poolArg);
                // if staking pool tokens in contract
                if (doStaking) {
                    // stake liquidity pool receipt for GLTR
                    StakePoolTokenArgs memory stakeArg = StakePoolTokenArgs(
                        i+1, // pools 1-4 = ghst-fud, ghst-fomo, ghst-alpha, ghst-kek
                        IERC20(lpTokens[i]).balanceOf(address(this))
                    );
                    stakePoolToken(stakeArg);
                }
            }
        }

        // get final GLTR balance
        balance = IERC20(GLTR).balanceOf(address(this));
        // if pooling GLTR with GHST
        if (poolGLTR) {
            if (balance >= minAmount) {
                // split GLTR for GHST
                swapArg = SwapTokenForGHSTArgs(
                    GLTR,
                    // swap half of the balance
                    balance/2,
                    0
                );
                swapTokenForGHST(swapArg);
                // pool GLTR with GHST
                poolArg = AddLiquidityArgs(
                    GHST,
                    GLTR,
                    IERC20(GHST).balanceOf(address(this)),
                    IERC20(GLTR).balanceOf(address(this)),
                    0,
                    0
                );
                addLiquidity(poolArg);
                // if staking stake GLTR too
                if (doStaking) {
                    // stake LP receipt
                    StakePoolTokenArgs memory stakeArg = StakePoolTokenArgs(
                        // 5th pair: ghst-gltr (pid 7)
                        7,
                        IERC20(lpTokens[4]).balanceOf(address(this))
                    );
                    stakePoolToken(stakeArg);
                }
            }
        } else {
            // send GLTR to recipient
            if (balance > 0) {
                require(IERC20(GLTR).transfer(recipient, balance));
            }
        }
    }
}
