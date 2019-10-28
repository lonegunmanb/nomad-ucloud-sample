package main

import . "./rolling"

type NomadUpdate struct {
	TaintModuleGroupPattern
	NodeDrain
}

func main() {
	a := ReadArgs()
	ExecuteTaint(NomadUpdate{
		TaintModuleGroupPattern: TaintModuleGroupPattern{
			Module: *a.Module,
			Group:  *a.Group,
		},
		NodeDrain: NodeDrain{
			Cmds: []string{
				"nomad node eligibility -self -disable",
				"nomad node drain -self -enable -force",
			},
			Password:   *a.Password,
			Group:      *a.Group,
			IpProperty: *a.IpProperty,
		},
	})
}
