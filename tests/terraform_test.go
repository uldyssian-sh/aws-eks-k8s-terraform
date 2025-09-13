package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformVPCModule(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform/modules/vpc",
		Vars: map[string]interface{}{
			"cluster_name":          "test-cluster",
			"vpc_cidr":             "10.0.0.0/16",
			"environment":          "test",
			"availability_zones":   []string{"eu-central-1a", "eu-central-1b"},
			"private_subnet_cidrs": []string{"10.0.1.0/24", "10.0.2.0/24"},
			"public_subnet_cidrs":  []string{"10.0.101.0/24", "10.0.102.0/24"},
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndPlan(t, terraformOptions)
}

func TestTerraformEKSModule(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform/modules/eks",
		Vars: map[string]interface{}{
			"cluster_name":       "test-cluster",
			"kubernetes_version": "1.29",
			"environment":        "test",
			"vpc_id":            "vpc-12345678",
			"private_subnet_ids": []string{"subnet-12345678", "subnet-87654321"},
			"public_subnet_ids":  []string{"subnet-11111111", "subnet-22222222"},
			"node_groups": map[string]interface{}{
				"main": map[string]interface{}{
					"instance_types": []string{"t3.medium"},
					"capacity_type":  "ON_DEMAND",
					"min_size":      1,
					"max_size":      3,
					"desired_size":  2,
					"disk_size":     20,
				},
			},
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndPlan(t, terraformOptions)
}