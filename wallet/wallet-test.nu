#!/usr/bin/env nu

use std assert
use wallet.nu ["address checksum" , "address verify"]

def "test address checksum" [] {
  let cases = [[addr, exp];
    ["c5b0a7913c6b0f27853e09a26cacf9e3542e6df1",
     "C5B0a7913C6b0F27853E09a26cAcF9e3542E6DF1"]
  ]
  $cases | each { assert equal ($in.addr | address checksum) $in.exp }
}

def "test address verify" [] {
  let cases = [[addr, exp];
   ["C5B0a7913C6b0F27853E09a26cAcF9e3542E6DF1", true],
   ["C5B0a7913C6b0F27853E09a26cAcF9e3542E6DE1", false]
  ]
  $cases | each { assert equal ($in.addr | address verify) $in.exp }
}

test address checksum
test address verify

print success
