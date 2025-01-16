#!/usr/bin/env nu

let nodeURL = "http://127.0.0.1:8545"
let dplScript = "erc/FungibleToken.s.sol:FungibleTokenScript"
let dplPrv = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
let dplAddr = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

def "deploy" []: nothing -> record {
  $env.DPL_PRV = $dplPrv
  let dplLog = forge script $dplScript --fork-url $nodeURL --broadcast
    | complete
  let ctrAddr = $dplLog.stdout | parse --regex 'Contract (?P<addr>0x\w+)'
    | get addr.0
  {deployer: $dplAddr, contract: $ctrAddr}
}

deploy
