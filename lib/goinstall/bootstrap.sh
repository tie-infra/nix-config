set -eux

export GOCACHE=$TMPDIR/go-cache
export CGO_ENABLED=0 GO_EXTLINK_ENABLED=0

argc=$#
if [ "$argc" != 2 ]; then
	echo "Expected 2 arguments (Go executable and builder source), got $argc" >&2
	exit 1
fi

go=$1
src=$2/main.go

exec "$go" build -trimpath -ldflags=-X=main.goExecutable="$go" -o "$out" -- "$src"
