#!/usr/bin/env bash
# Reports whether this runner image still trusts the roots behind the compromised
# eMudhra intermediates (https://emudhra.we-have-a-problem.com/). Fails while it does.
set -euo pipefail

bundle=/etc/ssl/certs/ca-certificates.crt
subjects=$(openssl crl2pkcs7 -nocrl -certfile "$bundle" | openssl pkcs7 -print_certs -noout | grep '^subject=')

# OpenSSL 3.0 prints "CN = x" and 3.5 prints "CN=x".
has() {
  if grep -qE "CN ?= ?$1(,|$)" <<<"$subjects"; then echo yes; else echo no; fi
}

emsign=$(has 'emSign ECC Root CA - G3')
aaa=$(has 'AAA Certificate Services')
pkg=$(dpkg-query -W -f '${Version}' ca-certificates)

# Path A of the disclosure: chains to emSign ECC Root CA - G3 through a cross-sign.
if curl -sS -o /dev/null --max-time 15 https://dv-g3b-emudhra.we-have-a-problem.com/ 2>/dev/null; then
  path_a=trusted
else
  path_a=rejected
fi

echo "RESULT image=${ImageOS:-unknown}/${ImageVersion:-unknown} arch=$(uname -m) ca-certificates=${pkg} emSign_ECC_G3=${emsign} AAA=${aaa} path_a=${path_a}"

{
  echo "| Image | Arch | ca-certificates | emSign ECC Root CA - G3 | AAA Certificate Services | Path A (curl) |"
  echo "|---|---|---|---|---|---|"
  echo "| ${ImageOS:-unknown} ${ImageVersion:-unknown} | $(uname -m) | ${pkg} | ${emsign} | ${aaa} | ${path_a} |"
} >>"${GITHUB_STEP_SUMMARY:-/dev/null}"

if [[ $emsign == yes || $aaa == yes ]]; then
  echo "::error::The system trust store still contains a root used by the compromised intermediates"
  exit 1
fi
