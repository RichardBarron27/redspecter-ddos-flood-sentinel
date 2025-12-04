#!/usr/bin/env bash
#
# Red Specter: DDoS Flood Sentinel (v0.1)
# Simple PPS + UDP-port-spread watcher for flood / carpet-bomb style attacks.
#
# Defensive-only. Monitors an interface, logs suspicious spikes.
#

VERSION="0.1"

IFACE="eth0"
PPS_THRESHOLD=50000          # Packets per second threshold for ALERT
LOG_FILE="/var/log/ddos-flood-sentinel.log"
CHECK_INTERVAL=1             # seconds between samples

UDP_SAMPLE_SECONDS=10        # How long to sample UDP when threshold hit
UDP_PORT_THRESHOLD=2000      # Unique destination ports in sample to flag carpet bombing
ENABLE_UDP_SAMPLE=1          # 1 = on (requires tcpdump), 0 = off

COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[0;33m"
COLOR_RESET="\033[0m"

usage() {
  cat <<EOF
Red Specter: DDoS Flood Sentinel v${VERSION}

Usage: $0 [options]

Options:
  -i, --iface IFACE          Network interface to monitor (default: ${IFACE})
  -t, --pps-threshold N      PPS threshold for ALERT (default: ${PPS_THRESHOLD})
  -l, --log-file PATH        Log file path (default: ${LOG_FILE})
      --interval N           Interval seconds between samples (default: ${CHECK_INTERVAL})
      --udp-sample-seconds N Duration for UDP sampling when ALERT triggers (default: ${UDP_SAMPLE_SECONDS})
      --udp-port-threshold N Unique UDP destination ports threshold (default: ${UDP_PORT_THRESHOLD})
      --no-udp-sample        Disable tcpdump UDP sampling
  -h, --help                 Show this help and exit

Notes:
  * Requires read access to /proc/net/dev
  * UDP sampling (if enabled) requires: tcpdump (and usually root/sudo)
  * This tool is defensive-only. It does not launch any traffic.
EOF
  exit 0
}

log_msg() {
  local level="$1"; shift
  local msg="$*"
  local ts
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "[$ts] [$level] $msg" | tee -a "$LOG_FILE"
}

die() {
  log_msg "ERROR" "$*"
  exit 1
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--iface)
      IFACE="$2"; shift 2;;
    -t|--pps-threshold)
      PPS_THRESHOLD="$2"; shift 2;;
    -l|--log-file)
      LOG_FILE="$2"; shift 2;;
    --interval)
      CHECK_INTERVAL="$2"; shift 2;;
    --udp-sample-seconds)
      UDP_SAMPLE_SECONDS="$2"; shift 2;;
    --udp-port-threshold)
      UDP_PORT_THRESHOLD="$2"; shift 2;;
    --no-udp-sample)
      ENABLE_UDP_SAMPLE=0; shift 1;;
    -h|--help)
      usage;;
    *)
      echo "Unknown option: $1"
      usage;;
  esac
done

# Check /proc/net/dev
[[ -r /proc/net/dev ]] || die "/proc/net/dev not readable. Are you on Linux?"

get_rx_pkts() {
  # /proc/net/dev format: face | bytes packets ...
  # We want RX packets (3rd field)
  awk -v iface="$IFACE" '
    $1 ~ iface ":" {
      gsub(":", "", $1);
      print $3;
    }' /proc/net/dev
}

mkdir -p "$(dirname "$LOG_FILE")" || die "Cannot create log directory for $LOG_FILE"

log_msg "INFO" "Starting DDoS Flood Sentinel v${VERSION} on interface=${IFACE}, PPS_THRESHOLD=${PPS_THRESHOLD}, LOG_FILE=${LOG_FILE}"

if [[ "$ENABLE_UDP_SAMPLE" -eq 1 ]]; then
  if ! command -v tcpdump >/dev/null 2>&1; then
    log_msg "WARN" "tcpdump not found. UDP sampling disabled."
    ENABLE_UDP_SAMPLE=0
  else
    log_msg "INFO" "UDP sampling enabled (tcpdump present). Sample=${UDP_SAMPLE_SECONDS}s, port_threshold=${UDP_PORT_THRESHOLD}"
  fi
else
  log_msg "INFO" "UDP sampling disabled by flag."
fi

udp_sample_carpet_bombing() {
  local iface="$1"
  local seconds="$2"
  local port_threshold="$3"

  log_msg "INFO" "Starting UDP sample on ${iface} for ${seconds}s to assess port spread..."

  local ports
  ports=$(
    timeout "$seconds" tcpdump -n -l -q -i "$iface" udp 2>/dev/null \
      | awk '
        /IP/ {
          for (i=1;i<=NF;i++) if ($i==">") {print $(i+1); break}
        }' \
      | sed 's/.*\.//; s/://g' \
      | grep -E '^[0-9]+$' \
      | sort -n \
      | uniq
  )

  local count
  count=$(wc -l <<< "$ports")
  [[ -z "$ports" ]] && count=0

  log_msg "INFO" "UDP sample complete. Unique destination ports seen: ${count}"

  if (( count >= port_threshold )); then
    log_msg "ALERT" "Pattern resembles UDP carpet bombing (unique dest ports >= ${port_threshold})."
  else
    log_msg "INFO" "UDP pattern does not meet carpet-bomb threshold (${count} < ${port_threshold})."
  fi
}

# Main loop
prev_pkts=$(get_rx_pkts)
if [[ -z "$prev_pkts" ]]; then
  die "Could not read initial RX packet count for ${IFACE}"
fi

while true; do
  sleep "$CHECK_INTERVAL"
  curr_pkts=$(get_rx_pkts)
  if [[ -z "$curr_pkts" ]]; then
    log_msg "ERROR" "Failed to read RX packet count. Skipping sample."
    continue
  fi

  diff=$((curr_pkts - prev_pkts))
  pps=$(( diff / CHECK_INTERVAL ))
  prev_pkts="$curr_pkts"

  if (( pps < 0 )); then
    log_msg "WARN" "RX packet counter wrapped or reset. Resetting baseline."
    prev_pkts="$curr_pkts"
    continue
  fi

  if (( pps >= PPS_THRESHOLD )); then
    printf "${COLOR_RED}[ALERT]${COLOR_RESET} High PPS detected on %s: %d PPS (threshold=%d)\n" "$IFACE" "$pps" "$PPS_THRESHOLD"
    log_msg "ALERT" "High PPS detected on ${IFACE}: ${pps} PPS (>= ${PPS_THRESHOLD})"

    if [[ "$ENABLE_UDP_SAMPLE" -eq 1 ]]; then
      udp_sample_carpet_bombing "$IFACE" "$UDP_SAMPLE_SECONDS" "$UDP_PORT_THRESHOLD"
    fi
  else
    printf "${COLOR_GREEN}[OK]${COLOR_RESET} PPS on %s: %d (threshold=%d)\r" "$IFACE" "$pps" "$PPS_THRESHOLD"
  fi
done
