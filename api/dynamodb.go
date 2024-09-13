package api

import (
	"context"
	"fmt"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/expression"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

type Query struct {
	DynamoDBClient *dynamodb.Client
	TableName      string
	PK             string
	SK             string
	Attribute      string
}

func (q *Query) UpdateTable(ctx context.Context) (map[string]int, error) {
	var attributeMap map[string]int

	update := expression.Add(
		expression.Name(q.Attribute),
		expression.Value(1),
	)

	expr, err := expression.NewBuilder().WithUpdate(update).Build()
	if err != nil {
		return nil, fmt.Errorf("got error building expression: %w", err)
	}

	response, err := q.DynamoDBClient.UpdateItem(ctx, &dynamodb.UpdateItemInput{
		TableName: aws.String(q.TableName),
		Key: map[string]types.AttributeValue{
			"PK": &types.AttributeValueMemberS{Value: q.PK},
			"SK": &types.AttributeValueMemberS{Value: q.SK},
		},
		UpdateExpression:          expr.Update(),
		ExpressionAttributeNames:  expr.Names(),
		ExpressionAttributeValues: expr.Values(),
		ReturnValues:              types.ReturnValueUpdatedNew,
	})

	if err != nil {
		return nil, fmt.Errorf("got error calling UpdateItem: %w", err)
	}
	err = attributevalue.UnmarshalMap(response.Attributes, &attributeMap) //TODO: unmarshals into the attributeMap
	if err != nil {
		return nil, fmt.Errorf("couldn't unmarshall update response: %w", err)
	}

	return attributeMap, nil
}
