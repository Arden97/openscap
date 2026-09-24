#!/usr/bin/env bash

. $builddir/tests/test_common.sh

set -e -o pipefail

function test_probes_shadow_stripped {

    probecheck "shadow" || return 255

    local ret_val=0
    local DF="${srcdir}/test_probes_shadow_stripped.xml"
    local RF="$(mktemp results.XXXXXXX.xml)"

    [ -f $RF ] && rm -f $RF

    tmpdir=$(make_temp_dir /tmp "test_probes_shadow_stripped")
    mkdir -p "${tmpdir}/etc"
    cat > "${tmpdir}/etc/shadow" << 'SHADOW'
sha512user:$6$saltsalt$longhashvaluethatneedstoberedacted:19000:0:99999:7:::
lockedhash:!!$6$anothersalt$anotherlonghashvalue:19000:0:99999:7:::
lockednohash:!:19000:0:99999:7:::
disabled:*:19000:0:99999:7:::
neverset:!!:19000:0:99999:7:::
SHADOW

    export OSCAP_PROBE_ROOT="${tmpdir}"

    $OSCAP oval eval --results $RF $DF

    unset OSCAP_PROBE_ROOT
    rm -rf "${tmpdir}"

    if [ -f $RF ]; then
	verify_results "def" $DF $RF 5 && verify_results "tst" $DF $RF 5
	ret_val=$?
    else
	ret_val=1
    fi

    if grep -q 'longhashvaluethatneedstoberedacted\|anotherlonghashvalue\|saltsalt\|anothersalt' $RF; then
        ret_val=1
    fi

    rm -f $RF
    return $ret_val
}

test_init

test_run "test_probes_shadow_stripped" test_probes_shadow_stripped

test_exit
