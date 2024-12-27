package hash

import (
	"crypto/hmac"
	"crypto/sha256"
	"crypto/sha512"
	"fmt"

	"github.com/spf13/cobra"
	"golang.org/x/crypto/sha3"
)

func HashCmd() *cobra.Command {
  cmd := &cobra.Command{
    Use: "hash",
    Short: "Produce sha256, keccak256, hmac-sha512 digests",
  }
  cmd.AddCommand(sha256Cmd(), keccak256Cmd(), hmacSHA512Cmd())
  return cmd
}

func sha256Cmd() *cobra.Command {
  cmd := &cobra.Command{
    Use: "sha256",
    Short: `Produce a sha256 digest of data from the stdin
  stdin: binary or hex data to hash
  stdout: the sha256 digest in hex of the data`,
    RunE: func(cmd *cobra.Command, args []string) error {
      var data []byte
      _, err := fmt.Scanf("%v", &data)
      if err != nil {
        return err
      }
      state := sha256.New()
      _, err = state.Write(data)
      if err != nil {
        return err
      }
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
  stdin: binary or hex data to hash
  sotout: the keccak256 digest in hex of the data`,
    RunE: func(cmd *cobra.Command, args []string) error {
      var data []byte
      _, err := fmt.Scanf("%v", &data)
      if err != nil {
        return err
      }
      state := sha3.NewLegacyKeccak256()
      _, err = state.Write(data)
      if err != nil {
        return err
      }
      hash := state.Sum(nil)
      fmt.Printf("%x\n", hash)
      return nil
    },
  }
  return cmd
}

func hmacSHA512Cmd() *cobra.Command {
  cmd := &cobra.Command{
    Use: "hmac-sha512",
    Short: `Produces a hmac-sha512 digest of data from the stdin using an authentication key
  stdin: binary or hex data to authenticate
  stdout: the hmac-sha512 authenticated digest in hex of the data`,
    RunE: func(cmd *cobra.Command, args []string) error {
      var data []byte
      _, err := fmt.Scanf("%v", &data)
      if err != nil {
        return err
      }
      key, _ := cmd.Flags().GetString("key")
      state := hmac.New(sha512.New, []byte(key))
      _, err = state.Write(data)
      if err != nil {
        return err
      }
      mac := state.Sum(nil)
      fmt.Printf("%x\n", mac)
      return nil
    },
  }
  cmd.Flags().String("key", "", "authentication key")
  _ = cmd.MarkFlagRequired("key")
  return cmd
}
