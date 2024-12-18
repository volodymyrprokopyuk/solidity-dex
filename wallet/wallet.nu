#!/usr/bin/env nu

def "hash sha256" []: [binary -> string, string -> string] {
  # $in | sha256sum | str substring 0..63 | print
  $in | openssl dgst -sha256 -r | str substring 0..63
}

def "hash keccak256" []: [binary -> string, string -> string] {
  # $in | keccak-256sum | str substring 0..63 | print
  $in | openssl dgst -keccak-256 -r | str substring 0..63
}

def "hash sha3-256" []: [binary -> string, string -> string] {
  # $in | sha3-256sum | str substring 0..63 | print
  $in | openssl dgst -sha3-256 -r | str substring 0..63
}

def "hash ripemd160" []: [binary -> string, string -> string] {
  $in | openssl dgst -ripemd160 -r | str substring 0..40
}

def "key generate" [
  --private: path = "key.pem", --public: path
] [nothing -> string] {
  openssl ecparam -genkey -name secp256k1 -noout
    | tee { save --force $private } | tee { print }
    | do {
      if ($public | is-not-empty) {
        $in | openssl ec -pubout e> /dev/null
          | tee { save --force $public } | print
      }
      $in
    }
}

# key generate --public pub.pem | print

def parse-key [key: string]: list<string> -> string {
  skip until { $in =~ $key } | skip 1 | take while { $in =~ '^\s+' }
    | each { str replace --all --regex '[\s:]' "" } | str join
}

def "key print" [--public]: string -> record {
  if $public {
    openssl ec -pubin -text -noout e> /dev/null
  } else {
    openssl ec -text -noout e> /dev/null
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


# key generate | key print | tee { print }
#   | get address | tee { print }
#   | address checksum | tee { print }
#   | address verify

# key generate --private key.pem --public pub.pem
"key.pem" | open | key print | get address | address checksum | address verify

# def "secp256k1 sign"
# def "secp256k1 verify"
