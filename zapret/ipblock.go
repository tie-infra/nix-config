package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"slices"
)

type ipblockEntry struct {
	Domain   string   `json:"domain,omitempty"`
	Networks []string `json:"networks"`
}

func resolveDomain(domain string) ([]string, error) {
	ipAddresses, err := net.LookupIP(domain)
	if err != nil {
		return nil, err
	}
	slices.SortFunc(ipAddresses, func(a, b net.IP) int {
		if a.Equal(b) {
			return 0
		}
		return bytes.Compare(a, b)
	})
	networks := make([]string, len(ipAddresses))
	for i, ip := range ipAddresses {
		mask := "/128"
		if ip.To4() != nil {
			mask = "/32"
		}
		networks[i] = ip.String() + mask
	}
	return networks, nil
}

func unmarshalJSONFile(filePath string, v any) error {
	contents, err := os.ReadFile(filePath)
	if err != nil {
		return err
	}
	return json.Unmarshal(contents, v)
}

func marshalJSONFile(filePath string, v any) error {
	contents, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		return err
	}
	contents = append(contents, '\n')
	return os.WriteFile(filePath, contents, 0644)
}

func updateJSONFile(filePath string) error {
	var ipblockEntries []ipblockEntry
	if err := unmarshalJSONFile(filePath, &ipblockEntries); err != nil {
		return err
	}
	for i := range ipblockEntries {
		entry := &ipblockEntries[i]
		domain := entry.Domain
		if domain == "" {
			continue
		}
		var err error
		entry.Networks, err = resolveDomain(domain)
		if err != nil {
			return err
		}
	}
	return marshalJSONFile(filePath, ipblockEntries)
}

func main() {
	if err := updateJSONFile("ipblock.json"); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
