#!/bin/sh

test_description='Test aliases'

. ./test-lib.sh

if test -z "$STG_RUST"; then
test_expect_success 'Test help on builtin alias command' '
    stg help add | grep -e "Alias for \"git add"
'
else
test_expect_success 'Test help on builtin alias command' '
    stg help add | grep -e "Alias for shell command \`git add\`"
'
fi

if test -z "$STG_RUST"; then
test_expect_success 'Test ambiguous alias' '
    test_config stgit.alias.show-stat "git show --stat" &&
    stg show-stat &&
    stg init &&
    stg show &&
    general_error stg sho 2>err &&
    grep -e "Ambiguous command: sho" err
'
else
test_expect_success 'Test ambiguous alias' '
    test_config stgit.alias.show-stat "!git show --stat" &&
    stg show-stat &&
    stg init &&
    stg show &&
    command_error stg sho 2>err &&
    grep -e "Did you mean .show-stat. or .show." err
'
fi

if test -n "$STG_RUST"; then
test_expect_success 'Setup top-level and nested aliases' '
    test_create_repo foo/bar/baz &&
    git config --local stgit.alias.top-level-alias "!echo TOP-LEVEL-ALIAS" &&
    git -C foo/bar/baz config --local stgit.alias.nested-alias "!echo NESTED-ALIAS"
'

test_expect_success 'Test finding aliases without -C' '
    stg -h | grep "top-level-alias" &&
    stg 2>&1 >/dev/null | grep "top-level-alias" &&
    test $(stg -h | grep -c "nested-alias") = 0
'

test_expect_success 'Test finding aliases with -C' '
    stg -C foo/bar -C baz -h | grep "nested-alias" &&
    stg -C foo/bar -C baz 2>&1 >/dev/null | grep "nested-alias" &&
    test $(stg -C foo -C bar/baz -h | grep -c "top-level-alias") = 0
'

test_expect_success 'Test running top-level alias' '
    stg top-level-alias | grep "TOP-LEVEL-ALIAS" &&
    stg top-level-alias -h 2>&1 >/dev/null |
    grep -e ".top-level-alias. is aliased to .!echo TOP-LEVEL-ALIAS." &&
    stg top-level-alias -h 2>/dev/null |
    grep "TOP-LEVEL-ALIAS"
'

test_expect_success 'Test running nested alias' '
    stg -C foo/bar/baz nested-alias | grep "NESTED-ALIAS" &&
    stg -C foo -C bar -C baz nested-alias -h 2>&1 >/dev/null |
    grep -e ".nested-alias. is aliased to .!echo NESTED-ALIAS." &&
    stg -C foo -C ./bar/baz/ nested-alias -h 2>/dev/null |
    grep "NESTED-ALIAS"
'

test_expect_success 'Test StGit alias help' '
    test_config stgit.alias.patch-count "series --all --count" &&
    test "$(stg patch-count)" = "0" &&
    stg patch-count -h 2>&1 >/dev/null |
    grep ".patch-count. is aliased to .series --all --count." &&
    stg patch-count -h 2>/dev/null | head -n 1 |
    grep "stg-series"
'
fi

test_done
