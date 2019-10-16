package rolling_test

import (
	"../rolling"
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestTaintModuleWithValidRes(t *testing.T) {
	validInputs := []string{
		"module.broker0.null_resource.config_consul[0]",
		"module.broker0.ucloud_disk.data_disk[2]",
		"module.broker0.data.null_data_source.finish_signal",
	}
	for _, input := range validInputs {
		t.Run(input, func(t *testing.T) {
			taint := rolling.TaintModuleGroupPattern{
				Module: "broker",
				Group:  0,
			}
			match := taint.Match(input)
			assert.True(t, match)

		})
	}
}

func TestTaintModuleWithInvalidRes(t *testing.T) {
	invalidInputs := []string{
		"module.broker1.null_resource.config_consul[0]",
		"module.nameServerInternalLb0.data.template_file.add-loopback-script",
		"null_resource.setup_loopback_for_internal_lb[0]",
	}
	for _, input := range invalidInputs {
		t.Run(input, func(t *testing.T) {
			taint := rolling.TaintModuleGroupPattern{
				Module: "broker",
				Group:  0,
			}
			match := taint.Match(input)
			assert.False(t, match)

		})
	}
}

func TestTaintResInModuleWithValidRes(t *testing.T) {
	validInputs := []string{
		"module.consul_servers.data.template_file.consul-config[0]",
		"module.consul_servers.null_resource.config_consul[0]",
		"module.consul_servers.ucloud_eip_association.consul_ip[0]",
	}
	for _, input := range validInputs {
		t.Run(input, func(t *testing.T) {
			taint := rolling.TaintResInModuleGroupPattern{
				Module: "consul_servers",
				Group:  0,
				Res: []string{
					"data.template_file.consul-config",
					"null_resource.config_consul",
					"ucloud_eip_association.consul_ip",
				},
			}
			match := taint.Match(input)
			assert.True(t, match)
		})
	}
}

func TestTaintResInModuleWithInvalidRes(t *testing.T) {
	invalidInputs := []string{
		"module.consul_servers.ucloud_instance.consul_server[0]",
		"module.nameServer0.null_resource.config_consul[0]",
		"ucloud_lb.name_server_internal_lb",
	}
	for _, input := range invalidInputs {
		t.Run(input, func(t *testing.T) {
			taint := rolling.TaintResInModuleGroupPattern{
				Module: "consul_servers",
				Group:  0,
				Res: []string{
					"data.template_file.consul-config",
					"null_resource.config_consul",
					"ucloud_eip_association.consul_ip",
				},
			}
			match := taint.Match(input)
			assert.False(t, match)
		})
	}
}

func TestTaintResByNameWithValidRes(t *testing.T) {
	validInputs := []string{
		"module.nomad_server2.null_resource.config_consul[0]",
		"module.nomad_server0.null_resource.config_consul[0]",
		"module.nameServer0.null_resource.config_consul[0]",
	}
	for _, input := range validInputs {
		t.Run(input, func(t *testing.T) {
			taint := rolling.TaintResByName{
				Res: []string{
					"config_consul",
				},
			}
			match := taint.Match(input)
			assert.True(t, match)
		})
	}
}

func TestTaintResByNameWithInvalidRes(t *testing.T) {
	invalidInputs := []string{
		"module.nameServer2.null_resource.setup[1]",
		"module.nomad_server0.null_resource.setup[0]",
		"ucloud_lb.name_server_internal_lb",
	}
	for _, input := range invalidInputs {
		t.Run(input, func(t *testing.T) {
			taint := rolling.TaintResByName{
				Res: []string{
					"config_consul",
				},
			}
			match := taint.Match(input)
			assert.False(t, match)
		})
	}
}
