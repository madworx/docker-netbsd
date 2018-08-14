@test "Test running commands directly" { 
  run docker run -it ${DOCKER_IMAGE} -q uname -a
  [[ "$output" == "NetBSD netbsd "* ]]
  [ "$status" == 0 ]
}
