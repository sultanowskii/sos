#!/bin/bash

elixir \
    --name "${NAME}" \
    --cookie "${COOKIE}" \
    -S mix run -- brain
