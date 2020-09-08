package main

import (
	"github.com/faiq/terraform-provider-aws-spot-instance/aws"
	"github.com/hashicorp/terraform-plugin-sdk/plugin"
)

func main() {
	plugin.Serve(&plugin.ServeOpts{
		ProviderFunc: aws.Provider})
}
