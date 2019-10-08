package main

import (
	. "./rolling"
)

func main() {
	RollingUpdate([]string{
		"consul leave",
	})
}
