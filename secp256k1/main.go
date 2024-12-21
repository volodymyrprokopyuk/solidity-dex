package main

import (
	"fmt"
	"os"
)

func main() {
  cmd := secp256k1Cmd()
  err := cmd.Execute()
  if err != nil {
    fmt.Fprintln(os.Stderr, err)
    os.Exit(1)
  }
}
