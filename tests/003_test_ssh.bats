# -*- mode: sh -*-

@test "Generate OpenSSH keys" {
    rm -f temp.key temp.key.pub 2>/dev/null || true
    run ssh-keygen -N '' -t rsa -f temp.key < /dev/null
    [ $status -eq 0 ]
    [ -f temp.key ]
    [ -f temp.key.pub ]
}

@test "Start container" {
    docker run -p 2222:22 --rm -e SSH_PUBKEY="$(cat temp.key.pub)" --name bats-netbsd -d ${DOCKER_IMAGE}
}

@test "Import NetBSD generated ssh host keys" {
    docker exec -it bats-netbsd /bin/bash -c 'cat /bsd/etc/ssh/ssh_host_*_key.pub' | sed 's#^#localhost,127.0.0.1 #' > netbsd_ssh_host_keys
}

@test "Wait for NetBSD to have booted" {
    docker exec -it bats-netbsd bsd true
}

@test "Test ssh using public-key works" {
    run ssh                                         \
        -p 2222                                     \
        -i temp.key                                 \
        -o UserKnownHostsFile=netbsd_ssh_host_keys  \
        -o StrictHostKeyChecking=yes                \
        -o ChallengeResponseAuthentication=no       \
        -o PasswordAuthentication=false             \
        -o KbdInteractiveAuthentication=no          \
        root@localhost                              \
        uptime
    echo $output
    [ $status -eq 0 ]
}

@test "Stop container" {
    docker stop bats-netbsd
}
