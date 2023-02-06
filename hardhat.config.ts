import "@nomiclabs/hardhat-waffle"
import "@nomiclabs/hardhat-etherscan"
import "@nomiclabs/hardhat-ethers"
import "hardhat-deploy"
import "hardhat-deploy-ethers"
import "dotenv/config"
import { HardhatUserConfig } from "hardhat/config"

const MAINNET_RPC = "https://rpc-mainnet.maticvigil.com"
const MUMBAI_RPC = "https://rpc-mumbai.maticvigil.com/"
const PRIVATE_KEY = process.env.PRIVATE_KEY || "private key"
const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY || "api key"

const config: HardhatUserConfig = {
    etherscan: {
        apiKey: POLYGONSCAN_API_KEY,
    },
    networks: {
        matic: {
            url: MAINNET_RPC,
            chainId: 137,
            live: true,
            saveDeployments: true,
            accounts: [PRIVATE_KEY],
        },
        mumbai: {
            url: MUMBAI_RPC,
            chainId: 80001,
            live: true,
            saveDeployments: true,
            gasMultiplier: 2,
            accounts: [PRIVATE_KEY],
        },
    },
    solidity: {
        version: "0.5.16",
        settings: {
            optimizer: {
                enabled: true,
                runs: 999999,
            }
        },
    },
}

export default config
