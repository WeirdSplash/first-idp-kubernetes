# Kind Cluster Configuration

This folder contains the Kind cluster configuration for the IDP demo.

## Files

- `cluster-config.yaml` — Kind cluster definition with port mappings

## Usage

```bash
kind create cluster --config cluster-config.yaml --name idp-demo
```
