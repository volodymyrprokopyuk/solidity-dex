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

def "key private" []: string -> string {
  openssl ec -text -noout | lines | parse-key "priv:"
}

# "key.pem" | open | key private | print

def "key public" [--pub]: string -> string {
  if $pub {
    openssl ec -pubin -text -noout
  } else {
    openssl ec -text -noout
  } | lines | parse-key "pub:" | str substring 2..129
}

# "key.pem" | open | key public | print
# "pub.pem" | open | key public --pub | print

def "key address" []: string -> string {
  $in | hash keccak256 | str substring 24..63
}

# "pub.pem" | open | key public --pub | key address | print

def "key sign" [key: path]: string -> string {
  openssl pkeyutl -sign -inkey $key | encode base64
}

# "message" | hash keccak256 | key sign key.pem | print

def "key verify" [pub: path, sig: string]: string -> bool {
  let tmp = mktemp --tmpdir --suffix .sig
  $sig | decode base64 | save --raw --force $tmp
  $in | openssl pkeyutl -verify -pubin -inkey $pub -sigfile $tmp
    | $in =~ 'Success'
}

# let sig = "message" | hash keccak256 | key sign key.pem
# $sig | print
# "message" | hash keccak256 | key verify pub.pem $sig | print
# "messagex" | hash keccak256 | key verify pub.pem $sig | print

# $env.PATH = $env.PATH | prepend ("../secp256k1" | path expand)

# let k = "/dev/urandom" | open | first 32 | hash keccak256 | secp256k1 derive
#   | from yaml

# let k = "key.pem" | open | key public | key address | secp256k1 derive | from yaml
# let sig2 = "message" | hash keccak256 | secp256k1 sign --key $k.key
# $sig2 | print
# "message" | hash keccak256 | secp256k1 verify --sig $sig2 --pub $k.pub | print
# "messagex" | hash keccak256 | secp256k1 verify --sig $sig2 --pub $k.pub | print

export def "mnemonic generate" [bits: int]: string -> string {
  if ($bits not-in [128, 160, 192, 224, 256]) {
    error make {msg: $"invalid bits length: ($bits)"}
  }
  let seqlen = $bits // 8
  $in | decode hex | take $seqlen | do {
    let hash = $in | hash sha256 | decode hex
    $in ++ ($hash | take 1) # the random sequence with the checksum
  } | do {
    let sumlen = $bits // 32
    let wrdlen = ($bits + $sumlen) // 11
    let rseq = $in
    0..<$wrdlen | each {|i|
      $rseq | bits shl ($i * 11) | take 2 | bits shr 5
        | bytes reverse | into int # the word index in a dictionary
    }
  } | do {
    let words = "dictionary.txt" | open | lines
    $in | each {|idx| $words | get $idx } # lookup words by index in a dictionary
  } | str join " "
}

export def "mnemonic recover" [bits: int]: string -> string {
  if ($bits not-in [128, 160, 192, 224, 256]) {
    error make {msg: $"invalid bits length: ($bits)"}
  }
  let seqlen = $bits // 8
  let idx = "dictionary.txt" | open | lines | enumerate
    | each { {$in.item: $in.index} } | into record
  $in | split words | each {|w| $idx | get $w } | reverse # word indices
    | reduce --fold 0x[] {|idx, rseq|
      let binidx = $idx | into binary | take 2 | bytes reverse
      $rseq | bytes add $binidx | bits shl 5
    } | take $seqlen | encode hex --lower
}

# "0c1e24e5917779d297e14d45f14e1a1a" | mnemonic generate 128 |
#   | mnemonic recover 128 | print
# "2041546864449caff939d32d574753fe684d3c947c3346713dd8423e74abcf8c"
#   | mnemonic generate 256 | mnemonic recover 256 | print

export def "address checksum" []: string -> string {
  let addr = $in | split chars
  let hash = $in | str downcase | hash keccak256 | split chars
  $addr | zip $hash | each {
    let a = $in.0
    let h = $in.1 | into int --radix 16
    if ($h >= 8) { $a | str upcase } else { $a }
  } | str join
}

# "pub.pem" | open | key public --pub | key address | address checksum | print

export def "address verify" []: string -> bool {
  let addr = $in | split chars
  let hash = $in | str downcase | hash keccak256 | split chars
  $addr | zip $hash | all {
    let a = $in.0
    let h = $in.1 | into int --radix 16
    if ($h >= 8) { $a =~ '[A-F0-9]' } else { $a =~ '[a-z0-9]' }
  }
}

# "pub.pem" | open | key public --pub | key address | address checksum
#   | address verify | print
