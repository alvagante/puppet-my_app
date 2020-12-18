#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  declare -r pre_command='sudo '
else
  declare -r pre_command=''
fi


declare puppet_options
puppet_options="--detailed-exitcodes"
[[ -n "${PT_verbose}" ]] && puppet_options="${puppet_options} --verbose"
[[ -n "${PT_debug}" ]] && puppet_options="${puppet_options} --debug"
[[ -n "${PT_noop}" ]] && puppet_options="${puppet_options} --noop"
[[ -n "${PT_no_noop}" ]] && puppet_options="${puppet_options} --no-noop"
[[ -n "${PT_tags}" ]] && puppet_options="${puppet_options} --tags ${PT_tags}"
[[ -n "${PT_modulepath}" ]] && puppet_options="${puppet_options} --modulepath ${PT_modulepath}"
[[ -n "${PT_environment}" ]] && puppet_options="${puppet_options} --environment ${PT_environment}"
if [[ "${PT_purge_destination}" == "true" ]]; then
  PURGE=", purge => true, force => true "
else
  PURGE=''
fi

readonly puppet_options

if [[ "x${PT_git_source}" != "x" ]]; then
  if [ -d ${PT_destination} ]; then
    command -v git &>/dev/null || exit 1
    cd $PT_destination
    git pull
  else
    git clone $PT_git_source $PT_destination
  fi
fi

if [[ "x${PT_zip_source}" != "x" ]]; then
  if [ ! -d $PT_destination ]; then
    command -v wget &>/dev/null || { echo "command wget not found!" && exit 1; }
    command -v unzip &>/dev/null || { echo "command unzip not found!" && exit 1; }
    mkdir -p $PT_destination
    cd $PT_destination
    TMPFILE=`mktemp`
    wget "${PT_zip_source}" -O $TMPFILE
    unzip -d $PT_destination $TMPFILE
    rm -f $TMPFILE
  else
    echo "${PT_destination} exists. Not changing it. Remove it to unzip ${PT_zip_source} again"
  fi
fi

if [[ "x${PT_tgz_source}" != "x" ]]; then
  if [ ! -d $PT_destination ]; then
    command -v wget &>/dev/null || { echo "command wget not found!" && exit 1; }
    command -v tar &>/dev/null || { echo "command tar not found!" && exit 1; }
    mkdir -p $PT_destination
    cd $PT_destination
    TMPFILE=`mktemp`
    wget "${PT_tgz_source}" -O $TMPFILE
    tar -zvxf $TMPFILE .
    rm -f $TMPFILE
  else
    echo "${PT_destination} exists. Not changing it. Remove it to unzip ${PT_tgz_source} again"
  fi
fi

if [[ "x${PT_puppet_source}" != "x" ]]; then
  command -v puppet &>/dev/null || { echo "command puppet not found!" && exit 1; }
  mkdir -p $PT_destination
  puppet apply -e "file { \"${PT_destination}\": source => \"${PT_puppet_source}\", ensure => directory, recurse => true $PURGE}" 
fi

if [[ "x${PT_puppet_source_tgz}" != "x" ]]; then
  command -v puppet &>/dev/null || { echo "command puppet not found!" && exit 1; }
  command -v tar &>/dev/null || { echo "command tar not found!" && exit 1; }
  TMPFILE=`mktemp`
  mkdir -p $PT_destination
  cd $PT_destination
  tar -zvxf $TMPFILE .
  puppet apply -e "file { \"${TMPFILE}\": source => \"${PT_puppet_source_tgz}\", ensure => present }" 
  rm -f $TMPFILE
fi


$pre_command /opt/puppetlabs/puppet/bin/puppet apply -t $puppet_options $PT_manifest


result=$?
# Puppet exit codes 0 and 2 both imply an error less run
if [ "x$result" == "x0" ] || [ "x$result" == "x2" ]; then
  exit 0
else
  exit 1
fi
