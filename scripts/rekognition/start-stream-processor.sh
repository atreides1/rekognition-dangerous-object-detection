#! /usr/bin/env bash

aws rekognition start-stream-processor \
    --name my-stream-processor \
    --cli-input-json '{"StartSelector":{"KVSStreamStartSelector":{"ProducerTimestamp":0}},"StopSelector":{"MaxDurationInSeconds": 120}}'