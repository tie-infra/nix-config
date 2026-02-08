package main

import (
	"bytes"
	"encoding/json/v2"
	"fmt"
	"net/http"
	"net/netip"
	"os"

	"go4.org/netipx"
)

const apiURL = "https://stat.ripe.net/data/announced-prefixes/data.json"

type apiResponse struct {
	Data apiData `json:"data"`
}

type apiData struct {
	Prefixes []apiPrefix `json:"prefixes"`
}

type apiPrefix struct {
	Prefix string `json:"prefix"`
}

var asnList = []struct {
	Name string
	ASNs []string
}{
	{"Scaleway", []string{"AS12876"}},
	{"Hetzner", []string{"AS24940", "AS213230", "AS212317"}},
	{"Akamai", []string{"AS20940", "AS16625"}},
	{"DigitalOcean", []string{"AS14061"}},
	{"Datacamp, CDN77", []string{"AS60068"}},
	{"Contabo", []string{"AS51167"}},
	{"OVH", []string{"AS16276"}},
	{"Constant", []string{"AS20473"}},
	{"Cloudflare", []string{"AS13335", "AS14789", "AS132892"}},
	{"Oracle", []string{"AS31898"}},
	{"Amazon", []string{"AS16509", "AS14618"}},
	{"G-Core", []string{"AS199524"}},
	{"Roblox", []string{"AS22697"}},
	{"Fellowship", []string{"AS46461"}},
	{"Fastly", []string{"AS54113"}},
	{"LogicForge", []string{"AS208621"}},
	{"Hostinger", []string{"AS47583"}},
	{"Ionos", []string{"AS8560"}},
	{"DreamHost", []string{"AS29873"}},
	{"GoDaddy", []string{"AS26496"}},
	{"HostGator, BlueHost", []string{"AS46606"}},
	{"Valve", []string{"AS32590"}},
	{"Cogent", []string{"AS174"}},
	{"Riot Games, Inc", []string{"AS6507"}},
	{"Linode", []string{"AS63949"}},
}

func asnPrefixes2(yield func(netip.Prefix, error) bool) {
	err := asnPrefixes(func(p netip.Prefix) bool {
		return yield(p, nil)
	})
	if err != nil {
		yield(netip.Prefix{}, err)
	}
}

func asnPrefixes(yield func(netip.Prefix) bool) error {
	for _, v := range asnList {
		for _, asn := range v.ASNs {
			rawURL := apiURL + "?resource=" + asn + "&min_peers_seeing=1"
			resp, err := http.Get(rawURL)
			if err != nil {
				return err
			}
			var out apiResponse
			err = json.UnmarshalRead(resp.Body, &out)
			_ = resp.Body.Close()
			if err != nil {
				return err
			}
			for _, prefix := range out.Data.Prefixes {
				p, err := netip.ParsePrefix(prefix.Prefix)
				if err != nil {
					return err
				}
				if p.Bits() == 0 {
					continue
				}
				if a := p.Addr(); !a.IsGlobalUnicast() || a.IsPrivate() {
					continue
				}
				if !yield(p) {
					return nil
				}
			}
		}
	}
	return nil
}

func main1() error {
	var ipSetBuilder netipx.IPSetBuilder
	for prefix, err := range asnPrefixes2 {
		if err != nil {
			return err
		}
		ipSetBuilder.AddPrefix(prefix)
	}
	ipSet, err := ipSetBuilder.IPSet()
	if err != nil {
		return err
	}

	var buf bytes.Buffer
	for _, prefix := range ipSet.Prefixes() {
		_, _ = buf.WriteString(prefix.String())
		_ = buf.WriteByte('\n')
	}

	return os.WriteFile("ipset.txt", buf.Bytes(), 0o644)
}

func main() {
	if err := main1(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
