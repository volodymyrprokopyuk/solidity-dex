package crypto

import (
	"crypto/hmac"
	"crypto/sha512"
)

func macHMACSHA512(data, key []byte) ([]byte, error) {
  state := hmac.New(sha512.New, key)
  _, err := state.Write(data)
  if err != nil {
    return nil, err
  }
  mac := state.Sum(nil)
  return mac, nil
}
