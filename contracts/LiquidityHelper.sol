// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "../interfaces/IERC20.sol";
import "../interfaces/IUniswapV2Router01.sol";
import "../interfaces/ILiquidityHelper.sol";
import "../interfaces/IMasterChef.sol";

contract LiquidityHelper is ILiquidityHelper {
    error LengthMismatch();
    IUniswapV2Router01 router;
    IMasterChef farm;
    address GHST;
    address owner;
    address operator;
    //0--fud
    //1--fomo
    //2--alpha
    //3--kek
    address[4] alchemicaTokens;
    address GLTR;
    //0--ghst-fud (pid 1)
    //1--ghst-fomo (pid 2)
    //2--ghst-alpha (pid 3)
    //3--ghst-kek (pid 4)
    //4--ghst-gltr (pid 7)
    address[] lpTokens;
    uint256[] pools = [1,2,3,4,7];
    bool poolGLTR;
    bool doStaking;

    constructor(
        address _gltr,
        address[4] memory _alchemicaTokens,
        address[] memory _pairAddresses, //might be more than 4 pairs
        address _farmAddress,
        address _routerAddress,
        address _ghst,
        address _owner,
        address _operator,
        bool _poolGLTR,
        bool _doStaking
    ) {
        //approve ghst
        IERC20(_ghst).approve(_routerAddress, type(uint256).max);
        //approve gltr
        IERC20(_gltr).approve(_routerAddress, type(uint256).max);
        //approve alchemica infinitely
        for (uint256 i; i < _alchemicaTokens.length; i++) {
            require(
                IERC20(_alchemicaTokens[i]).approve(
                    _routerAddress,
                    type(uint256).max
                )
            );
        }
        //approve pair Tokens
        for (uint256 i; i < _pairAddresses.length; i++) {
            require(
                IERC20(_pairAddresses[i]).approve(
                    _routerAddress,
                    type(uint256).max
                )
            );
        }

        //approve pair Tokens for staking
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
        owner = _owner;
        operator = _operator;
        poolGLTR = _poolGLTR;
        doStaking = _doStaking;
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

    function transferOwnership(address _newOwner) external onlyOwner {
        assert(_newOwner != address(0));
        owner = _newOwner;
    }

    function setOperator(address _newOperator) external onlyOwner {
        assert(_newOperator != address(0));
        operator = _newOperator;
    }

    function setPoolGLTR(bool _poolGLTR) external onlyOwner {
        poolGLTR = _poolGLTR;
    }

    function setDoStaking(bool _doStaking) external onlyOwner {
        doStaking = _doStaking;
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

    function transferAllPoolableTokensFromOwner() external onlyOwner {

        for (uint256 i; i < alchemicaTokens.length; i++) {
            uint256 balance = IERC20(alchemicaTokens[i]).balanceOf(msg.sender);
            if (balance > 0) {
                transferTokenFromOwner(alchemicaTokens[i], balance);
            }
        }

        if (poolGLTR) {
            uint256 balance = IERC20(GLTR).balanceOf(msg.sender);
            if (balance > 0) {
                transferTokenFromOwner(GLTR, balance);
            }
        }

    }

    function transferPercentageOfPoolableTokensFromOwner(uint256 _percent) external onlyOwner {

        require(_percent > 0 && _percent < 100, "Percentage need to be between 1-99");

        for (uint256 i; i < alchemicaTokens.length; i++) {
            uint256 balance = IERC20(alchemicaTokens[i]).balanceOf(msg.sender);
            if (balance > 0) {
                uint256 amount = balance*_percent/100;
                transferTokenFromOwner(alchemicaTokens[i], amount);
            }
        }

        if (poolGLTR) {
            uint256 balance = IERC20(GLTR).balanceOf(msg.sender);
            if (balance > 0) {
                uint256 amount = balance*_percent/100;
                transferTokenFromOwner(GLTR, amount);
            }
        }

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

    function unstakeAllPools() public {

        uint256 pool;
        uint256 balance;
        UnStakePoolTokenArgs memory arg;

        for (uint256 i; i < lpTokens.length; i++) {
            pool = pools[i];
            balance = getStakingPoolBalance(pool).amount;
            if (balance > 0) {
                arg = UnStakePoolTokenArgs(
                    pool,
                    balance
                ); 
                unStakePoolToken(arg);
            }
        }
    }

    function returnAllTokens() external {

        unstakeAllPools();

        uint256 balance;

        balance = IERC20(GHST).balanceOf(address(this));
        if (balance > 0) {
            require(IERC20(GHST).transfer(owner, balance));
        }

        balance = IERC20(GLTR).balanceOf(address(this));
        if (balance > 0) {
            require(IERC20(GLTR).transfer(owner, balance));
        }

        for (uint256 i; i < alchemicaTokens.length; i++) {
            balance = IERC20(alchemicaTokens[i]).balanceOf(address(this));
            if (balance > 0) {
                require(IERC20(alchemicaTokens[i]).transfer(owner, balance));
            }
        }

        for (uint256 i; i < lpTokens.length; i++) {
            balance = IERC20(lpTokens[i]).balanceOf(address(this));
            if (balance > 0) {
                require(IERC20(lpTokens[i]).transfer(owner, balance));
            }
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
        public 
    {
        for (uint256 i; i < _args.length; i++) {
            stakePoolToken(_args[i]);
        }
    }

    function unStakePoolToken(UnStakePoolTokenArgs memory _args)
        public
        onlyOwner 
    {
        farm.withdraw(
            _args._poolId,
            _args._amount
        );
    }

    function batchUnStakePoolToken(UnStakePoolTokenArgs[] memory _args)
        external
    {
        for (uint256 i; i < _args.length; i++) {
            unStakePoolToken(_args[i]);
        }
    }

    function processAllTokens() external onlyOperatorOrOwner {

        for (uint256 i; i < alchemicaTokens.length; i++) {

            uint256 initialTokenBalance = IERC20(alchemicaTokens[i]).balanceOf(address(this));

            if (initialTokenBalance > 0) {

                // swap tokens for GHST
                SwapTokenForGHSTArgs memory swapArg = SwapTokenForGHSTArgs(
                    alchemicaTokens[i],
                    // swap half of the balance
                    initialTokenBalance/2,
                    0
                );
                swapTokenForGHST(swapArg);

                // pool tokens with GHST
                uint256 amountGHST = IERC20(GHST).balanceOf(address(this));
                uint256 amountAlchemica = IERC20(alchemicaTokens[i]).balanceOf(address(this));
                // watch slippage (1% max)
                uint256 minAmountGHST = amountGHST - (amountGHST*1/100);
                uint256 minAmountAlchemica = amountAlchemica - (amountAlchemica*1/100);
                AddLiquidityArgs memory poolArg = AddLiquidityArgs(
                    GHST,
                    alchemicaTokens[i],
                    IERC20(GHST).balanceOf(address(this)),
                    IERC20(alchemicaTokens[i]).balanceOf(address(this)),
                    minAmountGHST,
                    minAmountAlchemica
                );
                addLiquidity(poolArg);

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

        if (poolGLTR) {

            batchClaimReward(pools);

            uint256 initialGLTRBalance = IERC20(GLTR).balanceOf(address(this));

            if (initialGLTRBalance > 0) {

                // split GLTR for GHST
                SwapTokenForGHSTArgs memory GLTRSwapArg = SwapTokenForGHSTArgs(
                    GLTR,
                    // swap half of the balance
                    initialGLTRBalance/2,
                    0
                );
                swapTokenForGHST(GLTRSwapArg);

                // LP GHST-GLTR
                AddLiquidityArgs memory GLTRPoolArg = AddLiquidityArgs(
                    GHST,
                    GLTR,
                    IERC20(GHST).balanceOf(address(this)),
                    IERC20(GLTR).balanceOf(address(this)),
                    0,
                    0
                );
                addLiquidity(GLTRPoolArg);

                if (doStaking) {
                    // stake LP receipt
                    StakePoolTokenArgs memory GLTRStakeArg = StakePoolTokenArgs(
                        // 5th pair: ghst-gltr (pid 7)
                        7,
                        IERC20(lpTokens[4]).balanceOf(address(this))
                    );
                    stakePoolToken(GLTRStakeArg);
                }

            }
        }
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

    function claimReward(uint256 _poolId)
        public
        onlyOwner
    {
        farm.harvest(_poolId);
    }

    function batchClaimReward(uint256[] memory _pools)
        public
        onlyOwner
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
        public 
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

    function withdrawLiquidity(RemoveLiquidityArgs calldata _args)
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

    function batchAddLiquidity(AddLiquidityArgs[] memory _args) public {
        for (uint256 i; i < _args.length; i++) {
            addLiquidity(_args[i]);
        }
    }

    function batchRemoveLiquidity(RemoveLiquidityArgs[] calldata _args)
        external
    {
        for (uint256 i; i < _args.length; i++) {
            withdrawLiquidity(_args[i]);
        }
    }

    function setApproval(address _token, address _spender) public onlyOwner {
        IERC20(_token).approve(_spender, type(uint256).max);
    }

    function getContractOwner() public view returns (address) {
        return owner;
    }

    function getPoolGLTR() public view returns (bool) {
        return poolGLTR;
    }

    function getDoStaking() public view returns (bool) {
        return doStaking;
    }

    function getOperator() public view returns (address) {
        return operator;
    }
}
