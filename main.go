// main.go
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"github.com/aws/aws-lambda-go/lambda"
)

type payload struct {
	version string
}

func hello(ctx context.Context, event json.RawMessage) (string, error) {
	// var p payload
	// if err := json.Unmarshal(event, &p); err != nil {
	// 	return "ERROR", err
	// }

	log.Printf("Version of the lambda is %s\n", version)
	r := fmt.Sprintf("Hello from version: %s", version)
	return r, nil
}

var version = "0"

func main() {
	// Make the handler available for Remote Procedure Call by AWS Lambda
	lambda.Start(hello)
}
