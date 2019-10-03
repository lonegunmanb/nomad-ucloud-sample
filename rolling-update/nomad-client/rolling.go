package main

import (
	"bufio"
	"flag"
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
	cmd := "terraform apply --auto-approve -input=false -var-file=terraform.tfvars.json"
	remoteVarExist := true
	if _, err := os.Stat("/backend/remote.tfvars"); os.IsNotExist(err) {
		remoteVarExist = false
	}
	if remoteVarExist {
		cmd += " -var-file=/backend/remote.tfvars"
	}
	_, err := execCmd(cmd, "../../", os.Stdout, os.Stderr)
	if err != nil {
		panic(err)
	}
}

func setIneligible(ips []string, password *string) {
	for _, ip := range ips {
		remoteExecuteCmd([]string{
			fmt.Sprintf("echo set node ineligiblty %s", ip),
			"nomad node eligibility -self -disable",
			fmt.Sprintf("echo drain node %s", ip),
			"nomad node drain -self -enable",
		}, ip, *password)
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

var ReadIp = func(name string, group int) []string {
	if name == "" {
		return []string{}
	}
	output, err := execCmd(fmt.Sprintf("terraform output -json | jq -r '.%s.value[%d]|.[]'", name, group), "../../", nil, nil)
	if err != nil {
		panic(err)
	}
	var ips []string
	scanner := bufio.NewScanner(strings.NewReader(output))
	for scanner.Scan() {
		ip := scanner.Text()
		ips = append(ips, ip)
	}
	err = scanner.Err()
	if err != nil {
		panic(err)
	}
	return ips
}

func execCmd(cmdStrings string, dir string, stdout io.Writer, stderr io.Writer) (string, error) {
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

func remoteExecuteCmd(cmd []string, hostname string, password string) {
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

	for _, command := range cmd {

		session, err := conn.NewSession()

		if err != nil {
			panic(err)
		}

		session.Stdout = os.Stdout
		session.Stderr = os.Stderr
		err = session.Run(command)
		if err != nil {
			panic(err)
		}
		session.Close()
	}
}
