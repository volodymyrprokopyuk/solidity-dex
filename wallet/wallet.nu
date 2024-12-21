#!/usr/bin/env nu

def "hash sha256" []: [binary -> string, string -> string] {
  # $in | sha256sum | str substring 0..63
  $in | openssl dgst -sha256 -r | str substring 0..63
}

def "hash keccak256" []: [binary -> string, string -> string] {
  # $in | keccak-256sum | str substring 0..63
  $in | openssl dgst -keccak-256 -r | str substring 0..63
}

def "hash sha3-256" []: [binary -> string, string -> string] {
  # $in | sha3-256sum | str substring 0..63
  $in | openssl dgst -sha3-256 -r | str substring 0..63
}

def "hash ripemd160" []: [binary -> string, string -> string] {
  $in | openssl dgst -ripemd160 -r | str substring 0..40
}

def "key generate" [--key: path = "key.pem", --pub: path]: [nothing -> string] {
  openssl ecparam -genkey -name secp256k1 -noout
    | tee { save --force $key } | tee { print } | do {
      if ($pub | is-not-empty) {
        $in | openssl ec -pubout | tee { save --force $pub } | print
      }
      $in
    }
}

# key generate --key key.pem --pub pub.pem | print

def parse-key [key: string]: list<string> -> string {
  skip until { $in =~ $key } | skip 1 | take while { $in =~ '^\s+' }
    | each { str replace --all --regex '[\s:]' "" } | str join
}

def "key print" [--pub]: string -> record {
  if $public {
    openssl ec -pubin -text -noout
  } else {
    openssl ec -text -noout
  } | lines | do {
    let key = $in | parse-key "priv:"
    let pub = $in | parse-key "pub:"
    let pubx = $pub | str substring 2..65
    let puby = $pub | str substring 66..129
    let addr = $pub | str substring 2..129 | hash keccak256
      | str substring 24..63
    { key: $key, pubx: $pubx, puby: $puby, address: $addr }
  }
}

# "key.pem" | open | key print | print
# "pub.pem" | open | key print --public | print
# "pub.pem" | open | key print --public | get address | print

def "key sign" [key: path]: string -> string {
  openssl pkeyutl -sign -inkey $key
}

# "message" | hash keccak256 | key sign key.pem | encode base64 | print

def "key verify" [pub: path, sig: string]: string -> bool {
  let tmp = mktemp --tmpdir --suffix .sig
  $sig | decode base64 | save --raw --force $tmp
  $in | openssl pkeyutl -verify -pubin -inkey $pub -sigfile $tmp
    | $in =~ 'Success'
}

# let sig = "message" | hash keccak256 | key sign key.pem | encode base64
# "message" | hash keccak256 | key verify pub.pem $sig | print
# "messagex" | hash keccak256 | key verify pub.pem $sig | print

# $env.PATH = $env.PATH | prepend ("../secp256k1" | path expand)
# let k = "/dev/urandom" | open | first 32 | hash keccak256 | secp256k1 derive
#   | from yaml
# $k | print
# let sig = "message" | hash keccak256 | secp256k1 sign --key $k.key
# $sig | print
# "message" | hash keccak256 | secp256k1 verify --sig $sig --pub $k.pub | print

export def "address checksum" []: string -> string {
  let addr = $in | split chars
  let hash = $in | str downcase | hash keccak256 | split chars
  $addr | zip $hash | each {
    let a = $in.0
    let h = $in.1 | into int --radix 16
    if ($h >= 8) { $a | str upcase } else { $a }
  } | str join
}

# "pub.pem" | open | key print --public | get address | address checksum | print

export def "address verify" []: string -> bool {
  let addr = $in | split chars
  let hash = $in | str downcase | hash keccak256 | split chars
  $addr | zip $hash | all {
    let a = $in.0
    let h = $in.1 | into int --radix 16
    if ($h >= 8) { $a =~ '[A-F0-9]' } else { $a =~ '[a-z0-9]' }
  }
}

# "pub.pem" | open | key print --public | get address
#   | address checksum | address verify | print
