// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"context"
	"fmt"
	"log"

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

type Handler struct {
	DynamoDBClient *dynamodb.Client
}

func (h *Handler) HandleRequest(ctx context.Context) (*string, error) {
	response, err := api.UpdateTable(h.DynamoDBClient, "visitor_counter")

	if err != nil {
		return nil, err
	}

	message := fmt.Sprintf("num_visitors: %d!", response["num_visitors"])
	return &message, nil
}
