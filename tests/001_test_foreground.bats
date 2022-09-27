# -*- mode: sh -*-

@test "Test running commands directly" { 
  run docker run --device=/dev/kvm --rm -it ${DOCKER_IMAGE} -q uname -a
  [[ "$output" == "NetBSD netbsd "* ]]
  [ "$status" == 0 ]
}

@test "Only command output should be output" { 
  run docker run --device=/dev/kvm --rm -it ${DOCKER_IMAGE} -q echo -n only-command-output
  [[ "$output" == "only-command-output" ]]
  [ "$status" == 0 ]
}