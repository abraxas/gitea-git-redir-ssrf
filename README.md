<p align="center">
  <img src="header.png" alt="Abraxas Labs — gitea-git-redir-ssrf" width="100%">
</p>

<p align="center">
  <a href="https://abraxaslabs.tech"><strong>abraxaslabs.tech</strong></a>
  &nbsp;·&nbsp;
  <a href="https://github.com/abraxas">github.com/abraxas</a>
  &nbsp;·&nbsp;
  <a href="https://x.com/abraxas_null">@abraxas_null</a>
  &nbsp;·&nbsp;
  <a href="https://github.com/abraxas/gitea-git-redir-ssrf">gitea-git-redir-ssrf</a>
</p>

# gitea-git-redir-ssrf

**Gitea** `1.27.3` — Gitea

Unpublished Gitea source finding: git HTTP redirect SSRF on migrate.

| | |
|---|---|
| ID | Unpublished Gitea source finding #2 (no CVE yet) |
| CWE | [CWE-918](https://cwe.mitre.org/data/definitions/918.html) |
| CVSS | **High: 7.7** `CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:N/A:N` |
| Product | [Gitea](https://github.com/go-gitea/gitea) |
| Affected | all versions **through 1.27.3** (inclusive) |
| Patched | vendor patch — see references |
| Auth | authenticated (see source map) |
| License | [GNU Affero GPL v3.0](LICENSE) |
| Lab | `127.0.0.1` only · vendor/client disclosure pack, not a scanner |

---

## Advisory (from the source map)

modules/git/redirection.go FIXME GIT-CLONE-HTTP-REDIRECT-SSRF. services/migrations/migrate.go  DNS. Default allow-list external; loopback is blocked.

---

## Entry

- **Method:** `POST`
- **Path:** `/api/v1/repos/migrate`
- **Router:** Authenticated migrate. IsMigrateURLAllowed checks bait IP only. git clone follows HTTP 302 because HandleGitCmdHTTPRedirection does not set http.followRedirects=false.
- **Notes:** Authenticated unpublished Gitea #2 CWE-918 v1.27.3. Witness: GHSA-GITEA-GIT-REDIR-SSRF in migrated repo. Not eval. Not a reverse shell. Direct loopback migrate must fail.

### Call chain

- `POST /api/v1/repos/migrate clone_addr=external bait`
- `IsMigrateURLAllowed LookupIP + MatchBuiltinExternal`
- `git.Clone -&gt; HandleGitCmdHTTPRedirection no-op`
- `git clone follows 302 to 127.0.0.1:9418/internal.git`

### Lab preconditions

- Gitea 1.27.3
- Account that can migrate/create repo
- ALLOW_LOCALNETWORKS false (default)

### Witness

migrated repo raw/contents contains GHSA-GITEA-GIT-REDIR-SSRF; direct loopback migrate denied

### Not success

- eval/base64/system payload
- reverse shell
- ALLOW_LOCALNETWORKS true
- file://
- X-Gitea-Internal-Auth

---

## Patch / remediation

**Do this first:** Apply the vendor patch for **Gitea**. See references.

**Verify after upgrade**

- Re-run `gitea-git-redir-ssrf-Abraxas-Labs.py` against the patched build: the mapped witness must **not** appear.
- Confirm the vendor advisory / changeset in the deployed tree (see references).
- A WAF signature is delay, not a patch.

**If you cannot update immediately**

- Disable or isolate the affected component.
- Hunt for the witness condition on production (new privileged users, unexpected files, injected rows — whatever this CVE's map names).

---

## Reproduction (authorized lab)

Target **only** `http://127.0.0.1:8088` (or the loopback you bound). Do not point this script at the internet.

```bash
python3 gitea-git-redir-ssrf-Abraxas-Labs.py
```

Success is the **witness** above in the response body. Generic 200 HTML is not it.

---

## Lab images

Loopback stack used to reproduce. Official images unless a `Dockerfile` in this folder builds from source.

- [`lab/docker-compose.yml`](lab/docker-compose.yml)
- [`lab/Dockerfile`](lab/Dockerfile)
- [`lab/internal-git.sh`](lab/internal-git.sh)
- [`lab/run.sh`](lab/run.sh)
- [`lab/redir.py`](lab/redir.py)

```bash
cd lab
docker compose up --force-recreate
```

Bind the vulnerable product tree next to Compose if the YAML mounts a local directory (plugin zip / source tag from the version table). Publish nothing except `127.0.0.1`.

---

## References

- [github.com/go-gitea/gitea](https://github.com/go-gitea/gitea) tag v1.27.3

- Abraxas Labs: [abraxaslabs.tech](https://abraxaslabs.tech) · [github.com/abraxas](https://github.com/abraxas) · [@abraxas_null](https://x.com/abraxas_null)

---

## Records (structured)

```
# Gitea unpublished #2 — git HTTP redirect SSRF

CWE: CWE-918
Severity: High (source review)

## Description

Migrate allow-list is a  check of `clone_addr`. `git clone` still follows HTTP redirects because `HandleGitCmdHTTPRedirection` is a no-op. A public bait URL can 302 onto loopback git HTTP that would have been denied.

## Product

Gitea 1.27.3. Lab oracle is a witness file in the cloned repo, not a shell.
```

---

## License

This disclosure pack is licensed under the **GNU Affero General Public License v3.0**. See [LICENSE](LICENSE).

---

## Disclaimer

This pack is for **the vendor, the site owner, and licensed labs**. The script talks to `127.0.0.1`. Using it against systems you do not own is not authorized by Abraxas Labs. No warranty.

<p align="center">
  <a href="https://abraxaslabs.tech">abraxaslabs.tech</a> ·
  <a href="https://github.com/abraxas">github.com/abraxas</a> ·
  <a href="https://x.com/abraxas_null">@abraxas_null</a>
</p>
