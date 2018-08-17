# -*- mode: sh -*-

@test "Start container" {
      docker run --rm --name bats-netbsd -d ${DOCKER_IMAGE}
}

@test "Wait for NetBSD to have booted" {
      docker exec -it bats-netbsd bsd true
}

@test "Test 'docker exec' succeeds" {
      docker exec -it bats-netbsd bsd uname -a
}

@test "Test 'docker exec' with failure" {
      run docker exec -it bats-netbsd bsd unknowncommand
      [ "$status" -ne 0 ]
}


@test "Bash shell should be installed and work." {
      run docker exec -it bats-netbsd bsd bash -c 'uname\ -a'
      echo "$output"
      [[ "$output" == "NetBSD netbsd "* ]]
      [ "$status" == 0 ]
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
