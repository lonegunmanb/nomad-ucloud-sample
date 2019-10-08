package main

import (
	. "./rolling"
	"fmt"
)

func main() {
	RollingUpdate([]string{
		"consul leave",
	}, func(group int) []string {
		return []string{
			resWithModule(fmt.Sprintf("ucloud_instance.consul_server[%d]", group)),
			resWithModule(fmt.Sprintf("null_resource.install_consul_server[%d]", group)),
		}
	}, []string{
		"config_consul",
	})
}

func resWithModule(res string) string {
	return fmt.Sprintf("module.consul_servers.%s", res)
}
