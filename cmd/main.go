package main

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/lambda"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/dwang288/cloud-resume-go-api/api"
)

//TODO: Add tests + mocks for DynamoDB

func main() {

	sdkConfig, err := config.LoadDefaultConfig(context.Background()) //TODO: check how config load works
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	if err != nil {
		logger.Error("unable to load SDK config", slog.Any("error", err))
	}

	query := &api.Query{
		DynamoDBClient: dynamodb.NewFromConfig(sdkConfig),
		TableName:      "visitor_counter",
		PK:             "counter",
		SK:             "SK",
		Attribute:      "num_visitors",
	}

	//TODO: Figure out if I can output to stdout/stderr depending on log level
	h := Handler{
		Logger: logger,
		Query:  query,
	}

	lambda.Start(h.HandleRequest)
}

type Handler struct {
	Logger *slog.Logger
	Query  *api.Query
}
type LambdaResponse struct {
	IsBase64Encoded   bool                `json:"isBase64Encoded"`
	StatusCode        int                 `json:"statusCode"`
	Headers           map[string]string   `json:"headers"`
	MultiValueHeaders map[string][]string `json:"multiValueHeaders"`
	Body              string              `json:"body"`
}

func (h Handler) HandleRequest(ctx context.Context) (LambdaResponse, error) {
	r, err := h.Query.UpdateTable(ctx)
	if err != nil {
		h.Logger.Error("Error updating DynamoDB:", slog.Any("error", err))
		// TODO: Figure out what i'm supposed to return to escape the function call since i've already logged
		return LambdaResponse{}, nil
	}
	h.Logger.Info("Successfully called UpdateTable", "table", h.Query.TableName, "attribute", h.Query.Attribute, "value", r["num_visitors"])

	jsonBytes, err := json.Marshal(r)
	if err != nil {
		h.Logger.Error("Error marshaling body response to JSON:", slog.Any("error", err))
		// TODO: Figure out what i'm supposed to return to escape the function call
		return LambdaResponse{}, nil
	}

	lambdaResponse := LambdaResponse{
		IsBase64Encoded: false,
		StatusCode:      http.StatusOK,
		Headers: map[string]string{
			"Content-Type": "application/json",
		},
		Body: string(jsonBytes),
	}

	return lambdaResponse, nil
}
