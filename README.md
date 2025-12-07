<p align="center">
  <img src="https://raw.githubusercontent.com/RichardBarron27/red-specter-offensive-framework/main/assets/red-specter-logo.png" alt="Red Specter Logo" width="200">
</p>

<br>

# 🛡️ Red Specter: DDoS Flood Sentinel (v0.1 – Bash MVP)

[![Stars](https://img.shields.io/github/stars/RichardBarron27/redspecter-scriptmap?style=flat&logo=github)](https://github.com/RichardBarron27/redspecter-scriptmap/stargazers)
![Last Commit](https://img.shields.io/github/last-commit/RichardBarron27/redspecter-scriptmap)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Kali%20-purple)
![License](https://img.shields.io/github/license/RichardBarron27/redspecter-scriptmap)


**Lightweight host-level DDoS flood detection with UDP carpet-bomb alerting.**  
Part of the **Red Specter | VIGIL** cybersecurity tooling ecosystem.

---

### 🔍 What It Does
DDoS Flood Sentinel continuously monitors incoming network traffic for:

✔ **PPS (Packets Per Second) spikes**  
✔ **High-entropy port spread**  
✔ **UDP carpet-bomb patterns** — seen in modern hyper-volumetric botnet attacks  
✔ **Real-time terminal alerts** + **timestamped logging**

> Designed for **early warning** on systems without expensive DDoS scrubbing.

---

### 🧠 Why It Exists
Volumetric attacks are now measured in **T**bps, not Gbps.  
You can’t always stop them — but you **can** see them coming.

This tool gives defenders:

- Visibility into **network storm conditions**
- Logs and data to support **incident response**
- A foundation for higher-level alerting tools

All with **zero impact** on live traffic.

---

### ⚙️ Quick Start

Clone and run:

```bash
git clone https://github.com/RichardBarron27/redspecter-ddos-flood-sentinel.git
cd redspecter-ddos-flood-sentinel
sudo ./ddos-flood-sentinel.sh -i eth0
sudo ./ddos-flood-sentinel.sh -i eth0 -t 1 --no-udp-sample
ping -c 5 8.8.8.8

🧪 Example Output
[ALERT] High PPS detected on eth0: 75422 PPS (threshold=50000)
[2025-12-04T10:05:24Z] [ALERT] Pattern resembles UDP carpet bombing (unique dest ports >= 2000).

🛑 Safety & Ethics

Defensive-only

No packet generation

Only use on systems/networks you own or are authorized to defend

Red Specter stands for:
Ethical Intelligence. Precision. Integrity

🚀 Roadmap

Planned enhancements:

Python v1.0 w/ richer metrics & log channels

Syslog/SIEM integration (JSON output)

Slack / webhook alerting

XDP/eBPF fast-path inspection

Dashboard visualization
Created by Red Specter | VIGIL
🔗 Ethical Offensive Security — powered by smart defense

---


## ❤️ Support Red Specter

If these tools help you, you can support future development:

- ☕ Buy me a coffee: https://www.buymeacoffee.com/redspecter  
- 💼 PayPal: https://paypal.me/richardbarron1747  

Your support helps me keep improving Red Specter and building new tools. Thank you!

Notice for Users: If you cloned this and found it useful, please consider starring the repo! Stars help with visibility and let me know which projects to maintain.
