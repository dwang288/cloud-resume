// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"context"
	"log"
	"net/http"

	"github.com/aws/aws-lambda-go/lambda"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/dwang288/cloud-resume-go-api/api"
)

func main() {

	sdkConfig, err := config.LoadDefaultConfig(context.Background()) //TODO: check how config load works
	if err != nil {
		log.Fatalf("unable to load SDK config, %v", err)
	}
	dynamoDbClient := dynamodb.NewFromConfig(sdkConfig)

	h := Handler{DynamoDBClient: dynamoDbClient}

	lambda.Start(h.HandleRequest)

	log.SetFlags(0)
}

type LambdaResponse struct {
	IsBase64Encoded   bool                `json:"isBase64Encoded"`
	StatusCode        int                 `json:"statusCode"`
	Headers           map[string]string   `json:"headers"`
	MultiValueHeaders map[string][]string `json:"multiValueHeaders"`
	Body              map[string]int      `json:"body"`
}

type Handler struct {
	DynamoDBClient *dynamodb.Client
}

func (h *Handler) HandleRequest(ctx context.Context) (LambdaResponse, error) {
	r, err := api.UpdateTable(h.DynamoDBClient, "visitor_counter")
	if err != nil {
		return LambdaResponse{}, err
	}

	// Add return value to the lambda response's body

	// TODO: Add CORS headers
	lambdaResponse := LambdaResponse{
		IsBase64Encoded: false,
		StatusCode:      http.StatusOK,
		Headers: map[string]string{
			"Content-Type": "application/json",
		},
		Body: r,
	}

	return lambdaResponse, nil
}
