package crypto

import (
	"fmt"
	"math/big"
	"strings"
)

const alpha58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

var digit58 = func() map[uint8]int64 {
  m := make(map[uint8]int64)
  for i := 0; i < len(alpha58); i++ {
    m[alpha58[i]] = int64(i)
  }
  return m
}()

func strReverse(str string) string {
  var rev strings.Builder
  for i := len(str) - 1; i >= 0; i-- {
    rev.WriteByte(str[i])
  }
  return rev.String()
}

func Base58enc(num *big.Int) string {
  zero, base58 := big.NewInt(0), big.NewInt(58)
  if num.Cmp(zero) == 0 {
    return "1"
  }
  quot, rem := new(big.Int).SetBytes(num.Bytes()), big.NewInt(0)
  var rev strings.Builder
  for quot.Cmp(zero) != 0 {
    quot.DivMod(quot, base58, rem)
    rev.WriteByte(alpha58[rem.Int64()])
  }
  str := strReverse(rev.String())
  return str
}

func Base58dec(str string) (*big.Int, error) {
  if len(str) == 0 {
    return nil, fmt.Errorf("empty base58 encoded string")
  }
  num, base58 := big.NewInt(0), big.NewInt(58)
  for i := 0; i < len(str); i ++ {
    digit, exist := digit58[str[i]]
    if !exist {
      return nil, fmt.Errorf("invalid base58 digit: %c", str[i])
    }
    num.Mul(num, base58)
    num.Add(num, big.NewInt(digit))
  }
  return num, nil
}
