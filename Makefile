.PHONY: init plan apply destroy fmt validate

ENV ?= dev

init:
	cd environments/$(ENV) && terraform init

plan:
	cd environments/$(ENV) && terraform plan -out=tfplan

apply:
	cd environments/$(ENV) && terraform apply tfplan

destroy:
	cd environments/$(ENV) && terraform destroy

fmt:
	terraform fmt -recursive

validate:
	@for dir in environments/*/; do \
		echo "=== Validating $$dir ==="; \
		cd $$dir && terraform init -backend=false && terraform validate && cd - > /dev/null; \
	done
