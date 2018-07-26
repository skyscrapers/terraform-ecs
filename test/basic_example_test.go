package test

import (
	"testing"
	"fmt"
	"time"
	"os"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/hashicorp/vault/api"
)

// From: https://www.vaultproject.io/api/system/health.html
type VaultStatus int

const (
	Leader        VaultStatus = 200
	Standby                   = 429
	Uninitialized             = 501
	Sealed                    = 503
)

type VaultCluster struct {
	main         *api.Client
	vault1       *api.Client
	vault2       *api.Client
	initResponse *api.InitResponse
}

// An example of how to test the simple Terraform module in examples/basic using Terratest.
func TestBasicExample(t *testing.T) {
	t.Parallel()

	// The path to where our Terraform code is located
	exampleFolder := "../examples/basic"

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, exampleFolder)
		// At the end of the test, run `terraform destroy` to clean up any resources that were created
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy", func() {
		uniqueId := random.UniqueId()
		projectName := fmt.Sprintf("vault-%s", uniqueId)

		terraformOptions := &terraform.Options{
			TerraformDir: exampleFolder,

			// Variables to pass to our Terraform code using -var options
			Vars: map[string]interface{}{
				"vault_acm_arn": os.Getenv("TEST_ACM_ARN"),
				"vault_dns_root": os.Getenv("TEST_R53_ZONE_NAME"),
				"le_email": os.Getenv("TEST_LE_EMAIL"),
				"vault_version": "0.9.3",
				"project": projectName,
				"le_staging": true,
				"lb_internal": false,
			},

			EnvVars: map[string]string{
				"AWS_DEFAULT_REGION": "eu-west-1",
			},
		}

		test_structure.SaveTerraformOptions(t, exampleFolder, terraformOptions)

		// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "validate", func() {
		initializeAndUnsealVaultCluster(t)
	})
}

// Initialize the Vault cluster and unseal each of the nodes via the Vault API
func initializeAndUnsealVaultCluster(t *testing.T) {
	cluster := findVaultClusterNodes(t)

	waitForVaultToBoot(t, cluster)
	initializeVault(t, &cluster)

	assertStatus(t, cluster.vault1, Sealed)
	unsealVaultNode(t, cluster.vault1, cluster.initResponse.Keys)
	assertStatus(t, cluster.vault1, Leader)
	assertStatus(t, cluster.main, Leader)

	assertStatus(t, cluster.vault2, Sealed)
	unsealVaultNode(t, cluster.vault2, cluster.initResponse.Keys)
	assertStatus(t, cluster.vault2, Standby)
}

// Create the api objects for the three vault endpoints: main, vault1 and vault2
func findVaultClusterNodes(t *testing.T) VaultCluster {
	main, err := api.NewClient(&api.Config{
		Address: fmt.Sprintf("https://vault.%s", os.Getenv("TEST_R53_ZONE_NAME")),
	})

	if err != nil {
		t.Fatalf("Failed to initialize Vault client for main endpoint")
	}

	vault1, err := api.NewClient(&api.Config{
		Address: fmt.Sprintf("https://vault1.%s", os.Getenv("TEST_R53_ZONE_NAME")),
	})

	if err != nil {
		t.Fatalf("Failed to initialize Vault client for vault1 endpoint")
	}

	vault2, err := api.NewClient(&api.Config{
		Address: fmt.Sprintf("https://vault2.%s", os.Getenv("TEST_R53_ZONE_NAME")),
	})

	if err != nil {
		t.Fatalf("Failed to initialize Vault client for vault2 endpoint")
	}

	return VaultCluster{
		main: main,
		vault1: vault1,
		vault2: vault2,
	}
}

// Initialize the Vault cluster, filling in the unseal keys in the given vaultCluster struct
func initializeVault(t *testing.T, cluster *VaultCluster) {
	logger.Logf(t, "Initializing the cluster")

	init, err := cluster.main.Sys().Init(&api.InitRequest{
		SecretShares: 1,
		SecretThreshold: 1,
	})

	if err != nil {
		t.Fatalf("Failed to initialize Vault due to error %v", err)
	}

	cluster.initResponse = init
}

// Unseal the given Vault server using the given unseal keys
func unsealVaultNode(t *testing.T, node *api.Client, unsealKeys []string) {
	logger.Logf(t, "Unsealing Vault on host %s", node.Address())

	for _, unsealKey := range unsealKeys {
		if _, err := node.Sys().Unseal(unsealKey); err != nil {
			t.Fatalf("Error unsealing Vault due to error %v", err)
		}
	}
}

// Wait until the Vault servers are booted the very first time on the EC2 Instance. As a simple solution, we simply
// query the Vault api until it gives the correct response code (should be Uninitialized).
func waitForVaultToBoot(t *testing.T, cluster VaultCluster) {
	logger.Logf(t, "Waiting for Vault to boot the first time on host %s. Expecting it to be in uninitialized status (%d).", cluster.main.Address(), int(Uninitialized))
	assertStatus(t, cluster.main, Uninitialized)
}

// Check that the Vault node at the given host has the given
func assertStatus(t *testing.T, node *api.Client, expectedStatus VaultStatus) {
	description := fmt.Sprintf("Check that Vault %s has status %d", node.Address(), int(expectedStatus))
	logger.Logf(t, description)

	maxRetries := 30
	sleepBetweenRetries := 10 * time.Second

	out := retry.DoWithRetry(t, description, maxRetries, sleepBetweenRetries, func() (string, error) {
		return checkStatus(t, node, expectedStatus)
	})

	logger.Logf(t, out)
}

// Check the status of the given Vault node and ensure it matches the expected status.
func checkStatus(t *testing.T, node *api.Client, expectedStatus VaultStatus) (string, error) {
  health, err := node.Sys().Health()

	if err != nil {
		return "", err
	}

	status := buildStatusCode(health)
	if status == int(expectedStatus) {
		return fmt.Sprintf("Got expected status code %d", status), nil
	} else {
		return "", fmt.Errorf("Expected status code %d, but got %d", int(expectedStatus), status)
	}
}

func buildStatusCode(health *api.HealthResponse) (int) {
	if !health.Initialized {
		return 501
	}
	if health.Sealed {
		return 503
	}
	if health.Standby {
		return 429
	}

	return 200
}
