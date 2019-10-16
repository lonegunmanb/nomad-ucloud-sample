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

var DryRun = false

type RemoteCleanupOnLeave interface {
	OnLeave()
}

type NodeDrain struct {
	Cmds       []string
	IpProperty string
	Group      int
	Password   string
}

func (n NodeDrain) OnLeave() {
	ips := ReadIp(n.IpProperty, n.Group)
	for _, ip := range ips {
		RemoteExecuteCmd(n.Cmds, ip, n.Password)
	}
}

type Taint interface {
	Match(res string) bool
}

type TaintModuleGroupPattern struct {
	Module string
	Group  int
}

func (t TaintModuleGroupPattern) Match(res string) bool {
	return inModuleGroup(res, t.Module, t.Group)
}

func inModuleGroup(res string, module string, group int) bool {
	return strings.HasPrefix(res, fmt.Sprintf("module.%s%d", module, group))
}

func inModule(res string, module string) bool {
	return strings.HasPrefix(res, fmt.Sprintf("module.%s", module))
}

type TaintResInModuleGroupPattern struct {
	Module string
	Group  int
	Res    []string
}

func (t TaintResInModuleGroupPattern) Match(res string) bool {
	return linq.From(t.Res).AnyWith(func(resName interface{}) bool {
		return inModule(res, t.Module) && contains(res, fmt.Sprintf("%s[%d]", resName.(string), t.Group))
	})
}

func contains(res string, resName string) bool {
	return strings.Contains(res, resName)
}

type TaintResByName struct {
	Res []string
}

func (t TaintResByName) Match(res string) bool {
	return linq.From(t.Res).AnyWith(func(r interface{}) bool {
		return contains(res, fmt.Sprintf("%s", r.(string)))
	})
}

func GetAllRes() []string {
	output, err := ExecCmd("terraform show | grep '#' | tr -d ':'  | tr -d '#' | tr -d ' '", Dir, nil, nil)
	if err != nil {
		panic(err)
	}
	var res []string
	scanner := bufio.NewScanner(strings.NewReader(output))
	for scanner.Scan() {
		r := scanner.Text()
		res = append(res, r)
	}
	err = scanner.Err()
	if err != nil {
		panic(err)
	}
	return res
}

func ExecuteTaint(taintPolicy Taint) {
	if onLeave, ok := taintPolicy.(RemoteCleanupOnLeave); ok && !DryRun {
		onLeave.OnLeave()
	}
	res := GetAllRes()
	for _, r := range res {
		if taintPolicy.Match(r) {
			println(fmt.Sprintf("terraform taint %s", r))
			if !DryRun {
				_, _ = ExecCmd(fmt.Sprintf("terraform taint %s", r), Dir, os.Stdout, os.Stderr)
			}
		}
	}
}

type Arg struct {
	Password   *string
	Group      *int
	Module     *string
	IpProperty *string
}

func ReadArgs() Arg {
	password := flag.String("pass", "", "ssh Password")
	group := flag.Int("group", -1, "update Group")
	module := flag.String("module", "", "")
	ipProperty := flag.String("ip-property", "", "")
	dryRun := flag.Bool("dry", false, "")
	flag.Parse()
	DryRun = *dryRun
	return Arg{
		Password:   password,
		Group:      group,
		Module:     module,
		IpProperty: ipProperty,
	}
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
