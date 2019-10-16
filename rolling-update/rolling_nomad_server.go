package main

import . "./rolling"

type NomadServerUpdate struct {
	TaintModuleGroupPattern
}

func main() {
	a := ReadArgs()
	ExecuteTaint(NomadServerUpdate{
		TaintModuleGroupPattern: TaintModuleGroupPattern{
			Module: *a.Module,
			Group:  *a.Group,
		},
	})
}
