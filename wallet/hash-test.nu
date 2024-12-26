#!/usr/bin/env nu

use std assert

def "test wallet sha256" [] {
  let cases = [[data, exp];
    ["message", "ab530a13e45914982b79f9b7e3fba994cfd1f3fb22f71cea1afbf02b460c6d1d"],
    [0x[1a2b], "7bb58a59efd43e747eaf28bbd8fc2d66fb0786b5fbecb617341aa018919ea42d"]
  ]
  $cases | each {|c|
    let hash = $c.data | ./wallet sha256
    assert equal $hash $c.exp
    let exp = $c.data | openssl dgst -sha256 -binary | encode hex --lower
    assert equal $hash $exp
  }
}

def "test wallet keccak256" [] {
  let cases = [[data, exp];
    ["message", "c2baf6c66618acd49fb133cebc22f55bd907fe9f0d69a726d45b7539ba6bbe08"],
    [0x[1a2b], "976ea750014b2010e9adf291796e3612009fe1aace333e7affcd7690a0fcafb6"]
  ]
  $cases | each {|c|
    let hash = $c.data | ./wallet keccak256
    assert equal $hash $c.exp
    let exp = $c.data | openssl dgst -keccak-256 -binary | encode hex --lower
    assert equal $hash $exp
  }
}

test wallet sha256
test wallet keccak256

print success
