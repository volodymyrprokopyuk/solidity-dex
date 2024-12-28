package crypto

import (
	"fmt"

	"github.com/spf13/cobra"
)

func HashCmd() *cobra.Command {
  cmd := &cobra.Command{
    Use: "hash",
    Short: "Produce sha256, keccak256 digest",
  }
  cmd.AddCommand(sha256Cmd(), keccak256Cmd())
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
      _, _ = fmt.Scanf("%v", &data)
      hash := SHA256(data)
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
      _, _ = fmt.Scanf("%v", &data)
      hash := Keccak256(data)
      fmt.Printf("%x\n", hash)
      return nil
    },
  }
  return cmd
}

func MACCmd() *cobra.Command {
  cmd := &cobra.Command{
    Use: "mac",
    Short: "Produce hmac-sha512 authenticated digest",
  }
  cmd.AddCommand(hmacSHA512Cmd())
  return cmd
}

func hmacSHA512Cmd() *cobra.Command {
  cmd := &cobra.Command{
    Use: "hmac-sha512",
    Short: `Produces a hmac-sha512 digest of data from the stdin using an authentication key
  stdin: binary or hex data to authenticate
  stdout: the hmac-sha512 digest in hex of the data authenticated with the key`,
    RunE: func(cmd *cobra.Command, args []string) error {
      var data []byte
      _, _ = fmt.Scanf("%v", &data)
      key, _ := cmd.Flags().GetString("key")
      mac := HMACSHA512(data, []byte(key))
      fmt.Printf("%x\n", mac)
      return nil
    },
  }
  cmd.Flags().String("key", "", "an authentication key")
  _ = cmd.MarkFlagRequired("key")
  return cmd
}
