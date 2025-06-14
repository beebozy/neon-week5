Here's a solid `README.md` tailored to your **RaydiumStakingVault** project, based on the contracts, test files, and your provided context:

---

# 🧱 RaydiumStakingVault

The contract can be found in **Staking.sol**
**RaydiumStakingVault** is a Solidity smart contract that enables users to stake liquidity pool (LP) tokens and manage their rewards on the Solana blockchain via Neon EVM. It interacts with the Raydium AMM through composable Solana instructions, allowing users to deposit tokens, mint LP shares, and withdraw liquidity in a decentralized way.

---

## 📌 Key Features

* ✅ **Solana ↔ EVM Interoperability** (via `ICallSolana`)
* 🧪 **Token Deposits & Share Minting**
* 🔁 **Liquidity Provision to Raydium Pools**
* 💸 **Withdrawals and LP Token Burning**
* 📊 **LP Token Tracking**
* 📤 **Supports both Input-based and Output-based Swaps**
* 🧱 **Composability with Raydium AMM Programs**

---

## ⚙️ Architecture Overview

** The two files created are the staking.sol and staking.test.sol**


  A[User Wallet] -->|ERC20ForSPL.transferFrom| B[RaydiumStakingVault]
  
  B -->|transferSolana| C[Solana Associated Token Account (ATA)]
  
  B -->|addLiquidityInstruction| D[Raydium AMM]
  
  B -->|withdrawLiquidityInstruction| D
  
  B -->|calculateShares| E[Vault State]
  
  E -->|Minted Shares| F[User]
  
  F -->|Withdraw Request| B
```

## 🧪 Testing Setup

We use Hardhat + Mocha + Chai to run tests on Neon EVM + Solana (via the `@solana/web3.js` and `@solana/spl-token` packages).

### ✅ How Tests Are Structured:

* Deploy `RaydiumStakingVault`
* Attach `ERC20ForSPL` interface to `wSOL`
* Setup ATA accounts and SPL tokens

* Deposit → Check share minting

* Withdraw → Check share burning

* Verify utility calls like `calculateShares()` and `getTotalLpInPool()`

---

## 🔁 Core Flow

**These are the methods the contract are being called **
### 1. **Deposit Tokens**

```solidity
RaydiumStakingVault.deposit(poolId, amount, slippage);
```

* Transfers tokens to a precomputed Solana ATA
* Calls `addLiquidityInstruction()` via `ICallSolana`
* Mints shares based on deposited LPs

### 2. **Withdraw Tokens**

```solidity
RaydiumStakingVault.withdraw(poolId, userShares, slippage);
```

* Calculates `lpAmount` to remove
* Withdraws via `withdrawLiquidityInstruction()`
* Burns the user’s shares

---

## 📁 Project Structure

```
contracts/
  ├── RaydiumStakingVault.sol        // Staking logic
  └── composability/                 // Raydium & ATA libraries
test/
  └── raydiumStakingVault.test.js   // Test cases
utils/
  └── setupSPLTokens.js, etc.       // Utility functions for tests
```

---

## 🧪 Example PoolId

In your tests:

```js
const poolId = ethers.zeroPadValue(
  ethers.toBeHex(ethers.decodeBase58("9XY7jqVAFxA9YLGmrMvAXQbTUkH9yUNnhYkG84YkPMfG")),
  32
);
```

---

## 💡 Requirements

*solidity 
* [Neon EVM](https://neonlabs.org/)
* Solana CLI (for devnet testing)
* A funded deployer account (both SOL and ERC20 SPL tokens)

---

## 📦 Installation

```bash
git clone 
cd raydium-vault
npm install
```

---

## 🚀 Run Tests

```bash
npx hardhat test test/staking.test.js
```

Make sure your `.env` or `config.js` includes the correct Solana + Neon node URLs.

---

## 🙏 Acknowledgements


---

## 📜 License

MIT © 2025

---


