package api

import (
	"context"
	"fmt"
	"log"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/expression"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

// TODO: Use structured logger
// TODO: Move all magic values into config
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
