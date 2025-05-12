# 🕵️‍♂️ Silintel — An OSINT & Reconnaissance Automation Tool

Silintel is an automated **OSINT** and **recon** tool for gathering usernames, finding leaked emails, scanning live domains, and enumerating open ports.  
It offers a **menu-driven interface** and integrates with powerful tools like **Sherlock**, **nmap**, **httpx**, and **Hunter.io** API for advanced enumeration.

![badge](https://img.shields.io/badge/Bash-OSINT-green) ![status](https://img.shields.io/badge/Active-Development-blue)

---

## 🚀 Features

- 🔍 **Username Finder** (via Sherlock)
- 🌐 **DNS Lookup** (`dig`, `nslookup`, `whois`)
- 📧 **Company Email Finder** (via Hunter.io API)
- 📡 **Active Port Scanning** (Multiple scan techniques using Nmap)
- 🔥 Progress bar animation for long-running tasks
- 🎨 Beautiful output with colored text and banners

---

## 🛠️ Requirements

Ensure the following tools are installed:

- `bash`
- `figlet`
- `lolcat`
- `jq`
- `curl`
- `nmap`
- `httpx`
- [`sherlock`](https://github.com/sherlock-project/sherlock)

### Install missing tools on Ubuntu/Debian:

```bash
sudo apt update
sudo apt install figlet lolcat jq curl nmap
GO111MODULE=on go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
git clone https://github.com/sherlock-project/sherlock.git
cd sherlock && pip install -r requirements.txt
