package crypto

import (
	"crypto/sha256"

	"golang.org/x/crypto/sha3"
)

func hashSHA256(data []byte) ([]byte, error) {
  state := sha256.New()
  _, err := state.Write(data)
  if err != nil {
    return nil, err
  }
  hash := state.Sum(nil)
  return hash, nil
}

func hashKeccak256(data []byte) ([]byte, error) {
  state := sha3.NewLegacyKeccak256()
  _, err := state.Write(data)
  if err != nil {
    return nil, err
  }
  hash := state.Sum(nil)
  return hash, nil
}
