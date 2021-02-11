deploy-vpc-subnet:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/vpc-subnet.yml \
		--stack-name ecs-blue-green-demo-vpc-subnet \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset

deploy-nat-instance:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/nat-instance.yml \
		--stack-name ecs-blue-green-demo-nat-instance \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset

deploy-network:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/network.yml \
		--stack-name ecs-blue-green-demo-network \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset

deploy-security-group:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/security-group.yml \
		--stack-name ecs-blue-green-demo-security-group \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset

deploy-load-balancer:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/load-balancer.yml \
		--stack-name ecs-blue-green-demo-load-balancer \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset

deploy-ecs-cluster:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/ecs-cluster.yml \
		--stack-name ecs-blue-green-demo-ecs-cluster \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset

deploy-ecs-ecr:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/ecs-ecr.yml \
		--stack-name ecs-blue-green-demo-ecs-ecr \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset

deploy-ecs-service:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/ecs-service.yml \
		--stack-name ecs-blue-green-demo-ecs-service \
		--capabilities CAPABILITY_NAMED_IAM \
		--no-fail-on-empty-changeset

push-docker-images:
	aws --profile $(profile) ecr get-login-password --region $(region) | docker login --username AWS --password-stdin $(account).dkr.ecr.$(region).amazonaws.com
	docker build -t ecs-blue-green-demo/php-fpm -f aws/ecs/app-service/app/Dockerfile .
	docker tag ecs-blue-green-demo/php-fpm:latest $(account).dkr.ecr.$(region).amazonaws.com/ecs-blue-green-demo/php-fpm:latest
	docker push $(account).dkr.ecr.$(region).amazonaws.com/ecs-blue-green-demo/php-fpm:latest
	docker build -t ecs-blue-green-demo/nginx -f aws/ecs/app-service/nginx/Dockerfile .
	docker tag ecs-blue-green-demo/nginx:latest $(account).dkr.ecr.$(region).amazonaws.com/ecs-blue-green-demo/nginx:latest
	docker push $(account).dkr.ecr.$(region).amazonaws.com/ecs-blue-green-demo/nginx:latest

deploy-secrets-github:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/secrets-github.yml \
		--stack-name ecs-blue-green-demo-secrets-github \
		--parameter-overrides AccessToken=$(access-token) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset

deploy-pipeline:
	aws --profile $(profile) cloudformation deploy \
		--template ./aws/cloud-formation/pipeline.yml \
		--stack-name ecs-blue-green-demo-pipeline \
		--capabilities CAPABILITY_NAMED_IAM \
		--no-fail-on-empty-changeset

deploy-code-deploy-app:
	aws --profile $(profile) deploy create-application \
		--application-name ecs-blue-green-demo-app \
		--compute-platform ECS

deploy-code-deploy-group:
	cat aws/cloud-formation/codedeploy-group.json | \
		sed -e "s!<LISTENER_ARN>!$(listener-arn)!g" -e "s!<DEPLOY_ROLE_ARN>!$(deploy-role-arn)!g" \
		> codedeploy-group.json
	aws --profile $(profile) deploy create-deployment-group \
		--cli-input-json file://codedeploy-group.json
	rm -f codedeploy-group.json
