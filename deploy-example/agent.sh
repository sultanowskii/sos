#!/bin/bash

elixir \
    --name "${NAME}" \
    --cookie "${COOKIE}" \
    -S mix run -- storage-agent --brain-name "${BRAIN_NAME}" --client-id "${CLIENT_ID}" --directory "${DIRECTORY}"
