package rolling

import (
	"bufio"
	"flag"
	"fmt"
	"github.com/ahmetb/go-linq"
	"golang.org/x/crypto/ssh"
	"io"
	"net"
	"os"
	"os/exec"
	"strings"
)

const Dir = "../"

type RemoteCleanupOnLeave interface {
	OnLeave(ips []string, password *string, cmds []string)
}

type TaintPattern interface {
	Match(res string) bool
}

type TaintModuleGroupPattern struct {
	module string
	group  int
}

func (t TaintModuleGroupPattern) Match(res string) bool {
	return strings.HasPrefix(res, fmt.Sprintf("module.%s%d", t.module, t.group))
}

type TaintResInModuleGroupPattern struct {
	module string
	group  int
	res    []string
}

func (t TaintResInModuleGroupPattern) Match(res string) bool {
	return linq.From(t.res).AnyWith(func(resName interface{}) bool {
		return strings.HasPrefix(resName.(string), fmt.Sprintf("%s.", t.module))
	})
}

func RollingUpdate(onLeaveNodeCmds []string, moduleResToTaint func(int) []string, resToTaint []string) {
	password, module, ipProperty, group := ReadArgs()
	ips := ReadIp(*ipProperty, *group)
	OnLeave(ips, password, onLeaveNodeCmds)
	if moduleResToTaint == nil {
		TaintEntireModule(*module, *group)
	} else {
		TaintResInModule(*group, moduleResToTaint)
	}
	if resToTaint != nil {
		TaintResContainsName(resToTaint)
	}
	Update()
}

func TaintResInModule(group int, resToTaint func(int) []string) {
	for _, res := range resToTaint(group) {
		taintCmd := fmt.Sprintf("terraform taint %s", res)
		println(taintCmd)
		_, _ = ExecCmd(taintCmd, Dir, os.Stdout, os.Stderr)
	}
}

func TaintResContainsName(resources []string) {
	for _, res := range resources {
		taintCmd := fmt.Sprintf("sh taint_res.sh %s", res)
		_, _ = ExecCmd(taintCmd, Dir, os.Stdout, os.Stderr)
	}
}

func TaintEntireModule(module string, group int) {
	var taintCmd string
	if group != -1 {
		taintCmd = fmt.Sprintf("sh taint_module.sh %s%d", module, group)
	} else {
		taintCmd = fmt.Sprintf("sh taint_module.sh %s", module)
	}
	println(taintCmd)
	_, _ = ExecCmd(taintCmd, Dir, os.Stdout, os.Stderr)
}

func Update() {
	println("updating")
	cmd := "terraform apply --auto-approve -input=false -var-file=terraform.tfvars.json"
	remoteVarFile := "/backend/remote.tfvars"
	remoteVarExist := FileExist(remoteVarFile)
	if remoteVarExist {
		cmd += fmt.Sprintf(" -var-file=%s", remoteVarFile)
	}
	_, err := ExecCmd(cmd, Dir, os.Stdout, os.Stderr)
	if err != nil {
		panic(err)
	}
}

var FileExist = func(path string) bool {
	remoteVarExist := true
	if _, err := os.Stat(path); os.IsNotExist(err) {
		remoteVarExist = false
	}
	return remoteVarExist
}

func OnLeave(ips []string, password *string, cmds []string) {
	for _, ip := range ips {
		RemoteExecuteCmd(cmds, ip, *password)
	}
}

func ReadArgs() (*string, *string, *string, *int) {
	password := flag.String("pass", "", "ssh password")
	group := flag.Int("group", -1, "update group")
	module := flag.String("module", "", "")
	ipProperty := flag.String("ip-property", "", "")
	flag.Parse()
	return password, module, ipProperty, group
}

var ReadIp = func(name string, group int) []string {
	if name == "" {
		return []string{}
	}
	output, err := ExecCmd(fmt.Sprintf("terraform output -json | jq -r '.%s.value[%d]|.[]'", name, group), Dir, nil, nil)
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

var ExecCmd = func(cmdString string, dir string, stdout io.Writer, stderr io.Writer) (string, error) {
	cmd := &exec.Cmd{
		Path:   "/bin/bash",
		Args:   []string{"/bin/bash", "-c", cmdString},
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

func RemoteExecuteCmd(cmd []string, hostname string, password string) {
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
