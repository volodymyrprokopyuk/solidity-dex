#!/usr/bin/env nu

use std assert
use wallet.nu [
  "hash sha256", "hash keccak256", "hash hmac-sha512"
  "seed generate", "seed recover", "seed derive"
  "address checksum" , "address verify"
]

def "test hash sha256" [] {
  let cases = [[msg, exp];
    ["message", "ab530a13e45914982b79f9b7e3fba994cfd1f3fb22f71cea1afbf02b460c6d1d"],
    [0x[1a2b], "7bb58a59efd43e747eaf28bbd8fc2d66fb0786b5fbecb617341aa018919ea42d"]
  ]
  $cases | each {|c| assert equal ($c.msg | hash sha256) $c.exp}
}

def "test hash keccak256" [] {
  let cases = [[msg, exp];
    ["message", "c2baf6c66618acd49fb133cebc22f55bd907fe9f0d69a726d45b7539ba6bbe08"],
    [0x[1a2b], "976ea750014b2010e9adf291796e3612009fe1aace333e7affcd7690a0fcafb6"]
  ]
  $cases | each {|c| assert equal ($c.msg | hash keccak256) $c.exp}
}

def "test hash hmac-sha512" [] {
  let cases = [[msg, key, exp];
    ["message", "key",
     "e477384d7ca229dd1426e64b63ebf2d36ebd6d7e669a6735424e72ea6c01d3f8b56eb39c36d8232f5427999b8d1a3f9cd1128fc69f4d75b434216810fa367e98"],
    [0x[1a2b], "key",
     "a0355072d81e01f3c5750d7af58299581d84c1938428284e0037e173bcb74c40229e674ce4598767b3faa1f83fc2cfa96e374959b57c11c888456e0aeafd12b9"]
  ]
  $cases | each {|c| assert equal ($c.msg | hash hmac-sha512 $c.key) $c.exp}
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

def "test seed generate" [] {
  let cases = [[rseq, bits, exp];
    ["0c1e24e5917779d297e14d45f14e1a1a", 128,
     "army van defense carry jealous true garbage claim echo media make crunch"],
    ["2041546864449caff939d32d574753fe684d3c947c3346713dd8423e74abcf8c", 256,
     ("cake apple borrow silk endorse fitness top denial coil riot stay wolf" +
      " luggage oxygen faint major edit measure invite love trap field" +
      " dilemma oblige")]
  ]
  $cases | each {|c| assert equal ($c.rseq | seed generate $c.bits) $c.exp }
}

def "test seed recover" [] {
  let cases = [[rseq, bits];
    ["0c1e24e5917779d297e14d45f14e1a1a", 128],
    ["2041546864449caff939d32d574753fe684d3c947c3346713dd8423e74abcf8c", 256]
  ]
  $cases | each {|c|
    let rseq = $c.rseq | seed generate $c.bits | seed recover $c.bits
    assert equal $rseq $c.rseq
  }
}

def "test seed derive" [] {
  let cases = [[rseq, bits, passphrase, exp];
    ["0c1e24e5917779d297e14d45f14e1a1a", 128, "",
     "5b56c417303faa3fcba7e57400e120a0ca83ec5a4fc9ffba757fbe63fbd77a89a1a3be4c67196f57c39a88b76373733891bfaba16ed27a813ceed498804c0570"],
    ["0c1e24e5917779d297e14d45f14e1a1a", 128, "SuperDuperSecret",
     "3b5df16df2157104cfdd22830162a5e170c0161653e3afe6c88defeefb0818c793dbb28ab3ab091897d0715861dc8a18358f80b79d49acf64142ae57037d1d54"],
    ["2041546864449caff939d32d574753fe684d3c947c3346713dd8423e74abcf8c", 256, "",
     "3269bce2674acbd188d4f120072b13b088a0ecf87c6e4cae41657a0bb78f5315b33b3a04356e53d062e55f1e0deaa082df8d487381379df848a6ad7e98798404"]
  ]
  $cases | each {|c|
    assert equal (
      $c.rseq | seed generate $c.bits
        | seed derive --passphrase $c.passphrase) $c.exp
  }
}

test hash sha256
test hash keccak256
test hash hmac-sha512

test address checksum
test address verify

test seed generate
test seed recover
test seed derive

print success
