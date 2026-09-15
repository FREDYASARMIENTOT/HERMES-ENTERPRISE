import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from tools.validate_user_facing import classify_response

LARGE = '<!DOCTYPE html><html><head><title>HERMES - test-project</title></head><body><h1>OK</h1>' + '<p>x</p>'*100 + '</body></html>'
SMALL = '<!DOCTYPE html><html><head><title>Minimal</title></head><body><p>Too small</p></body></html>'

def test_normal_html():
    r = classify_response(200, 'text/html', LARGE, 'test-project')
    assert r['result'] == 'PASS', f'Expected PASS, got {r["result"]}: {r["reason"]}'
    print('  PASS: test_normal_html')

def test_normal_html_with_data_error():
    html = LARGE.replace('</head>', '<script>fetch("/api").then(r=>r.json()).then(data=>{if(data.error){return;}show(data);})</script></head>')
    r = classify_response(200, 'text/html', html, 'test-project')
    assert r['result'] == 'PASS', f'Expected PASS, got {r["result"]}: {r["reason"]}'
    assert len(r['error_matches']) == 0, f'Expected 0 error_matches, got {len(r["error_matches"])}'
    assert any(m['type']=='legitimate_usage' for m in r['ignored_matches']), 'Expected legitimate_usage ignored match for data.error'
    print('  PASS: test_normal_html_with_data_error')

def test_normal_html_with_catch():
    html = LARGE.replace('</head>', '<script>fetch("/api").catch(error=>console.log(error))</script></head>')
    r = classify_response(200, 'text/html', html)
    assert r['result'] == 'PASS', f'Expected PASS, got {r["result"]}: {r["reason"]}'
    assert len(r['error_matches']) == 0
    print('  PASS: test_normal_html_with_catch')

def test_internal_server_error():
    html = '<!DOCTYPE html><html><head><title>Internal Server Error</title></head><body><h1>500 - Internal Server Error</h1><p>y</p>'*100+'</body></html>'
    r = classify_response(200, 'text/html', html)
    assert r['result'] == 'FAIL', f'Expected FAIL, got {r["result"]}'
    assert any(m['type']=='error_title' for m in r['error_matches'])
    print('  PASS: test_internal_server_error')

def test_http_500():
    r = classify_response(500, 'text/html', LARGE)
    assert r['result'] == 'FAIL'; assert r['error_matches'][0]['type'] == 'http_status'
    print('  PASS: test_http_500')

def test_http_502():
    r = classify_response(502, 'text/html', LARGE)
    assert r['result'] == 'FAIL'; assert r['error_matches'][0]['type'] == 'http_status'
    print('  PASS: test_http_502')

def test_http_503():
    r = classify_response(503, 'text/html', LARGE)
    assert r['result'] == 'FAIL'; assert r['error_matches'][0]['type'] == 'http_status'
    print('  PASS: test_http_503')

def test_small_html():
    r = classify_response(200, 'text/html', SMALL, 'test')
    assert r['result'] == 'FAIL'
    print('  PASS: test_small_html')

def test_legitimate_error_text():
    text = '<!DOCTYPE html><html><head><title>Portal User Manual</title></head><body><p>If you encounter any error, please contact support.</p><p>Common errors include connection issues.</p>' + '<p>y</p>'*100 + '</body></html>'
    r = classify_response(200, 'text/html', text)
    assert r['result'] == 'PASS', f'Expected PASS, got {r["result"]}: {r["reason"]}'
    print('  PASS: test_legitimate_error_text')

def test_http_404():
    r = classify_response(404, 'text/html', LARGE)
    assert r['result'] == 'FAIL'; assert r['error_matches'][0]['type'] == 'http_status'
    print('  PASS: test_http_404')

def test_non_html():
    r = classify_response(200, 'application/json', '{"status":"ok"}')
    assert r['result'] == 'FAIL'
    print('  PASS: test_non_html')

def test_traceback():
    html = '<!DOCTYPE html><html><head><title>Error</title></head><body><pre>Traceback (most recent call last):...Exception: something broke</pre><p>y</p>'*100+'</body></html>'
    r = classify_response(200, 'text/html', html)
    assert r['result'] == 'FAIL'
    assert len(r['error_matches']) >= 1
    print('  PASS: test_traceback')

if __name__ == '__main__':
    for name in sorted([k for k in dir() if k.startswith('test_')]):
        globals()[name]()
    print()
    print('ALL TESTS PASSED')
