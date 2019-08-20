cat>>/etc/consul.d/consul.hcl<<-EOF
acl = {
    enabled = true,
    default_policy = "deny",
    enable_token_persistence = true
    enable_key_list_policy = true
}
EOF