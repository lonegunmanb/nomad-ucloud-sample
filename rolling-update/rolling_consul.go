package main

import (
	. "./rolling"
)

type ConsulTaint struct {
	TaintResInModuleGroupPattern
	TaintResByName
}

func (c ConsulTaint) Match(res string) bool {
	return c.TaintResInModuleGroupPattern.Match(res) || c.TaintResByName.Match(res)
}

type ConsulUpdate struct {
	NodeDrain
	ConsulTaint
}

func main() {
	a := ReadArgs()
	ExecuteTaint(ConsulUpdate{
		NodeDrain: NodeDrain{
			Cmds: []string{
				"consul leave",
			},
			IpProperty: *a.IpProperty,
			Group:      *a.Group,
			Password:   *a.Password,
		},
		ConsulTaint: ConsulTaint{
			TaintResInModuleGroupPattern: TaintResInModuleGroupPattern{
				Module: *a.Module,
				Group:  *a.Group,
				Res: []string{
					"ucloud_instance.consul_server",
					"null_resource.install_consul_server",
				},
			},
			TaintResByName: TaintResByName{
				Res: []string{
					"config_consul",
				},
			},
		},
	})
}
