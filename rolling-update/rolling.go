package main

import (
	. "./rolling"
)

func main() {
	RollingUpdate([]string{
		"nomad node eligibility -self -disable",
		"nomad node drain -self -enable",
	}, nil, nil)
}
