#!/usr/bin/env bats

# Unit tests for src/ssh.sh: host resolution and the sb-pull call wrapper.

setup() {
  export PATH="$BATS_TEST_DIRNAME/mocks/bin:$PATH"
  export alfred_workflow_data="$BATS_TEST_TMPDIR/data"
  mkdir -p "$alfred_workflow_data"
  export SEEDBOX_SSH="$BATS_TEST_DIRNAME/mocks/bin/ssh"
}

@test "ssh.sh: ssh_host falls back to the default" {
  run bash -c 'unset SEEDBOX_SSH_HOST; . src/ssh.sh; ssh_host'
  [ "$output" = "beaver.h.g7v.io" ]
}

@test "ssh.sh: ssh_host honors the env override" {
  run bash -c 'export SEEDBOX_SSH_HOST=other.host; . src/ssh.sh; ssh_host'
  [ "$output" = "other.host" ]
}

@test "ssh.sh: ssh_host reads the config file, ignoring comments" {
  printf '# comment\n\nconfigured.host\n' > "$alfred_workflow_data/ssh-host"
  run bash -c '. src/ssh.sh; ssh_host'
  [ "$output" = "configured.host" ]
}

@test "ssh.sh: sb_pull returns the agent JSON" {
  run bash -c '. src/ssh.sh; sb_pull status'
  echo "$output" | jq -e 'has("jobs")' >/dev/null
}
