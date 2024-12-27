package key

import (
	"crypto/ecdsa"
	"crypto/rand"
	"fmt"
	"math/big"

	"github.com/dustinxie/ecc"
)

func keyGenerate() (*ecdsa.PrivateKey, error)  {
  return ecdsa.GenerateKey(ecc.P256k1(), rand.Reader)
}

func keyDerive(prv string) (*ecdsa.PrivateKey, error) {
  d, succ := new(big.Int).SetString(prv, 16)
  if !succ {
    return nil, fmt.Errorf("invalid key: %s", prv)
  }
  key := &ecdsa.PrivateKey{D: d}
  key.PublicKey.Curve = ecc.P256k1()
  key.PublicKey.X, key.PublicKey.Y = key.PublicKey.ScalarBaseMult(key.D.Bytes())
  return key, nil
}

// func keyAddress(pub string)

func sign(key string, hash []byte) ([]byte, error) {
  prv, err := keyDerive(key)
  if err != nil {
    return nil, err
  }
  return ecc.SignBytes(prv, hash, ecc.LowerS | ecc.RecID)
}

func verify(hash, sig []byte, pub string) (bool, error) {
  p, err := ecc.RecoverPubkey("P-256k1", hash, sig)
  if err != nil {
    return false, err
  }
  rpub := fmt.Sprintf("%x%x", p.X, p.Y)
  valid := rpub == pub
  return valid, nil
}
