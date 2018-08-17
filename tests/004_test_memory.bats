# -*- mode: sh -*-

KERNEL_RAM_OK=64

verify() {
    MEMTOT=$(docker run --rm -it -e SYSTEM_MEMORY=$1 ${DOCKER_IMAGE} -q cat /proc/meminfo | awk -F'[ :]+' '$1 == "MemTotal" {print $2}' || exit 1)
    [[ $(($1-${MEMTOT}/1024)) -lt ${KERNEL_RAM_OK} ]]
}

@test "Test 512M RAM" {
    verify 512
}

@test "Test 256M RAM" {
    verify 256
}

@test "Test 384M RAM" {
    verify 256
}

