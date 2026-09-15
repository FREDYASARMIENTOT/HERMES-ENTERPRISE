#!/usr/bin/env python3
"""
validate_user_facing.py - User-Facing Page Validation for HERMES Control Plane.

Robust error page detection with false positive prevention.
Handles legitimate "error" usage in JavaScript, JSON, comments.
Detects real error pages (500, 502, 503, Internal Server Error, etc.).
Outputs JSON for CI/CD integration.

Usage:
    python tools/validate_user_facing.py <url> [project_name]
    python tools/validate_user_facing.py --html-file <path> [project_name]
"""

import json
import re
import sys
import urllib.request
import urllib.error

# ============================================================
# Constants - Real error indicators
# ============================================================

ERROR_TITLES = [
    "internal server error",
    "bad request",
    "service unavailable",
    "application error",
    "http error 500",
    "http error 502",
    "http error 503",
    "http error 504",
    "500 internal server error",
    "502 bad gateway",
    "503 service unavailable",
    "504 gateway timeout",
]

ERROR_STRUCTURAL_PATTERNS = [
    r"<title>[^<]*(?:error|500|502|503|504)[^<]*</title>",
    r"<h[1-4][^>]*>[^<]*(?:internal server error|bad request|service unavailable|application error|something went wrong)[^<]*</h[1-4]>",
    r"Runtime\s+Error",
    r"An\s+Error\s+Occurred",
    r"Server\s+Error\s+in\s+['\"]",
    r"HTTP\s+Error\s+50[0-9]",
    r"Sorry,\s+(?:the\s+)?page\s+(?:you\s+)?(?:are\s+)?looking\s+for",
    r"The\s+resource\s+you\s+are\s+looking\s+for\s+has\s+been\s+removed",
    r"The\s+website\s+cannot\s+display\s+the\s+page",
    r"This\s+page\s+can(?:'t|not)\s+be\s+displayed",
    r"Azure\s+App\s+Service\s+-\s+Error",
    r"App\s+Service\s+-\s+Application\s+Error",
]

ERROR_SAFE_PATTERNS = [
    "traceback",
    "Traceback",
    "Internal Server Error",
    "500 Internal",
    "502 Bad",
    "503 Service",
    "504 Gateway",
]


