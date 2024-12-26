package main

import (
	"crypto/sha256"
	"fmt"

	"github.com/spf13/cobra"
	"golang.org/x/crypto/sha3"
)

func sha256Cmd() *cobra.Command {
  cmd := &cobra.Command{
    Use: "sha256",
    Short: `Produce a sha256 digest of data from the stdin
  stdin: binary or hex data
  stdout: the sha256 digest in hex of the data`,
    RunE: func(cmd *cobra.Command, args []string) error {
      var data []byte
      _, err := fmt.Scanf("%v", &data)
      if err != nil {
        return err
      }
      state := sha256.New()
      state.Write(data)
      hash := state.Sum(nil)
      fmt.Printf("%x\n", hash)
      return nil
    },
  }
  return cmd
}

func keccak256Cmd() *cobra.Command {
  cmd := &cobra.Command{
    Use: "keccak256",
    Short: `Produce a keccak256 digest of data from the stdin
  stdin: binary or hex data
  sotout: the keccak256 digest in hex of the data`,
    RunE: func(cmd *cobra.Command, args []string) error {
      var data []byte
      _, err := fmt.Scanf("%v", &data)
      if err != nil {
        return err
      }
      state := sha3.NewLegacyKeccak256()
      state.Write(data)
      hash := state.Sum(nil)
      fmt.Printf("%x\n", hash)
      return nil
    },
  }
  return cmd
}
