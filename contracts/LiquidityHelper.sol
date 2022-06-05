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
    address[] lpTokens;
    address GLTR;

    constructor(
        address _gltr,
        address[4] memory _alchemicaTokens,
        address[] memory _pairAddresses, //might be more than 4 pairs
        address _farmAddress,
        address _routerAddress,
        address _ghst,
        address _owner,
        address _operator
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
        public 
    {
        for (uint256 i; i < _args.length; i++) {
            stakePoolToken(_args[i]);
        }
    }

    function unStakePoolToken(UnStakePoolTokenArgs calldata _args)
        public
        onlyOwner 
    {
        farm.withdraw(
            _args._poolId,
            _args._amount
        );
    }

    function batchUnStakePoolToken(UnStakePoolTokenArgs[] calldata _args)
        external
    {
        for (uint256 i; i < _args.length; i++) {
            unStakePoolToken(_args[i]);
        }
    }

//    function distributeAlchemica() external  {
//
//    }

//    function stakeGHSTForFrens() external  {
//
//    }

    function stakeAllAlchemicaTokens() external onlyOperatorOrOwner {

        for (uint256 i; i < alchemicaTokens.length; i++) {

            SwapTokenForGHSTArgs memory swapArg = SwapTokenForGHSTArgs(
                alchemicaTokens[i],
                // swap half of the balance
                IERC20(alchemicaTokens[i]).balanceOf(address(this))/2,
                //fix to 1% slippage
                0
            );
            swapTokenForGHST(swapArg);

            uint256 amountGHST = IERC20(GHST).balanceOf(address(this));
            uint256 amountAlchemica = IERC20(alchemicaTokens[i]).balanceOf(address(this));
            //uint256 minAmountGHST = amountGHST - (amountGHST*1/100);
            //uint256 minAmountAlchemica = amountAlchemica - (amountAlchemica*1/100);
            AddLiquidityArgs memory poolArg = AddLiquidityArgs(
                GHST,
                alchemicaTokens[i],
                IERC20(GHST).balanceOf(address(this)),
                IERC20(alchemicaTokens[i]).balanceOf(address(this)),
                0,
                0
                //minAmountGHST,
                //minAmountAlchemica
            );
            addLiquidity(poolArg);

            StakePoolTokenArgs memory stakeArg = StakePoolTokenArgs(
                // pools 1-4 = fud, fomo, alpha, keke 
                // alchemica tokens 1-4 = fud, fomo, alpha, keke 
                i,
                IERC20(lpTokens[i]).balanceOf(address(this))
            );
            stakePoolToken(stakeArg);

        }
    }

    function splitAllAlchemicaTokens() external onlyOperatorOrOwner {

        SwapTokenForGHSTArgs[] memory args; 

        for (uint256 i; i < alchemicaTokens.length; i++) {
            SwapTokenForGHSTArgs memory arg = SwapTokenForGHSTArgs(
                alchemicaTokens[i],
                // swap half of the balance
                IERC20(alchemicaTokens[i]).balanceOf(address(this))/2,
                //fix to 1% slippage
                0
            );
            args[i] = arg;
        }

        batchSwapTokenForGHST(args);
            
    }

    function poolAllAlchemicaTokens() external onlyOperatorOrOwner {

        AddLiquidityArgs[] memory args; 

        for (uint256 i; i < alchemicaTokens.length; i++) {
            uint256 amountGHST = IERC20(GHST).balanceOf(address(this));
            uint256 amountAlchemica = IERC20(alchemicaTokens[i]).balanceOf(address(this));
            //uint256 minAmountGHST = amountGHST - (amountGHST*1/100);
            //uint256 minAmountAlchemica = amountAlchemica - (amountAlchemica*1/100);
            AddLiquidityArgs memory arg = AddLiquidityArgs(
                GHST,
                alchemicaTokens[i],
                IERC20(GHST).balanceOf(address(this)),
                IERC20(alchemicaTokens[i]).balanceOf(address(this)),
                0,
                0
                //minAmountGHST,
                //minAmountAlchemica
            );
            args[i] = arg;
        }

        batchAddLiquidity(args);

    }

    function stakeAllAlchemicaTokens() external onlyOperatorOrOwner {

        StakePoolTokenArgs[] memory args; 

        for (uint256 i; i < alchemicaTokens.length; i++) {
            StakePoolTokenArgs memory arg = StakePoolTokenArgs(
                // pools 1-4 = fud, fomo, alpha, keke 
                // alchemica tokens 1-4 = fud, fomo, alpha, keke 
                i,
                IERC20(lpTokens[i]).balanceOf(address(this))
            );
            args[i] = arg;
        }

        batchStakePoolToken(args);

    }

    function stakingPoolBalance(uint256 _poolId)
        external
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

    function batchClaimReward(uint256[] calldata _pools)
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

    function contractOwner() public view returns (address) {
        return owner;
    }

    function contractOperator() public view returns (address) {
        return operator;
    }
}
