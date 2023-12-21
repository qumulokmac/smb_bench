#!/bin/bash

az deployment group create --name YOURCLUSTERNAME --resource-group YOURRG --template-file arm-qumulo.bicep --parameters '@parameters.json' tag=$tag
