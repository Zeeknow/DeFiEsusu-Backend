import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";

dotenv.config();

// Ensure your .env file has PRIVATE_KEY=your_wallet_private_key
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";

const config: HardhatUserConfig = {
  solidity: "0.8.20",
  networks: {
    blockdag: {
      url: "https://rpc.awakening.bdagscan.com", // BlockDAG Testnet RPC
      chainId: 1043,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [], 
      gasPrice: "auto"
    },
    // Keep localhost for fast testing
    localhost: {
      url: "http://127.0.0.1:8545"
    }
  }
};

export default config;