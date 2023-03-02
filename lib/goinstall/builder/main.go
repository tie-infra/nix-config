//go:build ignore
// +build ignore

package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
)

// goExecutable is a Go executable name/path that can be set via linker flags.
var goExecutable string = "go"

type flagStrings []string

func (f *flagStrings) String() string {
	return fmt.Sprint([]string(*f))
}

func (f *flagStrings) Set(s string) error {
	*f = append(*f, s)
	return nil
}

func main() {
	var caDir string
	var modCache string
	var goenvs flagStrings
	var goflags flagStrings

	flag.StringVar(&caDir, "cadir", "", "")
	flag.StringVar(&modCache, "modcache", "", "")
	flag.Var(&goenvs, "goenv", "")
	flag.Var(&goflags, "goflag", "")
	flag.CommandLine.Parse(os.Args[2:])

	out := os.Getenv("out")
	tmp := os.Getenv("TMPDIR")

	for _, env := range goenvs {
		name, value, _ := strings.Cut(env, "=")
		must(os.Setenv(name, value))
	}

	must(os.Setenv("HOME", filepath.Join(tmp, "home")))
	must(os.Unsetenv("GOBIN"))

	defer fmt.Println("done")
	switch cmd := os.Args[1]; cmd {
	case "download":
		must(os.Setenv("SSL_CERT_DIR", caDir))
		must(os.Setenv("GOMODCACHE", out))
		must(os.Setenv("GOSUMDB", "off"))
		must(runGo(merge(
			[]string{"install"},
			[]string(goflags),
			[]string{"-n"},
			[]string{"--"},
			flag.Args(),
		)...))
	case "install":
		must(os.Setenv("GOMODCACHE", modCache))
		must(os.Setenv("GOPATH", out))
		must(os.Setenv("GOPROXY", "off"))
		must(os.Setenv("GOSUMDB", "off"))
		must(setEnvIfNotSet("CGO_ENABLED", "0"))
		must(setEnvIfNotSet("GO_EXTLINK_ENABLED", "0"))
		must(runGo(merge(
			[]string{"install"},
			[]string(goflags),
			[]string{"-trimpath"},
			[]string{"--"},
			flag.Args(),
		)...))
		goos := env("GOOS", runtime.GOOS)
		goarch := env("GOARCH", runtime.GOARCH)
		if runtime.GOOS != goos || runtime.GOARCH != goarch {
			bin := filepath.Join(out, "bin")
			binCross := filepath.Join(bin, goos+"_"+goarch)
			temp := filepath.Join(out, "temp")
			must(os.Rename(binCross, temp))
			must(os.Remove(bin))
			must(os.Rename(temp, bin))
		}
	default:
		fatal(`unknown command %q, expected "download" or "install"`, cmd)
	}
}

func env(name, value string) string {
	s := os.Getenv(name)
	if s == "" {
		return value
	}
	return s
}

func setEnvIfNotSet(name, value string) error {
	_, ok := os.LookupEnv(name)
	if ok {
		return nil
	}
	return os.Setenv(name, value)
}

func merge(xs ...[]string) []string {
	var out []string
	for _, x := range xs {
		out = append(out, x...)
	}
	return out
}

func runGo(args ...string) error {
	return run(goExecutable, args...)
}

func run(name string, args ...string) error {
	fmt.Println(name, strings.Join(args, " "))
	c := exec.Command(name, args...)
	c.Stderr = os.Stderr
	return c.Run()
}

func must(err error) {
	if err == nil {
		return
	}
	fatal("%v", err)
}

func fatal(format string, args ...any) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(1)
}
