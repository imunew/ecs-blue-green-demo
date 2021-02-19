stack-family=ecs-blue-green-demo

deploy-vpc-subnet:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/vpc-subnet.yml \
		--stack-name $(stack-family)-vpc-subnet \
		--parameter-overrides StackFamily=$(stack-family) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset

deploy-nat-instance:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/nat-instance.yml \
		--stack-name $(stack-family)-nat-instance \
		--parameter-overrides StackFamily=$(stack-family) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset

deploy-network:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/network.yml \
		--stack-name $(stack-family)-network \
		--parameter-overrides StackFamily=$(stack-family) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset

deploy-security-group:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/security-group.yml \
		--stack-name $(stack-family)-security-group \
		--parameter-overrides StackFamily=$(stack-family) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset

deploy-load-balancer:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/load-balancer.yml \
		--stack-name $(stack-family)-load-balancer \
		--parameter-overrides StackFamily=$(stack-family) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset

deploy-ecs-cluster:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/ecs-cluster.yml \
		--stack-name $(stack-family)-ecs-cluster \
		--parameter-overrides StackFamily=$(stack-family) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset

deploy-ecs-ecr:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/ecs-ecr.yml \
		--stack-name $(stack-family)-ecs-ecr \
		--parameter-overrides StackFamily=$(stack-family) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset

deploy-ecs-service:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/ecs-service.yml \
		--stack-name $(stack-family)-ecs-service \
		--parameter-overrides StackFamily=$(stack-family) \
		--capabilities CAPABILITY_NAMED_IAM \
		--no-fail-on-empty-changeset

push-docker-images:
	aws --profile $(profile) ecr get-login-password --region $(region) | docker login --username AWS --password-stdin $(account).dkr.ecr.$(region).amazonaws.com
	docker build -t $(stack-family)/php-fpm -f aws/ecs/app-service/php-fpm/Dockerfile .
	docker tag $(stack-family)/php-fpm:latest $(account).dkr.ecr.$(region).amazonaws.com/$(stack-family)/php-fpm:latest
	docker push $(account).dkr.ecr.$(region).amazonaws.com/$(stack-family)/php-fpm:latest
	docker build -t $(stack-family)/nginx -f aws/ecs/app-service/nginx/Dockerfile .
	docker tag $(stack-family)/nginx:latest $(account).dkr.ecr.$(region).amazonaws.com/$(stack-family)/nginx:latest
	docker push $(account).dkr.ecr.$(region).amazonaws.com/$(stack-family)/nginx:latest

deploy-secrets-github:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/secrets-github.yml \
		--stack-name $(stack-family)-secrets-github \
		--parameter-overrides StackFamily=$(stack-family) AccessToken=$(access-token) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset

deploy-pipeline:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/pipeline.yml \
		--stack-name $(stack-family)-pipeline \
		--parameter-overrides StackFamily=$(stack-family) \
		--capabilities CAPABILITY_NAMED_IAM \
		--no-fail-on-empty-changeset

deploy-code-deploy-app:
	aws --profile $(profile) deploy create-application \
		--application-name $(stack-family)-app \
		--compute-platform ECS

deploy-code-deploy-group:
	cat aws/cloud-formation/codedeploy-group.json | \
		sed -e "s!<LISTENER_ARN>!$(listener-arn)!g" -e "s!<DEPLOY_ROLE_ARN>!$(deploy-role-arn)!g" \
		> codedeploy-group.json
	aws --profile $(profile) deploy create-deployment-group \
		--cli-input-json file://codedeploy-group.json
	rm -f codedeploy-group.json
