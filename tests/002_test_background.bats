# -*- mode: sh -*-

bats_require_minimum_version 1.5.0

@test "Start container" {
      docker stop -t 0 bats-netbsd || true
      docker rm bats-netbsd || true
      docker run --device=/dev/kvm --name bats-netbsd -d ${DOCKER_IMAGE}
}

@test "Wait for NetBSD to have booted" {
      docker exec -it bats-netbsd bsd true
}

@test "Test 'docker exec' succeeds" {
      docker exec -it bats-netbsd bsd uname -a
}

@test "Test 'docker exec' with unknown command" {
      run -127 docker exec -it bats-netbsd bsd unknowncommand
}

@test "Bash shell should be installed and work" {
      run docker exec -it bats-netbsd bsd bash -c 'uname\ -a'
      echo "$output"
      [[ "$output" == "NetBSD netbsd "* ]]
      [ "$status" == 0 ]
}

@test "Container logs should include kernel output" {
      run docker logs bats-netbsd 
      echo "$output" | egrep -q "The NetBSD Foundation"
      echo "$output" | egrep -q "Created tmpfs"
}

@test "Container status should be healthy" {
      sleep 30
      run docker inspect --format='{{json .State.Health.Status}}' bats-netbsd
      echo "Status: $output"
      [ "$output" == '"healthy"' ]
}

@test "Stop container" {
      docker stop bats-netbsd
}

@test "NetBSD should shut down cleanly" {
      run docker logs bats-netbsd
      echo "$output" | egrep -q 'syncing disks'
}

@test "Remove container" {
      docker rm bats-netbsd
}