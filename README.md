# ⛓️ DeFi Esusu - Smart Contracts

This directory contains the Solidity smart contracts and Hardhat deployment scripts for the **DeFi Esusu** platform.

## 📄 Contracts Overview

### 1. `DeFiEsusu.sol` (Main Logic)
The core contract that manages:
* **Circles:** Creation, membership management, contribution tracking, and round-robin payouts.
* **Vaults:** Personal savings logic with time-locks and penalty enforcement.
* **State Variables:** Tracks `nextCircleId`, user balances, and active circles.

### 2. `MockUSDC.sol` (Testing)
A standard ERC20 token used to simulate USDC on the Testnet.
* **Public Mint:** Includes a `mint()` function so judges/testers can get free tokens.

---

## ⚙️ Setup & Installation

### 1. Install Dependencies
```bash
npm install

**### 2. Compile Contracts**
Ensure the code compiles without errors.
```bash
npx hardhat compile

**### 3. Run Tests**
We have included a test suite to verify the logic.
```bash
npx hardhat test

**### 4. Deploy to BlockDAG Awakening Testnet**
To deploy fresh contracts to the network:
```bash
npx hardhat run scripts/deploy.ts --network blockdag
**Note: You must have a .env file with your PRIVATE_KEY (see Configuration below).**

**### 🔐 Configuration (.env)**
Create a .env file in this directory (do NOT commit this file).

**### Code snippet**

PRIVATE_KEY=your_wallet_private_key_here
📍 Deployed Addresses (Awakening Testnet)
DeFiEsusu: 0x6b3e578FDdfF8c4aa1F0CA6A916bb7B8D4EA0880

MockUSDC: 0xee268f4ff160150312485a008dE2cC121107E209

(If you redeploy, update these addresses here so the frontend team knows!)
