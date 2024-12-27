package main

import (
	"github.com/spf13/cobra"
	"github.com/volodymyrprokopyuk/solidity-dex/wallet/hash"
	"github.com/volodymyrprokopyuk/solidity-dex/wallet/key"
)

func walletCmd() *cobra.Command {
  cmd := &cobra.Command{
    Use: "wallet",
    Short: "sha256, keccak256, hmac-sha512",
    Version: "0.1.0",
    SilenceUsage: true,
    SilenceErrors: true,
  }
  cmd.AddCommand(hash.HashCmd(), key.KeyCmd())
  return cmd
}
