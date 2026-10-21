# watch-ca-gha

Checks whether GitHub-hosted Ubuntu runner images still trust the roots behind the compromised eMudhra intermediate CAs ([disclosure](https://emudhra.we-have-a-problem.com/)).

The `probe` workflow runs every 6 hours on each Ubuntu runner label. A job fails while the image's system trust store (`/etc/ssl/certs/ca-certificates.crt`) still contains emSign ECC Root CA - G3 or AAA Certificate Services. Each job's summary records the runner image version, the `ca-certificates` package version, and whether `curl` accepts the disclosure's path A test host.
