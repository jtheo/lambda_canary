package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"github.com/aws/aws-lambda-go/lambda"
)

func hello(ctx context.Context, event json.RawMessage) (string, error) {
	log.Printf("Version of the lambda is %s\n", Version)
	r := fmt.Sprintf("Hello from version: %s", Version)
	return r, nil
}

var Version = "0" // Version comes from the build process

func main() {
	lambda.Start(hello)
}
