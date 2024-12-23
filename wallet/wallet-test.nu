#!/usr/bin/env nu

use std assert
use wallet.nu [
  "mnemonic generate", "mnemonic recover",
  "address checksum" , "address verify"
]

def "test mnemonic generate" [] {
  let cases = [[rseq, bits, exp];
    ["0c1e24e5917779d297e14d45f14e1a1a", 128,
     "army van defense carry jealous true garbage claim echo media make crunch"],
    ["2041546864449caff939d32d574753fe684d3c947c3346713dd8423e74abcf8c", 256,
     ("cake apple borrow silk endorse fitness top denial coil riot stay wolf" +
      " luggage oxygen faint major edit measure invite love trap field" +
      " dilemma oblige")]
  ]
  $cases | each {|c| assert equal ($c.rseq | mnemonic generate $c.bits) $c.exp }
}

def "test mnemonic recover" [] {
  let cases = [[rseq, bits];
    ["0c1e24e5917779d297e14d45f14e1a1a", 128],
    ["2041546864449caff939d32d574753fe684d3c947c3346713dd8423e74abcf8c", 256]
  ]
  $cases | each {|c|
    let rseq = $c.rseq | mnemonic generate $c.bits | mnemonic recover $c.bits
    assert equal $rseq $c.rseq
  }
}

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

test mnemonic generate
test mnemonic recover

# test address checksum
# test address verify

print success
