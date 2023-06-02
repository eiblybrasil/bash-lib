#!/bin/bash

export SERVICE_CMD=""

if command -v systemctl >/dev/null 2>&1; then
    SERVICE_CMD="systemctl"
elif command -v service >/dev/null 2>&1; then
    SERVICE_CMD="service"
fi