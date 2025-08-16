#!/bin/bash

# ==============================================================================
# SCRIPT TO SET ENVIRONMENT VARIABLES FOR A POSTGRES DATABASE CONNECTION
#
# USAGE:
# To use this script, you must 'source' it so that the environment variables
# are set in your current shell session.
#
#   source ./setup_env.sh
#   or
#   . ./setup_env.sh
#
# ==============================================================================

# --- PROMPT FOR USER INPUT ---
echo "Please provide your database connection details."

read -p "PostgreSQL User: " POSTGRES_USER
read -s -p "PostgreSQL Password: " POSTGRES_PASSWORD
echo

read -p "Database Host: " DB_HOST
read -p "Database Port (e.g., 5432): " DB_PORT
read -p "Database Name: " DB_NAME
read -p "Credit Token Service API Key: " CREDIT_TOKEN_SVC_API_KEY

# --- SET ENVIRONMENT VARIABLES ---
# The username for your PostgreSQL database.
export POSTGRES_USER
echo "POSTGRES_USER has been set."

# The password for your PostgreSQL database user.
export POSTGRES_PASSWORD
echo "POSTGRES_PASSWORD has been set."

# The R2DBC (Reactive Relational Database Connectivity) URL.
export R2DBC_POSTGRES_URL="r2dbc:postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
echo "R2DBC_POSTGRES_URL has been set."

# The JDBC (Java Database Connectivity) URL.
export JDBC_POSTGRES_URL="jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}"
echo "JDBC_POSTGRES_URL has been set."

# The API key for the Credit Token Service.
export CREDIT_TOKEN_SVC_API_KEY
echo "CREDIT_TOKEN_SVC_API_KEY has been set."

echo "All environment variables have been set for the current session."
