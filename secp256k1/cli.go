package main

import (
	"crypto/ecdsa"
	"encoding/base64"
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

func formatKey(key *ecdsa.PrivateKey) string {
  return fmt.Sprintf("{key: %064x, pub: %064x%064x}", key.D, key.X, key.Y)
}

func secp256k1Cmd() *cobra.Command {
  cmd := &cobra.Command{
    Use: "secp256k1",
    Short: "Generate secp256k1 keys, sign messages, verify signatures",
    Version: "0.1.0",
    SilenceUsage: true,
    SilenceErrors: true,
  }
  cmd.AddCommand(generateCmd(), deriveCmd(), signCmd(), verifyCmd());
  return cmd
}

func generateCmd() *cobra.Command {
  cmd := &cobra.Command{
    Use: "generate",
    Short: `Generate a secp256k1 key pair
  stdout: a key pair yaml {key, pub}`,
    RunE: func(cmd *cobra.Command, args []string) error {
      k, err := generate()
      if err != nil {
        return err
      }
      fmt.Println(formatKey(k))
      return nil
    },
  }
  return cmd
}

func deriveCmd() *cobra.Command {
  cmd := &cobra.Command{
    Use: "derive",
    Short: `Derive a secp256k1 public key from an external private key
  stdin: an external private key
  stdout: a key pair yaml {key, pub}`,
    RunE: func(cmd *cobra.Command, args []string) error {
      var key string
      _, err := fmt.Fscanf(os.Stdin, "%s", &key)
      if err != nil {
        return err
      }
      k, err := derive(key)
      if err != nil {
        return err
      }
      fmt.Println(formatKey(k))
      return nil
    },
  }
  return cmd
}

func signCmd() *cobra.Command {
  cmd := &cobra.Command{
    Use: "sign",
    Short: `Sign a message with a private key
  stdin: a hash of the message
  stdout: the signature of the message`,
    RunE: func(cmd *cobra.Command, args []string) error {
      key, _ := cmd.Flags().GetString("key")
      var hash string
      _, err := fmt.Fscanf(os.Stdin, "%s", &hash)
      if err != nil {
        return err
      }
      sig, err := sign(key, []byte(hash))
      if err != nil {
        return err
      }
      fmt.Println(base64.StdEncoding.EncodeToString(sig))
      return nil
    },
  }
  cmd.Flags().String("key", "", "private key")
  _ = cmd.MarkFlagRequired("key")
  return cmd
}

func verifyCmd() *cobra.Command {
  cmd := &cobra.Command{
    Use: "verify",
    Short: `Verify a signature given a message and a public key
  stdin: a hash of the message
  stdout: true if the signature is valid, false otherwise`,
    RunE: func(cmd *cobra.Command, args []string) error {
      var hash string
      _, err := fmt.Fscanf(os.Stdin, "%s", &hash)
      if err != nil {
        return err
      }
      ssig, _ := cmd.Flags().GetString("sig")
      sig, err := base64.StdEncoding.DecodeString(ssig)
      if err != nil {
        return err
      }
      pub, _ := cmd.Flags().GetString("pub")
      valid, err := verify([]byte(hash), sig, pub)
      if err != nil {
        return err
      }
      fmt.Println(valid)
      return nil
    },
  }
  cmd.Flags().String("sig", "", "message signature")
  _ = cmd.MarkFlagRequired("pub")
  cmd.Flags().String("pub", "", "public key")
  _ = cmd.MarkFlagRequired("pub")
  return cmd
}
