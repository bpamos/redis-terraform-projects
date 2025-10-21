#!/bin/bash

ENDPOINT="$1"

if [ -z "$ENDPOINT" ]; then
  echo "Usage: $0 <redis-endpoint>"
  exit 1
fi

#!/bin/bash

ENDPOINT="$1"

if [ -z "$ENDPOINT" ]; then
  echo "Usage: $0 <redis-endpoint>"
  exit 1
fi

memtier_benchmark \
  -s "$ENDPOINT" \
  -p 6379 \
  --protocol redis \
  --clients=50 \
  --threads=2 \
  --test-time=60 \
  --ratio=1:1 \
  --pipeline=4 \
  --key-pattern=R:R \
  --key-prefix=mt: \
  --data-size-range=60-1024 \
  --expiry-range=60-60 \
  --random-data \
  --distinct-client-seed \
  --hide-histogram
