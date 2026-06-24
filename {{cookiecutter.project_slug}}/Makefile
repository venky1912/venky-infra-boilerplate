.PHONY: plan apply destroy validate fmt

ENV ?= dev

plan:
	cd environments/$(ENV) && terragrunt run-all plan --terragrunt-non-interactive

apply:
	cd environments/$(ENV) && terragrunt run-all apply --terragrunt-non-interactive

destroy:
	cd environments/$(ENV) && terragrunt run-all destroy --terragrunt-non-interactive

validate:
	cd environments/$(ENV) && terragrunt run-all validate --terragrunt-non-interactive

fmt:
	terraform fmt -recursive modules/
