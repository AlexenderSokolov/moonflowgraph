#!/usr/bin/env bash
set -euo pipefail

moon fmt --check
moon check
moon test
moon run cmd/demo
