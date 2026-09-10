#!/usr/bin/env python3
"""evidence.py — Generate smoke test evidence JSON with real results.

Usage: echo '{"pass_count": 5, "fail_count": 0, "result": "PASS", ...}' | python3 evidence.py

Called from deploy.yml smoketest job. Captures actual test results.
"""

import json
import sys
import os
from datetime import datetime, timezone


def generate_evidence(pass_count_str, fail_count_str, result, corr_id, project_name,
                      url, sha, run_id, health_app, version_app, openapi_title,
                      python_ver, output_path):
    """Generate evidence JSON with real test results."""
    pass_count = int(pass_count_str) if pass_count_str else 0
    fail_count = int(fail_count_str) if fail_count_str else 0

    evidence = {
        'rc': 'RC77-C5',
        'result': result,
        'pass_count': pass_count,
        'fail_count': fail_count,
        'total_tests': pass_count + fail_count,
        'correlation_id': corr_id,
        'project': project_name,
        'url': url,
        'commit': sha,
        'run_id': run_id,
        'workflow': 'deploy.yml',
        'job': 'smoketest',
        'repository': 'HERMES-ENTERPRISE',
        'ref': 'main',
        'timestamp': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
        'identity': {
            'health_aplicacion': health_app,
            'version_aplicacion': version_app,
            'openapi_title': openapi_title,
            'python_version': python_ver,
        },
        'test_summary': 'See smoke-test log for per-endpoint details',
        'tests_count': pass_count + fail_count,
    }

    with open(output_path, 'w') as f:
        json.dump(evidence, f, indent=2)

    print(f'Evidence saved: result={result} pass={pass_count} fail={fail_count}')


if __name__ == '__main__':
    if len(sys.argv) < 13:
        print('Usage: evidence.py <pass_count> <fail_count> <result> <corr_id> <project> <url> <sha> <run_id> <health_app> <version_app> <openapi_title> <python_ver> <output_path>', file=sys.stderr)
        sys.exit(1)

    generate_evidence(
        sys.argv[1], sys.argv[2], sys.argv[3],
        sys.argv[4], sys.argv[5], sys.argv[6],
        sys.argv[7], sys.argv[8], sys.argv[9],
        sys.argv[10], sys.argv[11], sys.argv[12],
        sys.argv[13]
    )