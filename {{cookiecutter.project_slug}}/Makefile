.PHONY: init plan apply destroy fmt

init:
	terraform init

plan:
	terraform plan -out=tfplan

apply:
	terraform apply tfplan

destroy:
	terraform destroy

fmt:
	terraform fmt -recursive
