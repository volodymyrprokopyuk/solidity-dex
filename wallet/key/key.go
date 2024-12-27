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

func keyDerive(key string) (*ecdsa.PrivateKey, error) {
  d, succ := new(big.Int).SetString(key, 16)
  if !succ {
    return nil, fmt.Errorf("invalid key: %s", key)
  }
  prv := &ecdsa.PrivateKey{D: d}
  prv.PublicKey.Curve = ecc.P256k1()
  prv.PublicKey.X, prv.PublicKey.Y = prv.PublicKey.ScalarBaseMult(prv.D.Bytes())
  return prv, nil
}

// func keyAddress()

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
