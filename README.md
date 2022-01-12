# FlashLiquidity

FlashLiquidity core contracts are the fork of [Uniswap V2](https://github.com/Uniswap/uniswap-v2-core)

In-depth documentation on Uniswap V2 is available at [uniswap.org](https://uniswap.org/docs).

The built contract artifacts can be browsed via [unpkg.com](https://unpkg.com/browse/@uniswap/v2-core@latest/).

# Addresses and Verified Source Code:

- FLIQ token: https://polygonscan.com/address/0x03079F967A37cCAc6eb01d5dcC98FC45E6b57517
- FlashLiquidity Router: https://polygonscan.com/address/0x552bE393Ef90A8f95836942f731359cf609badb7
- FlashLiquidity Factory: https://polygonscan.com/address/0x59c2997A3D73F32590D9D49dE63B860bB1477d3c
- Pair Contract: https://polygonscan.com/address/0x2572A50CC8f68AdbA0cd20315Aa44107A2a02ddD

# Local Development

The following assumes the use of `node@>=10`.

## Install Dependencies

`yarn`

## Compile Contracts

`yarn compile`

## Run Tests

`yarn test`

## Add To Your Site

To include a FlashLiquidity iframe within your site just add an iframe element within your website code and link to the FlashLiquidity frontend.


`<iframe
  src="https://www.flashliquidity.finance/#/add/ETH/0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619"
  height="660px"
  width="100%"
  style="
    border: 0;
    margin: 0 auto;
    display: block;
    border-radius: 10px;
    max-width: 600px;
    min-width: 300px;
  "
  id="myId"
/>`
