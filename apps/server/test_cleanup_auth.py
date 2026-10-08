#!/usr/bin/env python3
"""
Test Suite: VPS Cleanup Service Authentication & Fail-Closed Behavior (R3)
Verifies:
1. When CLEANUP_SECRET is unset: all requests fail closed (401 Unauthorized). No default is accepted.
2. When CLEANUP_SECRET is set to the new secret:
   - Old literal secret ('mykidstube_default_secret_2026') is REJECTED with 401.
   - Any wrong secret is REJECTED with 401.
   - New secret is ACCEPTED with 200 OK.
"""

import http.client
import json
import os
import subprocess
import sys
import time

TEST_PORT = 8999
OLD_SECRET = "mykidstube_default_secret_2026"
NEW_SECRET = "431ddcf907852cbc71dcc53e1a811e5db75e560c115fd53fe351f6885e37804b"


import socket

def wait_for_server(port: int, timeout: float = 3.0) -> bool:
    start = time.time()
    while time.time() - start < timeout:
        try:
            s = socket.create_connection(("127.0.0.1", port), timeout=0.2)
            s.close()
            return True
        except Exception:
            time.sleep(0.05)
    return False


def start_server(env_vars: dict, port: int) -> subprocess.Popen:
    env = os.environ.copy()
    env.update(env_vars)
    env["CLEANUP_PORT"] = str(port)
    env["CLEANUP_HOST"] = "127.0.0.1"
    proc = subprocess.Popen(
        [sys.executable, "apps/server/cleanup_service.py"],
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if not wait_for_server(port):
        stderr = proc.stderr.read().decode('utf-8') if proc.stderr else ''
        stdout = proc.stdout.read().decode('utf-8') if proc.stdout else ''
        raise RuntimeError(f"Server on port {port} failed to start in time. Stderr: {stderr}. Stdout: {stdout}")
    return proc


def send_cleanup_request(port: int, secret: str | None, payload: dict) -> tuple[int, dict]:
    conn = http.client.HTTPConnection("127.0.0.1", port, timeout=5)
    headers = {"Content-Type": "application/json"}
    if secret is not None:
        headers["X-Media-Secret"] = secret
    body = json.dumps(payload)
    conn.request("POST", "/cleanup", body=body, headers=headers)
    resp = conn.getresponse()
    resp_body = resp.read().decode("utf-8")
    conn.close()
    try:
        data = json.loads(resp_body)
    except Exception:
        data = {"raw": resp_body}
    return resp.status, data


def run_tests():
    print("=" * 60)
    print("🧪 Running R3 VPS Cleanup Security & Rotation Tests")
    print("=" * 60)

    # -------------------------------------------------------------
    # Test 1: Unset CLEANUP_SECRET fails closed
    # -------------------------------------------------------------
    print("\n[Phase 1] Testing Unset CLEANUP_SECRET (Fail-Closed)...")
    port1 = 8991
    env_unset = {"CLEANUP_SECRET": ""}
    server1 = start_server(env_unset, port1)
    try:
        # Request with old secret
        status, data = send_cleanup_request(port1, OLD_SECRET, {"ids": ["test1"]})
        assert status == 401, f"Expected 401 when unset, got {status}: {data}"
        print(f"  ✅ Old secret rejected with 401 when CLEANUP_SECRET is unset")

        # Request with new secret
        status, data = send_cleanup_request(port1, NEW_SECRET, {"ids": ["test1"]})
        assert status == 401, f"Expected 401 when unset, got {status}: {data}"
        print(f"  ✅ New secret rejected with 401 when CLEANUP_SECRET is unset")

        # Request with missing header
        status, data = send_cleanup_request(port1, None, {"ids": ["test1"]})
        assert status == 401, f"Expected 401 when unset, got {status}: {data}"
        print(f"  ✅ Missing secret rejected with 401 when CLEANUP_SECRET is unset")
    finally:
        server1.terminate()
        server1.wait()

    # -------------------------------------------------------------
    # Test 2: Configured New Secret
    # -------------------------------------------------------------
    print("\n[Phase 2] Testing Configured New Secret...")
    port2 = 8992
    env_configured = {"CLEANUP_SECRET": NEW_SECRET}
    server2 = start_server(env_configured, port2)
    try:
        # Request with old secret must return 401
        status, data = send_cleanup_request(port2, OLD_SECRET, {"ids": ["test1"]})
        assert status == 401, f"Expected 401 for old secret, got {status}: {data}"
        print(f"  ✅ Old literal secret rejected with 401 Unauthorized")

        # Request with missing secret must return 401
        status, data = send_cleanup_request(port2, None, {"ids": ["test1"]})
        assert status == 401, f"Expected 401 for missing secret, got {status}: {data}"
        print(f"  ✅ Missing secret rejected with 401 Unauthorized")

        # Request with random wrong secret must return 401
        status, data = send_cleanup_request(port2, "wrong_random_secret_token", {"ids": ["test1"]})
        assert status == 401, f"Expected 401 for wrong secret, got {status}: {data}"
        print(f"  ✅ Arbitrary wrong secret rejected with 401 Unauthorized")

        # Request with NEW secret must return 200
        status, data = send_cleanup_request(port2, NEW_SECRET, {"ids": ["non_existent_test_id"]})
        assert status == 200, f"Expected 200 for new secret, got {status}: {data}"
        assert data.get("success") is True, f"Expected success: True, got {data}"
        print(f"  ✅ New secret successfully authenticated with 200 OK")
    finally:
        server2.terminate()
        server2.wait()

    print("\n" + "=" * 60)
    print("🎉 ALL VPS CLEANUP AUTH & FAIL-CLOSED TESTS PASSED!")
    print("=" * 60)


if __name__ == "__main__":
    run_tests()
