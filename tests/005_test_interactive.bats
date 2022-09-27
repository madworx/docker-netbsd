@test "Test interactive mode using expect" {
    docker stop -t 0 bats-netbsd || true
    docker rm bats-netbsd || true
    expect -f - <<EOT
set docker [list docker run --name bats-netbsd --device=/dev/kvm --rm -it "${DOCKER_IMAGE}"]
spawn {*}\$docker
set timeout 120

expect "login: "                  { send "root\n" }
expect "netbsd#"                  { send "id\n" }
expect "uid=0(root) gid=0(wheel)" { send "poweroff\n" }
expect eof
EOT
}