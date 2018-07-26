# Tests

This folder contains automated tests for this module. All of the tests are written in [Go](https://golang.org/).
Most of these are "integration tests" that deploy real infrastructure using Terraform and verify that infrastructure
works as expected using a helper library called [Terratest](https://github.com/gruntwork-io/terratest).  

## WARNING WARNING WARNING

**Note #1**: Many of these tests create real resources in an AWS account and then try to clean those resources up at
the end of a test run. That means these tests may cost you money to run! When adding tests, please be considerate of
the resources you create and take extra care to clean everything up when you're done!

**Note #2**: Never forcefully shut the tests down (e.g. by hitting `CTRL + C`) or the cleanup tasks won't run!

**Note #3**: We set `-timeout 60m` on all tests not because they necessarily take that long, but because Go has a
default test timeout of 10 minutes, after which it forcefully kills the tests with a `SIGQUIT`, preventing the cleanup
tasks from running. Therefore, we set an overlying long timeout to make sure all tests have enough time to finish and
clean up.

## Running the tests

### Prerequisites

- Install the latest version of [Go](https://golang.org/).
- Install [dep](https://github.com/golang/dep) for Go dependency management.
- Install [Terraform](https://www.terraform.io/downloads.html).
- Configure your AWS credentials using one of the [options supported by the AWS
  SDK](http://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/credentials.html). Usually, the easiest option is to
  set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables.

### Pre-existing resources

These tests expect some AWS resources to be already there to be able to run properly. Those are mostly resources that are not easy to create automatically:

- A Route53 zone where to add Vault's domain names
  - You need to provide it to the test as an environment variable `TEST_R53_ZONE_NAME`
- An ACM certificate for the ALB
  - You need to provide it to the test as an environment variable `TEST_ACM_ARN`

### One-time setup

Download Go dependencies using dep:

```
cd test
dep ensure
```

### Run all the tests

```bash
cd test
export TEST_R53_ZONE_NAME="test.example.com"
export TEST_ACM_ARN="arn:aws:acm:eu-west-1:1234567890:certificate/uev7722-434t-55g7-86ba-a882d9da1fa5"
go test -v -timeout 60m
```

### Run a specific test

To run a specific test called `TestFoo`:

```bash
cd test
export TEST_R53_ZONE_NAME="test.example.com"
export TEST_ACM_ARN="arn:aws:acm:eu-west-1:1234567890:certificate/uev7722-434t-55g7-86ba-a882d9da1fa5"
go test -v -timeout 60m -run TestFoo
```
