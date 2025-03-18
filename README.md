# PoC of a Lambda Function's Canary Deploy.

Based on:

- [Implementing Canary Deployments of AWS Lambda Functions with Alias Traffic Shifting](https://aws.amazon.com/blogs/compute/implementing-canary-deployments-of-aws-lambda-functions-with-alias-traffic-shifting/)
- [Implement Lambda canary deployments using a weighted alias](https://docs.aws.amazon.com/lambda/latest/dg/configuring-alias-routing.html)

Other references:

- [Implementing Canary Deployment for Lambda Functions](https://awstip.com/implementing-canary-deployment-for-lambda-functions-32cb3339f4fa)
- [Progressive Lambda Deployments with Rollbacks](https://blog.serverlessadvocate.com/progressive-lambda-deployments-with-rollbacks-e8a1288fa852)
- [Level up your Lambda Game with Canary Deployments](https://www.eliasbrange.dev/posts/canary-lambda-releases-sst/)
- [Implementing Canary Deployment with AWS Lambda and AWS API Gateway.](https://okeyebereblessing.medium.com/implementing-canary-deployment-with-aws-lambda-and-aws-api-gateway-155b5977591d)
- [Using Canary Deployments with Lambda](https://lumigo.io/aws-lambda-deployment/canary-deployment-for-aws-lambda/)

## Notes on Terraform

- [Introduction to AWS Lambda with Terraform](https://terrateam.io/blog/aws-lambda-function-with-terraform/)

## Test

### Requirements

- [Go](https://go.dev/)
- [Terraform](https://www.terraform.io/)
- [AWS account](https://aws.amazon.com/)

### Create basic infra

```
terraform init && terraform plan && terraform apply
```

### Execute tests

```
./build.sh
```

### Example

```
Fri 28 Mar 2025 13:32:31 GMT: Dump vars
- liveFunctionVersion: 47
----------------------------------------------------------------------------------------------------

Fri 28 Mar 2025 13:32:31 GMT: Building lambda
Fri 28 Mar 2025 13:32:32 GMT: Preparing zip
Fri 28 Mar 2025 13:32:32 GMT: Updating lambda
Fri 28 Mar 2025 13:32:34 GMT: Waiting for the lambda to be updated
Fri 28 Mar 2025 13:32:39 GMT: Publish lambda
Fri 28 Mar 2025 13:32:40 GMT: Get version
Fri 28 Mar 2025 13:32:41 GMT: 25% Traffic new version 48, 75% remainging to old version 47
Fri 28 Mar 2025 13:32:42 GMT: Testing with Routing Option {"48":0.25}
Fri 28 Mar 2025 13:32:42 GMT: Start Testing 10 times
..........

v41 7 requests 70.00%
v48 3 requests 30.00%

Fri 28 Mar 2025 13:32:44 GMT: Test took: 2 seconds
Rollback [y/n]?
Fri 28 Mar 2025 13:32:49 GMT: 50% Traffic new version 48, 50% remainging to old version 47
Fri 28 Mar 2025 13:32:50 GMT: Testing with Routing Option {"48":0.5}
Fri 28 Mar 2025 13:32:50 GMT: Start Testing 10 times
..........

v41 4 requests 40.00%
v48 6 requests 60.00%

Fri 28 Mar 2025 13:32:52 GMT: Test took: 2 seconds
Rollback [y/n]?
Fri 28 Mar 2025 13:32:57 GMT: 75% Traffic new version 48, 25% remainging to old version 47
Fri 28 Mar 2025 13:32:58 GMT: Testing with Routing Option {"48":0.75}
Fri 28 Mar 2025 13:32:58 GMT: Start Testing 10 times
..........

v41 1 requests 10.00%
v48 9 requests 90.00%

Fri 28 Mar 2025 13:33:00 GMT: Test took: 2 seconds
Rollback [y/n]?
Fri 28 Mar 2025 13:33:05 GMT: 100% Traffic new version 48, 0% remainging to old version 47
Fri 28 Mar 2025 13:33:07 GMT: Testing with Routing Option null
Fri 28 Mar 2025 13:33:07 GMT: Start Testing 10 times
..........

v48 10 requests 100.00%

Fri 28 Mar 2025 13:33:08 GMT: Test took: 1 seconds
Fri 28 Mar 2025 13:33:08 GMT: ./build-and-test.sh executed in 37 seconds
```
