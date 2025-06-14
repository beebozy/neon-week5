// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ICallSolana} from "./precompiles/ICallSolana.sol";
import {LibRaydiumData} from "./composability/libraries/raydium-program/LibRaydiumData.sol";
import {LibAssociatedTokenData} from "./composability/libraries/associated-token-program/LibAssociatedTokenData.sol";
import {LibRaydiumProgram} from "./composability/libraries/raydium-program/LibRaydiumProgram.sol";
import {CallSolanaHelperLib} from "./utils/CallSolanaHelperLib.sol";
import {Constants} from "./composability/libraries/Constants.sol";
import {SolanaDataConverterLib} from "./utils/SolanaDataConverterLib.sol";

contract RaydiumStakingVault {
    using SolanaDataConverterLib for uint64;

    ICallSolana public constant CALL_SOLANA = ICallSolana(0xFF00000000000000000000000000000000000006);

    struct Vault {
        bytes32 poolId;
        bytes32 lpMint;
        uint256 totalShares;
        mapping(address => uint256) balances;
    }

    mapping(bytes32 => Vault) public vaults;

    event Deposited(address indexed user, bytes32 indexed poolId, uint256 amount, uint256 shares);
    event Withdrawn(address indexed user, bytes32 indexed poolId, uint256 amount, uint256 shares);
    event Compounded(bytes32 indexed poolId, uint256 rewards);

    error SolanaOperationFailed();
    error InvalidTokens();

    function deposit(bytes32 poolId, uint64 amountA, uint16 slippage) external {
        LibRaydiumData.PoolData memory poolData = LibRaydiumData.getPoolData(poolId);

        // Setup premade accounts
        bytes32 payer = CALL_SOLANA.getPayer();
        bytes32[] memory premadeAccounts; // length based on Raydium addLiquidityInstruction
        premadeAccounts[0] = payer;
        premadeAccounts[4] = LibAssociatedTokenData.getAssociatedTokenAccount(poolData.tokenA, payer, Constants.getSystemProgramId());
        premadeAccounts[5] = LibAssociatedTokenData.getAssociatedTokenAccount(poolData.tokenB, payer,Constants.getSystemProgramId());

        // Get instruction
        (
            bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibRaydiumProgram.addLiquidityInstruction(poolId, amountA, true, slippage, true, premadeAccounts);

        // Execute
        bytes memory result = CALL_SOLANA.execute(
            0,
            CallSolanaHelperLib.prepareSolanaInstruction(
                Constants.getCreateCPMMPoolProgramId(),
                accounts,
                isSigner,
                isWritable,
                data
            )
        );
        if (result.length == 0) revert SolanaOperationFailed();

        // Calculate shares
        uint256 shares = calculateShares(poolId, amountA);
        vaults[poolId].balances[msg.sender] += shares;
        vaults[poolId].totalShares += shares;

        emit Deposited(msg.sender, poolId, amountA, shares);
    }

    function withdraw(bytes32 poolId, uint256 shares, uint16 slippage) external {
        require(vaults[poolId].balances[msg.sender] >= shares, "Insufficient shares");

        uint64 lpAmount = uint64((shares * getTotalLpInPool(poolId)) / vaults[poolId].totalShares);

        LibRaydiumData.PoolData memory poolData = LibRaydiumData.getPoolData(poolId);
        bytes32 payer = CALL_SOLANA.getPayer();

        bytes32[] memory premadeAccounts; // length based on withdrawLiquidityInstruction
        premadeAccounts[0] = payer;
        premadeAccounts[4] = LibAssociatedTokenData.getAssociatedTokenAccount(poolData.tokenA, payer,Constants.getSystemProgramId());
        premadeAccounts[5] = LibAssociatedTokenData.getAssociatedTokenAccount(poolData.tokenB, payer,Constants.getSystemProgramId());

        (
            bytes32[] memory accounts,
            bool[] memory isSigner,
            bool[] memory isWritable,
            bytes memory data
        ) = LibRaydiumProgram.withdrawLiquidityInstruction(poolId, lpAmount, slippage, true, premadeAccounts);

        CALL_SOLANA.execute(
            0,
            CallSolanaHelperLib.prepareSolanaInstruction(
                Constants.getCreateCPMMPoolProgramId(),
                accounts,
                isSigner,
                isWritable,
                data
            )
        );

        vaults[poolId].balances[msg.sender] -= shares;
        vaults[poolId].totalShares -= shares;

        emit Withdrawn(msg.sender, poolId, lpAmount, shares);
    }

    function calculateShares(bytes32 poolId, uint256 amount) public view returns (uint256) {
        uint256 totalShares = vaults[poolId].totalShares;
        if (totalShares == 0) return amount;
        return (amount * totalShares) / getTotalLpInPool(poolId);
    }

    function getTotalLpInPool(bytes32 poolId) public view returns (uint256) {
        return LibRaydiumData.getPoolLpAmount(poolId);
    }

    function getUserShares(address user, bytes32 poolId) public view returns (uint256) {
        return vaults[poolId].balances[user];
    }
}