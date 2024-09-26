
# Domain Enumeration & Fuzzing Script

This script allows you to perform subdomain enumeration and directory fuzzing on a specified domain. Based on the chosen option (`subdomain` or `fuzz`), it will either enumerate subdomains or fuzz for directories/files within the domain.

## Requirements

- `dig` (for subdomain resolution)
- `curl` (for fuzzing)

## Usage

```bash
./script.sh <domain> <option> [<subdomains_file> or <fuzzing_file>]
```

### Arguments

- `<domain>`: The domain to target (e.g., `example.com`).
- `<option>`: The action to perform. Options are:
  - `subdomain`: Enumerates subdomains using a provided list.
  - `fuzz`: Fuzzes directories or files on the domain using a provided wordlist.
- `<subdomains_file>`: (Required if using `subdomain` option) A file containing a list of subdomains to check.
- `<fuzzing_file>`: (Required if using `fuzz` option) A file containing directory or file names for fuzzing.

### Examples

To enumerate subdomains for a domain using a wordlist file called `/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt`:

```bash
./script.sh example.com subdomain subdomains.txt
```

This will check for active subdomains in the provided list and output the results.

To fuzz directories or files on a domain using a wordlist file called `/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt`:

```bash
./script.sh example.com fuzz fuzzing.txt
```

This will test for valid directories or files based on the wordlist provided.


