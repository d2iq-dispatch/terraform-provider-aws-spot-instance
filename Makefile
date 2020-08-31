default: build

build: fmtcheck
	go install

gen:
	rm -f aws/internal/keyvaluetags/*_gen.go
	go generate ./...

fmt:
	@echo "==> Fixing source code with gofmt..."
	gofmt -s -w ./$(PKG_NAME) ./awsproviderlint

fmtcheck:
	@sh -c "'$(CURDIR)/scripts/gofmtcheck.sh'"

gencheck:
.PHONY: build gen fmt fmtcheck
