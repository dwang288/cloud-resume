// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"context"
	"fmt"
	"log"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/expression"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	_ "github.com/dwang288/cloud-resume-go-api/api"
)

// main loads default AWS credentials and configuration from the ~/.aws folder and runs
// a scenario specified by the `-scenario` flag.
//
// `-scenario` can be one of the following:
//
//   - `movieTable`    -  Runs the interactive movie table scenario that shows you how to use
//     Amazon DynamoDB API commands to work with DynamoDB tables and items.
//   - `partiQLSingle` - 	Runs a scenario that shows you how to use PartiQL statements
//     to work with DynamoDB tables and items.
//   - `partiQLBatch`  - 	Runs a scenario that shows you how to use batches of PartiQL
//     statements to work with DynamoDB tables and items.
func main() {

	//TODO: Add lambda handler

	sdkConfig, err := config.LoadDefaultConfig(context.Background()) //TODO: check how config load works
	if err != nil {
		log.Fatalf("unable to load SDK config, %v", err)
	}
	dynamoDbClient := dynamodb.NewFromConfig(sdkConfig)

	UpdateTable(dynamoDbClient, "visitor_counter") // TODO: replace table-name with the actual table name, belongs in lambda handler

	log.SetFlags(0)
}

// TODO: Use structured logger
func UpdateTable(client *dynamodb.Client, tableName string) (map[string]int, error) {
	var attributeMap map[string]int

	// Define the key of the item you want to update
	pk := "counter"
	sk := "SK"

	update := expression.Add(
		expression.Name("num_visitors"),
		expression.Value(1),
	)

	expr, err := expression.NewBuilder().WithUpdate(update).Build()
	if err != nil {
		log.Print("Got error building expression:", err)
		return nil, err
	}

	response, err := client.UpdateItem(context.Background(), &dynamodb.UpdateItemInput{
		TableName: aws.String(tableName),
		Key: map[string]types.AttributeValue{
			"PK": &types.AttributeValueMemberS{Value: pk},
			"SK": &types.AttributeValueMemberS{Value: sk},
		},
		UpdateExpression:          expr.Update(),
		ExpressionAttributeNames:  expr.Names(),
		ExpressionAttributeValues: expr.Values(),
		ReturnValues:              types.ReturnValueUpdatedNew,
	})

	if err != nil {
		log.Print("Got error calling UpdateItem:", err)
		return nil, err
	}
	err = attributevalue.UnmarshalMap(response.Attributes, &attributeMap) //TODO: unmarshals into the attributeMap
	if err != nil {
		log.Print("Couldn't unmarshall update response:", err)
		return nil, err
	}

	fmt.Printf("Successfully called UpdateTable, updated attribute %s in %s with %v\n", "num_visitors", tableName, attributeMap["num_visitors"])
	return attributeMap, err
}
