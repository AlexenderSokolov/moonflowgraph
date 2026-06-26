#!/usr/bin/env bash
set -euo pipefail

moon check
moon test
moon run cmd/demo