def classify_response(status_code, content_type, html, project_name=None):
    """
    Classify a user-facing web response as PASS or FAIL.

    Args:
        status_code: HTTP status code (int)
        content_type: Content-Type header value (str)
        html: Full HTML body (str)
        project_name: Optional expected project identity (str)

    Returns:
        dict with keys: result, reason, error_matches, ignored_matches, details
    """
    result = {
        "result": "PASS",
        "reason": [],
        "error_matches": [],
        "ignored_matches": [],
        "details": {}
    }

    # ----------------------------------------------------------
    # Check 1: HTTP status code
    # ----------------------------------------------------------
    if status_code >= 500:
        result["result"] = "FAIL"
        result["reason"].append("HTTP %d - server error" % status_code)
        result["error_matches"].append({
            "type": "http_status",
            "value": str(status_code),
            "context": "HTTP %d response" % status_code
        })
        result["details"]["http_status"] = status_code
        result["details"]["html_size"] = len(html)
        result["details"]["content_type"] = content_type
        result["reason"] = "; ".join(result["reason"])
        return result

    if status_code >= 400 and status_code < 500:
        result["result"] = "FAIL"
        result["reason"].append("HTTP %d - client error" % status_code)
        result["error_matches"].append({
            "type": "http_status",
            "value": str(status_code),
            "context": "HTTP %d response" % status_code
        })
        result["details"]["http_status"] = status_code
        result["details"]["html_size"] = len(html)
        result["details"]["content_type"] = content_type
        result["reason"] = "; ".join(result["reason"])
        return result

    # ----------------------------------------------------------
    # Check 2: Content-Type
    # ----------------------------------------------------------
    is_html = (
        "text/html" in content_type.lower()
        or html.strip().lower().startswith("<!doctype html")
        or html.strip().lower().startswith("<html")
        or html.strip().lower().startswith("<head")
    )
    result["details"]["content_type"] = content_type
    result["details"]["is_html"] = is_html

    if not is_html:
        result["result"] = "FAIL"
        result["reason"].append("Content-Type '%s', expected text/html" % content_type)
        result["reason"] = "; ".join(result["reason"])
        return result

    result["reason"].append("Content-Type is text/html or HTML-like")

    # ----------------------------------------------------------
    # Check 3: HTML size
    # ----------------------------------------------------------
    html_size = len(html)
    result["details"]["html_size"] = html_size

    if html_size < 500:
        result["result"] = "FAIL"
        result["reason"].append("HTML too small (%d bytes, min 500)" % html_size)
        result["reason"] = "; ".join(result["reason"])
        return result

    result["reason"].append("HTML size %d bytes (> 500)" % html_size)

    # ----------------------------------------------------------
    # Check 4: Structural error page detection (real errors)
    # ----------------------------------------------------------
    html_lower = html.lower()

    # 4a. Check for error titles
    for pattern in ERROR_TITLES:
        if pattern in html_lower:
            idx = html_lower.index(pattern)
            ctx_start = max(0, idx - 60)
            ctx_end = min(len(html), idx + len(pattern) + 60)
            context = html[ctx_start:ctx_end]
            match = {
                "type": "error_title",
                "value": pattern,
                "context": context.replace("\n", " ").strip()
            }
            result["error_matches"].append(match)
            result["result"] = "FAIL"
            result["reason"].append("Error title: '%s'" % pattern)

    # 4b. Structural error patterns (regex)
    for pattern in ERROR_STRUCTURAL_PATTERNS:
        for m in re.finditer(pattern, html, re.IGNORECASE):
            ctx_start = max(0, m.start() - 60)
            ctx_end = min(len(html), m.end() + 60)
            context = html[ctx_start:ctx_end]
            match = {
                "type": "structural_error",
                "value": m.group()[:80],
                "context": context.replace("\n", " ").strip()
            }
            result["error_matches"].append(match)
            result["result"] = "FAIL"
            result["reason"].append("Structural error: '%s'" % m.group()[:50])

    # 4c. Safe error patterns (traceback, etc.)
    for pattern in ERROR_SAFE_PATTERNS:
        for m in re.finditer(re.escape(pattern), html):
            ctx_start = max(0, m.start() - 60)
            ctx_end = min(len(html), m.end() + 60)
            context = html[ctx_start:ctx_end]
            match = {
                "type": "safe_error_pattern",
                "value": pattern,
                "context": context.replace("\n", " ").strip()
            }
            result["error_matches"].append(match)
            result["result"] = "FAIL"
            result["reason"].append("Error pattern: '%s'" % pattern)

    # ----------------------------------------------------------
    # Check 5: Legitimate "error" word usage (false positive candidates)
    # ----------------------------------------------------------
    legitimate_error_patterns = [
        r"data\.error\b",
        r"error\s*=",
        r"error\s*\(",
        r"errorHandler",
        r"errorMessage",
        r"showError",
        r"handleError",
        r"onError",
        r"errorCallback",
        r"try\s*{[^}]*}\s*catch\s*\(\s*(?:\w+\s+)?error\s*\)",
        r"\.catch\s*\(\s*(?:\w+\s+)?=>\s*{",
        r"errors?\s*:",
        r"error_code",
        r"error_msg",
        r"error_message",
        r"error_type",
        r"errorResponse",
        r"errorState",
        r"error_boundary",
    ]

    for pattern in legitimate_error_patterns:
        for m in re.finditer(pattern, html, re.IGNORECASE):
            ctx_start = max(0, m.start() - 40)
            ctx_end = min(len(html), m.end() + 40)
            context = html[ctx_start:ctx_end]
            result["ignored_matches"].append({
                "type": "legitimate_usage",
                "value": m.group()[:80],
                "context": context.replace("\n", " ").strip(),
                "pattern": pattern
            })

    # Bare word "error" outside known legitimate patterns
    bare_error = r'(?<!data\.)(?<!\.catch\()(?:^|[^a-zA-Z_.])error(?:$|[^a-zA-Z])'
    for m in re.finditer(bare_error, html, re.IGNORECASE):
        ctx_start = max(0, m.start() - 40)
        ctx_end = min(len(html), m.end() + 40)
        context = html[ctx_start:ctx_end]
        before = html[max(0, m.start()-500):m.start()].lower()
        in_script = bool(re.search(r'<script[^>]*>', before))
        has_close = '</script>' in before
        in_script = in_script and not has_close
        if in_script:
            result["ignored_matches"].append({
                "type": "inside_script_tag",
                "value": m.group()[:80],
                "context": context.replace("\n", " ").strip(),
            })
        else:
            result["ignored_matches"].append({
                "type": "bare_error_outside_script",
                "value": m.group()[:80],
                "context": context.replace("\n", " ").strip(),
            })

    # ----------------------------------------------------------
    # Check 6: Project identity
    # ----------------------------------------------------------
    if project_name:
        identity_found = project_name in html
        result["details"]["identity_found"] = identity_found
        result["details"]["expected_identity"] = project_name
        if identity_found:
            result["reason"].append("Project identity '%s' found" % project_name)
        else:
            result["result"] = "FAIL"
            result["reason"].append("Project identity '%s' NOT found" % project_name)

    # ----------------------------------------------------------
    # Final classification
    # ----------------------------------------------------------
    if result["result"] != "FAIL":
        result["result"] = "PASS"

    result["reason"] = "; ".join(result["reason"])
    return result


def fetch_url(url, timeout=30):
    """Fetch a URL and return (status_code, content_type, body)."""
    req = urllib.request.Request(url)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            status_code = resp.status
            content_type = resp.headers.get("Content-Type", "")
            body = resp.read().decode("utf-8", errors="replace")
            return status_code, content_type, body
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        return e.code, e.headers.get("Content-Type", ""), body
    except urllib.error.URLError as e:
        return 0, "", "<error>URL Error: %s</error>" % e.reason


def main():
    if len(sys.argv) < 2:
        print("Usage: python validate_user_facing.py <url> [project_name]", file=sys.stderr)
        print("   or: python validate_user_facing.py --html-file <path> [project_name]", file=sys.stderr)
        sys.exit(1)

    html = None
    project_name = None

    if sys.argv[1] == "--html-file":
        html_path = sys.argv[2]
        with open(html_path, "r", encoding="utf-8") as f:
            html = f.read()
        if len(sys.argv) > 3:
            project_name = sys.argv[3]
        status_code = 200
        content_type = "text/html"
    else:
        url = sys.argv[1]
        if len(sys.argv) > 2:
            project_name = sys.argv[2]
        print("Fetching: %s" % url, file=sys.stderr)
        status_code, content_type, html = fetch_url(url)
        print("Status: %d, Content-Type: %s" % (status_code, content_type), file=sys.stderr)
        print("HTML size: %d bytes" % len(html), file=sys.stderr)

    result = classify_response(status_code, content_type, html, project_name)

    print(json.dumps(result, indent=2, ensure_ascii=False))

    if result["result"] == "FAIL":
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()