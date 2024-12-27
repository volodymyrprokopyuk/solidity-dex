package key

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/volodymyrprokopyuk/solidity-dex/wallet/crypto"
)

func addressEncode(addr string) string {
  hash := crypto.Keccak256([]byte(strings.ToLower(addr)))
  hexAddr := strings.Split(addr, "")
  hexHash := strings.Split(fmt.Sprintf("%x", hash), "")
  var encAddr strings.Builder
  for i := range addr {
    h, _ := strconv.ParseInt(hexHash[i], 16, 8)
    a := hexAddr[i]
    if h >= 8 {
      a = strings.ToUpper(a)
    }
    _, _ = encAddr.WriteString(a)
  }
  return encAddr.String()
}
