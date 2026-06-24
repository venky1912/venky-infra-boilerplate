.PHONY: init plan apply destroy fmt validate

ENV ?= dev

init:
	cd environments/$(ENV) && terragrunt run-all init --terragrunt-non-interactive

plan:
	cd environments/$(ENV) && terragrunt run-all plan --terragrunt-non-interactive

apply:
	cd environments/$(ENV) && terragrunt run-all apply --terragrunt-non-interactive

destroy:
	cd environments/$(ENV) && terragrunt run-all destroy --terragrunt-non-interactive

fmt:
	terragrunt hclfmt
	terraform fmt -recursive

validate:
	cd environments/$(ENV) && terragrunt run-all validate --terragrunt-non-interactive
