# FlashLiquidity

FlashLiquidity core contracts are the fork of [Uniswap V2](https://github.com/Uniswap/uniswap-v2-core)

In-depth documentation on Uniswap V2 is available at [uniswap.org](https://uniswap.org/docs).

# Addresses and Verified Source Code:

- FlashLiquidity Factory: https://polygonscan.com/address/0x6e553d5f028bD747a27E138FA3109570081A23aE
- Pair Contract: https://polygonscan.com/address/0x0C9580eC848bd48EBfCB85A4aE1f0354377315fD

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
