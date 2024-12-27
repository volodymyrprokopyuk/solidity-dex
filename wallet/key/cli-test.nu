#!/usr/bin/env nu

use std assert

$env.PATH = $env.PATH | prepend ("../wallet" | path expand)

def parse-key [keyName: string]: string -> string {
  let strKey = $in
  let hexKey = $strKey | lines | skip until { $in =~ $keyName } | skip 1
    | take while { $in =~ '^\s+' } | str join
    | str replace --all --regex '[\s:]' ""
  $hexKey
}

def "test key generate" [] {
  let $key = wallet key generate | from yaml
  let $exp = $key.prv | wallet key derive | from yaml
  assert equal $key $exp
}

def "test key derive" [] {
  let prvPEM = openssl ecparam -genkey -name secp256k1 -noout
  let pubPEM = $prvPEM | openssl ec -pubout
  let exp = {
    prv: ($prvPEM | openssl ec -text -noout | parse-key "priv:")
    pub: ($pubPEM | openssl ec -text -noout -pubin | parse-key "pub:"
      | str substring 2..129)
  }
  let key = $exp.prv | wallet key derive | from yaml
  assert equal $key $exp
}

def "test key address" [] {
  let cases = [[prv, exp];
    ["c8aee432ef2035adc6f71a7094c0677eedf74a04f4e17227fa1a4155ad511047",
     "9cea81b9d2e900d6027125378ee2ddfa15feeed1"],
    ["14331ff79e696ae342ca0eab1b2e0f8bd83c4225e3da75cb3d649d443ac860bb",
     "75d28c27ac5c5de118508fee2d14ef5fb04c5435"]
  ]
  $cases | each {|c|
    let key = $c.prv | wallet key derive | from yaml
    let addr = $key.pub | wallet key address
    assert equal $addr $c.exp
  }
}

test key generate
test key derive
test key address

print success

