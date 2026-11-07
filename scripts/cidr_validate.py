#!/usr/bin/env python3
"""Validate CIDR topology for Terraform's external data source and preflight."""

import ipaddress
import json
import sys
from typing import Any


def network(value: str, label: str, errors: list[str]) -> ipaddress.IPv4Network | None:
    try:
        candidate = ipaddress.ip_network(value, strict=True)
        if candidate.version != 4:
            errors.append(f"{label} must be IPv4, not IPv{candidate.version}")
            return None
        return candidate
    except ValueError as exc:
        errors.append(f"{label} is not a valid CIDR: {exc}")
        return None


def validate(payload: dict[str, Any]) -> dict[str, str]:
    errors: list[str] = []
    vpc = network(str(payload.get("vpc_cidr", "")), "vpc_cidr", errors)

    def as_list(key: str) -> list[Any]:
        value = payload.get(key, "[]")
        try:
            return json.loads(value) if isinstance(value, str) else value
        except (TypeError, json.JSONDecodeError):
            errors.append(f"{key} could not be parsed as a list")
            return []

    subnet_values = as_list("private_subnets_json")
    remote_values = as_list("remote_cidrs_json")
    az_values = as_list("availability_zones")

    if len(subnet_values) != 4:
        errors.append("exactly four private subnet CIDRs are required")
    if len(az_values) != 4 or len(set(az_values)) != 4:
        errors.append("exactly four distinct Availability Zone names are required")

    subnets = [network(str(value), f"private_subnet_cidrs[{index}]", errors) for index, value in enumerate(subnet_values)]
    valid_subnets = [subnet for subnet in subnets if subnet is not None]
    if vpc is not None:
        for subnet in valid_subnets:
            if not subnet.subnet_of(vpc):
                errors.append(f"subnet {subnet} is not contained by VPC CIDR {vpc}")

    for index, left in enumerate(valid_subnets):
        for right in valid_subnets[index + 1 :]:
            if left.overlaps(right):
                errors.append(f"private subnets overlap: {left} and {right}")

    remotes = [network(str(value), f"remote_vpc_cidrs[{index}]", errors) for index, value in enumerate(remote_values)]
    valid_remotes = [remote for remote in remotes if remote is not None]
    if vpc is not None:
        for remote in valid_remotes:
            if remote.overlaps(vpc):
                errors.append(f"remote VPC CIDR {remote} overlaps VPC C CIDR {vpc}")

    # Overlapping remote CIDRs make VPC C route destinations ambiguous, even
    # though VPC peering itself is intentionally non-transitive.
    for index, left in enumerate(valid_remotes):
        for right in valid_remotes[index + 1 :]:
            if left.overlaps(right):
                errors.append(f"remote VPC CIDRs overlap: {left} and {right}")

    diagnostics = "; ".join(errors) if errors else "CIDR and AZ topology validation passed"
    return {"valid": str(not errors).lower(), "diagnostics": diagnostics}


def main() -> int:
    raw = sys.stdin.read()
    try:
        payload: Any = json.loads(raw)
        # `terraform console` prints jsonencode() as a JSON string.
        if "--terraform-console" in sys.argv and isinstance(payload, str):
            payload = json.loads(payload)
        if not isinstance(payload, dict):
            raise ValueError("input must be a JSON object")
    except (ValueError, json.JSONDecodeError) as exc:
        result = {"valid": "false", "diagnostics": f"Unable to parse validation input: {exc}"}
    else:
        result = validate(payload)

    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
