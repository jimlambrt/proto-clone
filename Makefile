# Determine this makefile's path.
# Be sure to place this BEFORE `include` directives, if any.
THIS_FILE := $(lastword $(MAKEFILE_LIST))
THIS_DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

TMP_DIR := $(shell mktemp -d)

REPO_PATH := proto-clone


tools:
	go generate -tags tools tools/tools.go

fmt:
	gofumpt -w $$(find . -name '*.go' | grep -v pb.go | grep -v pb.gw.go)

### oplog requires protoc-gen-go v1.20.0 or later
# GO111MODULE=on go get -u github.com/golang/protobuf/protoc-gen-go@v1.40
proto: protolint protobuild


protobuild:
	# To add a new directory containing a proto pass the  proto's root path in
	# through the --proto_path flag.
	@bash scripts/protoc_gen_plugin.bash \
		"--proto_path=proto" \
		"--plugin_name=go" \
		"--plugin_out=${TMP_DIR}"

	# Move the generated files from the tmp file subdirectories into the current repo.
	cp -R ${TMP_DIR}/${REPO_PATH}/* ${THIS_DIR}

	@protoc --proto_path=proto  
	
	@rm -R ${TMP_DIR}

protolint:
	@buf check lint
	@buf check breaking --against 'https://github.com/hashicorp/boundary.git#branch=stable-website'
