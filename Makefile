SWEEP?=us-east-1,us-west-2
TEST?=./...
SWEEP_DIR?=./aws
GOFMT_FILES?=$$(find . -name '*.go' |grep -v vendor)
PKG_NAME=aws
WEBSITE_REPO=github.com/hashicorp/terraform-website
TEST_COUNT?=1

default: build

build: fmtcheck
	go install

gen:
	rm -f aws/internal/keyvaluetags/*_gen.go
	go generate ./...

sweep:
	@echo "WARNING: This will destroy infrastructure. Use only in development accounts."
	go test $(SWEEP_DIR) -v -sweep=$(SWEEP) $(SWEEPARGS) -timeout 60m

test: fmtcheck
	go test $(TEST) $(TESTARGS) -timeout=120s -parallel=4

testacc: fmtcheck
	@if [ "$(TESTARGS)" = "-run=TestAccXXX" ]; then \
		echo ""; \
		echo "Error: Skipping example acceptance testing pattern. Update TESTARGS to match the test naming in the relevant *_test.go file."; \
		echo ""; \
		echo "For example if updating aws/resource_aws_acm_certificate.go, use the test names in aws/resource_aws_acm_certificate_test.go starting with TestAcc and up to the underscore:"; \
		echo "make testacc TESTARGS='-run=TestAccAWSAcmCertificate_'"; \
		echo ""; \
		echo "See the contributing guide for more information: https://github.com/terraform-providers/terraform-provider-aws/blob/master/docs/contributing/running-and-writing-acceptance-tests.md"; \
		exit 1; \
	fi
	TF_ACC=1 go test ./$(PKG_NAME) -v -count $(TEST_COUNT) -parallel 20 $(TESTARGS) -timeout 120m

fmt:
	@echo "==> Fixing source code with gofmt..."
	gofmt -s -w ./$(PKG_NAME) ./awsproviderlint

# Currently required by tf-deploy compile
fmtcheck:
	@sh -c "'$(CURDIR)/scripts/gofmtcheck.sh'"

gencheck:
	@echo "==> Checking generated source code..."
	@$(MAKE) gen
	@git diff --compact-summary --exit-code || \
		(echo; echo "Unexpected difference in directories after code generation. Run 'make gen' command and commit."; exit 1)

depscheck:
	@echo "==> Checking source code with go mod tidy..."
	@go mod tidy
	@git diff --exit-code -- go.mod go.sum || \
		(echo; echo "Unexpected difference in go.mod/go.sum files. Run 'go mod tidy' command or revert any go.mod/go.sum changes and commit."; exit 1)
	@echo "==> Checking source code with go mod vendor..."
	@go mod vendor
	@git diff --compact-summary --exit-code -- vendor || \
		(echo; echo "Unexpected difference in vendor/ directory. Run 'go mod vendor' command or revert any go.mod/go.sum/vendor changes and commit."; exit 1)

lint: golangci-lint awsproviderlint

golangci-lint:
	@golangci-lint run ./$(PKG_NAME)/...

awsproviderlint:
	@awsproviderlint \
		-c 1 \
		-AT001 \
		-AT002 \
		-AT003 \
		-AT005 \
		-AT006 \
		-AT007 \
		-AT008 \
		-AWSAT001 \
		-AWSAT004 \
		-AWSR001 \
		-AWSR002 \
		-R002 \
		-R003 \
		-R004 \
		-R005 \
		-R006 \
		-R007 \
		-R008 \
		-R009 \
		-R011 \
		-R012 \
		-R013 \
		-R014 \
		-S001 \
		-S002 \
		-S003 \
		-S004 \
		-S005 \
		-S006 \
		-S007 \
		-S008 \
		-S009 \
		-S010 \
		-S011 \
		-S012 \
		-S013 \
		-S014 \
		-S015 \
		-S016 \
		-S017 \
		-S018 \
		-S019 \
		-S020 \
		-S021 \
		-S022 \
		-S023 \
		-S024 \
		-S025 \
		-S026 \
		-S027 \
		-S028 \
		-S029 \
		-S030 \
		-S031 \
		-S032 \
		-S033 \
		-S034 \
		-S035 \
		-S036 \
		-S037 \
		-V002 \
		-V003 \
		-V004 \
		-V005 \
		-V006 \
		-V007 \
		-V008 \
		./$(PKG_NAME)

tools:
	GO111MODULE=on go install ./awsproviderlint
	GO111MODULE=on go install github.com/bflad/tfproviderdocs
	GO111MODULE=on go install github.com/client9/misspell/cmd/misspell
	GO111MODULE=on go install github.com/golangci/golangci-lint/cmd/golangci-lint
	GO111MODULE=on go install github.com/katbyte/terrafmt

test-compile:
	@if [ "$(TEST)" = "./..." ]; then \
		echo "ERROR: Set TEST to a specific package. For example,"; \
		echo "  make test-compile TEST=./$(PKG_NAME)"; \
		exit 1; \
	fi
	go test -c $(TEST) $(TESTARGS)

.PHONY: awsproviderlint build gen golangci-lint sweep test testacc fmt fmtcheck lint tools test-compile
