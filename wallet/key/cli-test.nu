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

test key generate
test key derive

print success
