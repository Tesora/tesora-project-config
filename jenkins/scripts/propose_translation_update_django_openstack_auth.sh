#!/bin/bash -xe

# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

SOFTWARE="Transifex"

if [ -n "$1" -a "$1" = "zanata" ]; then
    SOFTWARE="Zanata"
fi

source /usr/local/jenkins/slave_scripts/common_translation_update.sh

setup_git

setup_review "$SOFTWARE"

# Setup basic connection for transifex.
setup_translation

setup_django_openstack_auth

# Pull updated translations from Transifex, or Zanata.
case "$SOFTWARE" in
    Transifex)
        pull_from_transifex
        ;;
    Zanata)
        pull_from_zanata "openstack_auth"
        ;;
esac

# Update the .pot file
python setup.py extract_messages
PO_FILES=$(find openstack_auth/locale -name '*.po')
if [ -n "$PO_FILES" ]; then
    # Use updated .pot file to update translations
    python setup.py update_catalog --no-fuzzy-matching  --ignore-obsolete=true
fi

# Compress downloaded po files
compress_po_files "openstack_auth"

# Add all changed files to git
git add openstack_auth/locale/*

filter_commits

send_patch
