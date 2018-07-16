#!/bin/bash

# mk-sstp-keys.sh    ~ v0.9
# Michail Topaloudis ~ Dublin, 2017-07-20
# License            ~ GPL 2.0

# A bash script that simplifies ssl keys creation

# https://wiki.mikrotik.com/wiki/SSTP_step-by-step
# https://docs.oracle.com/cd/E24191_01/common/tutorials/authz_cert_attributes.html
# https://stackoverflow.com/questions/6464129/certificate-subject-x-509

#########################################################################################

# General Settings

Domain='example.org'
Hosts='host1 host2 router1 router2 switch1 switch2'
Passphrase='1234'

# SSL Attribute Subject

countryName='US'
stateOrProvinceName='Random'
locality='Random'
organizationName='Example SA'
organizationalUnitName='IT'
emailAddress='info@example.org'

# SSL Settings

Length=4096
Days=3650
Dir='sstp-keychain'

#########################################################################################

# CA
CAdir="${Dir}/${Domain}/ca"
CAkey=''
CAcrt=''

# Hosts
HSdir="${Dir}/${Domain}/hosts"

#########################################################################################

# Creates the x509 Attribute Subject
# param 1: commonName (CN)
mk_subject() {
  local subj="/C=${countryName}/ST=${stateOrProvinceName}/L=${locality}/O=${organizationName}/OU=${organizationalUnitName}/emailAddress=${emailAddress}"

  if [ ! -z "${1}" ]; then
    subj+="/CN=${1}"
  fi

  echo "${subj}"
}

# Creates CA key and crt if don't exist
# param 1: Directory
# param 2: Domain
mk_ca() {
  if [ ! -z "${1}" ]; then
    CAkey="${1}/${2}.key"
    CAcrt="${1}/${2}.crt"

    if [ ! -f "${CAkey}" ] || [ ! -f "${CAcrt}" ]; then
      mkdir -p "${2}"
      rm   -rf "${2}/*"
      mkdir -p "${1}"
      rm   -rf "${1}/*"

      local subj=$(mk_subject)

      openssl genrsa -passout pass:${Passphrase} -des3 -out "${CAkey}" ${Length}
      openssl req     -passin pass:${Passphrase} -subj "${subj}" -new -x509 -days ${Days} -key "${CAkey}" -out "${CAcrt}"

      pyel "${2} CA key, crt created." 1
    fi
  fi
}

# Creates a Host key, csr, crt if don't exist
# param 1: Directory
# param 2: commonName (CN)
mk_host() {
  if [ ! -z "${1}" ] && [ ! -z "${2}" ]; then
    local key="${1}/${2}.key"
    local csr="${1}/${2}.csr"
    local crt="${1}/${2}.crt"

    mkdir -p "${1}"

    if [ ! -f "${key}" ] || [ ! -f "${csr}" ] || [ ! -f "${crt}" ]; then
      rm -rf "${1}/${2}.*"

      local subj=$(mk_subject "${2}")

      openssl genrsa -passout pass:${Passphrase} -des3 -out "${key}" ${Length}
      openssl req    -passin  pass:${Passphrase} -subj "${subj}" -new -key "${key}" -out "${csr}"
      openssl x509   -passin  pass:${Passphrase} -req -days ${Days} -in "${csr}" -CA "${CAcrt}" -CAkey "${CAkey}" -set_serial 01 -out "${crt}"

      pyel "${1} Host key, csr, crt created." 1
    fi
  fi
}

#########################################################################################

# Prints normal text.
# param 1: payload
# param 2: If 1, add newline
pnor() {
  echo "${1}"

  if [ ! -z "${2}" ]; then
    if [ "${2}" == '1' ]; then
      echo
    fi
  fi
}

# Prints everything Yellow!
# param 1: payload
# param 2: If 1, add newline
pyel() {
  local YEL='\e[93m'
  local NOR='\e[39m'

  echo -e "${YEL}${1}${NOR}"

  if [ ! -z "${2}" ]; then
    if [ "${2}" == '1' ]; then
      echo
    fi
  fi
}

#########################################################################################

if [ -z "${Dir}" ] || [ -z "${Domain}" ] || [ -z "${Passphrase}" ]; then
  exit 1
fi

mkdir -p "${Dir}"

mk_ca "${CAdir}" "${Domain}"

for Host in ${Hosts}; do
  mk_host "${HSdir}" "${Host}.${Domain}"
done

find "${Dir}"

exit 0
