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
	Merge    bool     `json:"merge,omitempty"`
	Networks []string `json:"networks"`
}

func updateDomain(domain string, oldIPAddresses []net.IP) ([]string, error) {
	ipAddresses, err := net.LookupIP(domain)
	if err != nil {
		return nil, err
	}
	ipAddresses = append(ipAddresses, oldIPAddresses...)
	sortIPAddresses(ipAddresses)
	ipAddresses = slices.CompactFunc(ipAddresses, net.IP.Equal)
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

func sortIPAddresses(ips []net.IP) {
	slices.SortFunc(ips, func(a, b net.IP) int {
		// IPv6 comes before IPv4
		a4, b4 := a.To4(), b.To4()
		if a4 != nil && b4 == nil {
			return 1
		}
		if a4 == nil && b4 != nil {
			return -1
		}
		if a4 != nil && b4 != nil {
			return bytes.Compare(a4, b4)
		}
		return bytes.Compare(a, b)
	})
}

func parseNetworks(networks []string) ([]net.IP, error) {
	ipAddress := make([]net.IP, len(networks))
	for i, cidr := range networks {
		address, network, err := net.ParseCIDR(cidr)
		if err != nil {
			return nil, err
		}
		if ones, bits := network.Mask.Size(); ones != bits {
			// We allow only IPv6 /128 and IPv4 /32 masks.
			return nil, fmt.Errorf("invalid network mask for %v", cidr)
		}
		ipAddress[i] = address
	}
	return ipAddress, nil
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
		var oldIPAddresses []net.IP
		if entry.Merge {
			oldIPAddresses, err = parseNetworks(entry.Networks)
			if err != nil {
				return err
			}
		}
		entry.Networks, err = updateDomain(domain, oldIPAddresses)
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
