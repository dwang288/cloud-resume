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

type UpdateResponse map[string]int

func (q *Query) IncrementAttribute(ctx context.Context) (UpdateResponse, error) {
	var attrResponse UpdateResponse

	update := expression.Add(
		expression.Name(q.Attribute),
		expression.Value(1),
	)

	expr, err := expression.NewBuilder().WithUpdate(update).Build()
	if err != nil {
		return UpdateResponse{}, fmt.Errorf("failed to build expression: %w", err)
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
		return UpdateResponse{}, fmt.Errorf("failed to update DynamoDB: %w", err)
	}
	err = attributevalue.UnmarshalMap(response.Attributes, &attrResponse)
	if err != nil {
		return UpdateResponse{}, fmt.Errorf("failed to unmarshall update response: %w", err)
	}

	return attrResponse, nil
}
