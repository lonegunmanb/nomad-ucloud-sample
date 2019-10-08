package rolling_test

import (
	"../rolling"
	"github.com/magiconair/properties/assert"
	"github.com/prashantv/gostub"
	"io"
	"testing"
)

func TestUpdateWithoutRemoteVar(t *testing.T) {
	stub := gostub.Stub(&rolling.FileExist, func(path string) bool {
		return false
	})
	defer stub.Reset()
	stub.Stub(&rolling.ExecCmd, func(cmdString string, dir string, stdout io.Writer, stderr io.Writer) (string, error) {
		assert.Equal(t, cmdString, "terraform apply --auto-approve -input=false -var-file=terraform.tfvars.json")
		assert.Equal(t, dir, "../")
		return "", nil
	})
	rolling.Update()
}

func TestUpdateWithRemoteVar(t *testing.T) {
	stub := gostub.Stub(&rolling.FileExist, func(path string) bool {
		return true
	})
	defer stub.Reset()
	stub.Stub(&rolling.ExecCmd, func(cmdString string, dir string, stdout io.Writer, stderr io.Writer) (string, error) {
		assert.Equal(t, cmdString, "terraform apply --auto-approve -input=false -var-file=terraform.tfvars.json -var-file=/backend/remote.tfvars")
		assert.Equal(t, dir, "../")
		return "", nil
	})
}

func TestTaintModuleWithGroup(t *testing.T) {
	module := "module"
	group := 0
	gostub.Stub(&rolling.ExecCmd, func(cmdString string, dir string, stdout io.Writer, stderr io.Writer) (string, error) {
		assert.Equal(t, cmdString, "sh taint_module.sh module0")
		assert.Equal(t, "../", dir)
		return "", nil
	})
	rolling.TaintEntireModule(module, group)
}

func TestTaintModuleWithoutGroup(t *testing.T) {
	module := "module"
	group := -1
	gostub.Stub(&rolling.ExecCmd, func(cmdString string, dir string, stdout io.Writer, stderr io.Writer) (string, error) {
		assert.Equal(t, cmdString, "sh taint_module.sh module")
		assert.Equal(t, "../", dir)
		return "", nil
	})
	rolling.TaintEntireModule(module, group)
}
