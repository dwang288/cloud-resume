// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"context"
	"log"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/dwang288/cloud-resume-go-api/api"
)

func main() {

	//TODO: Add lambda handler

	sdkConfig, err := config.LoadDefaultConfig(context.Background()) //TODO: check how config load works
	if err != nil {
		log.Fatalf("unable to load SDK config, %v", err)
	}
	dynamoDbClient := dynamodb.NewFromConfig(sdkConfig)

	api.UpdateTable(dynamoDbClient, "visitor_counter") // TODO: replace table-name with the actual table name, belongs in lambda handler

	log.SetFlags(0)
}
