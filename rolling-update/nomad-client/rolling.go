package main

import (
	"bufio"
	"bytes"
	"flag"
	_ "flag"
	"fmt"
	"golang.org/x/crypto/ssh"
	"io"
	"net"
	"os"
	"os/exec"
	"strings"
)

func main() {
	password, module, ipProperty, group := readArgs()
	ips := ReadIp(*ipProperty, *group)
	setIneligible(ips, password)
	taint(*module, *group)
	update()
}

func taint(module string, group int) {
	taintCmd := fmt.Sprintf("sh taint_module.sh %s%d", module, group)
	println(taintCmd)
	_, _ = execCmd(taintCmd, "../../", os.Stdout, os.Stderr)
}

func update() {
	println("updating")
	_, err := execCmd("terraform apply --auto-approve -input=false", "../../", os.Stdout, os.Stderr)
	if err != nil {
		panic(err)
	}
}

func setIneligible(ips string, password *string) {
	scanner := bufio.NewScanner(strings.NewReader(ips))
	for scanner.Scan() {
		ip := scanner.Text()

		output := remoteExecuteCmd([]string{
			fmt.Sprintf("echo set node ineligiblty %s", ip),
			"nomad node eligibility -self -disable",
			fmt.Sprintf("echo drain node %s", ip),
			"nomad node drain -self -enable",
		}, ip, *password)
		println(output)
	}
	err := scanner.Err()
	if err != nil {
		panic(err)
	}
}

func readArgs() (*string, *string, *string, *int) {
	password := flag.String("pass", "", "ssh password")
	group := flag.Int("group", 0, "update group")
	module := flag.String("module", "", "")
	ipProperty := flag.String("ip-property", "", "")
	flag.Parse()
	return password, module, ipProperty, group
}

var ReadIp = func(name string, group int) string {
	output, err := execCmd(fmt.Sprintf("terraform output -json | jq -r '.%s.value[%d]|.[]'", name, group), "../../", nil, nil)
	if err != nil {
		panic(err)
	}
	return output
}

func execCmd(cmdStrings string, dir string, stdout io.Writer, stderr io.Writer) (string, error) {
	// cmd := exec.Command("/bin/bash", "-c", cmdStrings)
	cmd := &exec.Cmd{
		Path:   "/bin/bash",
		Args:   []string{"/bin/bash", "-c", cmdStrings},
		Dir:    dir,
		Stdout: stdout,
		Stderr: stderr,
	}
	cmd.Dir = dir
	if stdout == nil && stderr == nil {
		output, err := cmd.Output()
		return string(output), err
	}
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return "", cmd.Run()
}

func remoteExecuteCmd(cmd []string, hostname string, password string) string {
	conn, err := ssh.Dial("tcp", hostname+":22", &ssh.ClientConfig{
		User: "root",
		Auth: []ssh.AuthMethod{ssh.Password(password)},
		HostKeyCallback: func(hostname string, remote net.Addr, key ssh.PublicKey) error {
			return nil
		},
	})

	if err != nil {
		panic(err)
	}
	defer conn.Close()

	var stdoutBuf bytes.Buffer

	for _, command := range cmd {

		session, err := conn.NewSession()

		if err != nil {
			panic(err)
		}

		session.Stdout = &stdoutBuf
		err = session.Run(command)
		if err != nil {
			panic(err)
		}
		session.Close()
	}

	return hostname + ":\n" + stdoutBuf.String()
}
