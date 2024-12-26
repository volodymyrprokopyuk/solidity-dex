#!/usr/bin/env nu

$env.PATH = $env.PATH | prepend ("../secp256k1" | path expand)

export def "hash sha256" []: [binary -> string, string -> string] {
  let msg = $in
  let hash = $msg | openssl dgst -sha256 -binary | encode hex --lower
  $hash
}

# "message" | hash sha256 | print
# 0x[1a2b] | hash sha256 | print

export def "hash keccak256" []: [binary -> string, string -> string] {
  let msg = $in
  let hash = $msg | openssl dgst -keccak-256 -binary | encode hex --lower
  $hash
}

# "message" | hash keccak256 | print
# 0x[1a2b] | hash keccak256 | print

export def "hash hmac-sha512" [key: string]: [binary -> string, string -> string] {
  let msg = $in
  let hash = $msg | openssl dgst -sha512 -hmac $key -binary | encode hex --lower
  $hash
}

# "message" | hash hmac-sha512 "key" | print
# 0x[1a2b] | hash hmac-sha512 "key" | print

# export def "encode base58check" []: string -> string {
#   let alpha = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
#     | split chars
# }

let key = "45fe397c062513442044ab8f303b92c7a54184f2dd935b7eb5dc20b72fd68b39"
$key | secp256k1 derive | from yaml | print

def "key generate" [keyPath: path, pubPath: path] {
  let key = openssl ecparam -genkey -name secp256k1 -noout
  $key | save --force $keyPath
  $key | openssl ec -pubout | save --force $pubPath
}

# key generate key.pem pub.pem

def parse-key [keyName: string]: string -> string {
  let strKey = $in
  let hexKey = $strKey | lines | skip until { $in =~ $keyName } | skip 1
    | take while { $in =~ '^\s+' } | str join
    | str replace --all --regex '[\s:]' ""
  $hexKey
}

def "key private" []: path -> string {
  let keyFile = $in
  let hexKey = $keyFile | open | openssl ec -text -noout | parse-key "priv:"
  $hexKey
}

# "key.pem" | key private | print

def "key public" [--pub-in]: path -> string {
  let keyFile = $in
  let hexPub = $keyFile | open | if $pub_in {
    openssl ec -pubin -text -noout
  } else {
    openssl ec -text -noout
  } | parse-key "pub:" | str substring 2..129
  $hexPub
}

# "key.pem" | key public | print
# "pub.pem" | key public --pub-in | print

def "key address" []: string -> string {
  let pub = $in
  let addr = $pub | hash keccak256 | str substring 24..63
  $addr
}

# "pub.pem" | key public --pub-in | key address | print
# "key.pem" | key private | secp256k1 derive | from yaml | print

export def "address checksum" []: string -> string {
  let strAddr = $in
  let chAddr = $strAddr | split chars
  let chHash = $strAddr | str downcase | hash keccak256 | split chars
  let addrSum = $chAddr | zip $chHash | each {
    let a = $in.0
    let h = $in.1 | into int --radix 16
    if ($h >= 8) { $a | str upcase } else { $a }
  } | str join
  $addrSum
}

# "pub.pem" | key public --pub-in | key address | address checksum | print

export def "address verify" []: string -> bool {
  let addrSum = $in
  let chAddr = $addrSum | split chars
  let chHash = $addrSum | str downcase | hash keccak256 | split chars
  let valid = $chAddr | zip $chHash | all {
    let a = $in.0
    let h = $in.1 | into int --radix 16
    if ($h >= 8) { $a =~ '[A-F0-9]' } else { $a =~ '[a-z0-9]' }
  }
  $valid
}

# "pub.pem" | key public --pub-in | key address | address checksum
#   | address verify | print

export def "seed generate" [bits: int]: string -> string {
  if ($bits not-in [128, 160, 192, 224, 256]) {
    error make {msg: $"invalid bits length: ($bits)"}
  }
  let rseq = $in
  let seed = $rseq | decode hex | take ($bits // 8)
  let hash = $seed | hash sha256 | decode hex
  let seedSum = $seed ++ ($hash | take 1)
  let wrdLen = ($bits + ($bits // 32)) // 11
  let wrdIdx = 0..<$wrdLen | each {|i|
    $seedSum | bits shl ($i * 11) | take 2 | bits shr 5
      | bytes reverse | into int
  }
  let words = "dictionary.txt" | open | lines
  let mnemonic = $wrdIdx | each {|idx| $words | get $idx } | str join " "
  $mnemonic
}

# "0c1e24e5917779d297e14d45f14e1a1a" | seed generate 128 | print
# "2041546864449caff939d32d574753fe684d3c947c3346713dd8423e74abcf8c"
#   | seed generate 256 | print

export def "seed recover" [bits: int]: string -> string {
  if ($bits not-in [128, 160, 192, 224, 256]) {
    error make {msg: $"invalid bits length: ($bits)"}
  }
  let mnemonic = $in
  let words = "dictionary.txt" | open | lines | enumerate
    | each { {$in.item: $in.index} } | into record
  let wrdIdx = $mnemonic | split words | each {|w| $words | get $w } | reverse
  let seed = $wrdIdx | reduce --fold 0x[] {|decIdx, seed|
    let hexIdx = $decIdx | into binary | take 2 | bytes reverse
    $seed | bytes add $hexIdx | bits shl 5
  } | take ($bits // 8) | encode hex --lower
  $seed
}

# "0c1e24e5917779d297e14d45f14e1a1a" | seed generate 128 |
#   | seed recover 128 | print
# "2041546864449caff939d32d574753fe684d3c947c3346713dd8423e74abcf8c"
#   | seed generate 256 | seed recover 256 | print

export def "seed derive" [--passphrase: string = ""]: string -> string {
  let mnemonic = $in
  let pass = $mnemonic | encode hex --lower
  let salt = "mnemonic" + $passphrase | encode hex --lower
  (openssl kdf -kdfopt digest:sha512 -kdfopt iter:2048 -keylen 64 -binary
   -kdfopt hexpass:($pass) -kdfopt hexsalt:($salt) pbkdf2) | encode hex --lower
}

# "0c1e24e5917779d297e14d45f14e1a1a" | mnemonic generate 128
#   | seed derive | print
# "0c1e24e5917779d297e14d45f14e1a1a" | mnemonic generate 128
#   | seed derive --passphrase SuperDuperSecret | print

# def "master derive" []: string -> record {
#   let hash = $in | hash sha512
#   let mkey = $hash | str substring 0..63
#   let mpub = $hash | secp256k1 derive | from yaml | get pub
#   let mcode = $hash | str substring 64..127
#   {mkey: $mkey, mpub: $mpub, mcode: $mcode}
# }

# "key.pem" | open | key private | print
# "key.pem" | open | key public | tee { print } | str length | print

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

# let k = "/dev/urandom" | open | first 32 | hash keccak256 | secp256k1 derive
#   | from yaml

# let k = "key.pem" | open | key public | key address | secp256k1 derive | from yaml
# let sig2 = "message" | hash keccak256 | secp256k1 sign --key $k.key
# $sig2 | print
# "message" | hash keccak256 | secp256k1 verify --sig $sig2 --pub $k.pub | print
# "messagex" | hash keccak256 | secp256k1 verify --sig $sig2 --pub $k.pub | print
