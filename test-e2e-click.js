const { chromium } = require('playwright');

(async () => {
    const URL = 'https://as-hermesportal.azurewebsites.net/';
    const TEST_NAME = 'hermes-ui-click-e2e-02';
    
    const browser = await chromium.launch({ 
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const context = await browser.newContext({
        viewport: { width: 1280, height: 900 }
    });
    
    // Track console messages and network requests
    const consoleErrors = [];
    const networkRequests = [];
    
    context.on('console', msg => {
        if (msg.type() === 'error' || msg.type() === 'warning') {
            consoleErrors.push({ type: msg.type(), text: msg.text(), location: msg.location() });
        }
    });
    
    context.on('request', request => {
        if (request.method() === 'POST') {
            networkRequests.push({
                url: request.url(),
                method: request.method(),
                postData: request.postData()
            });
        }
    });
    
    context.on('response', response => {
        if (response.request().method() === 'POST') {
            networkRequests.push({
                url: response.url(),
                status: response.status(),
                method: response.request().method()
            });
        }
    });
    
    const page = await context.newPage();
    
    console.log('=== FASE 9: ABRIR PORTAL ===');
    await page.goto(URL, { waitUntil: 'networkidle', timeout: 30000 });
    console.log('Portal loaded successfully');
    
    // Wait for all initial API calls to complete
    await page.waitForTimeout(2000);
    
    // === CHECK CONSOLE ERRORS ===
    console.log('\n=== CONSOLE BEFORE CLICK ===');
    if (consoleErrors.length === 0) {
        console.log('NO CONSOLE ERRORS ✅');
    } else {
        console.log('CONSOLE ERRORS FOUND ❌');
        consoleErrors.forEach(e => console.log(`  [${e.type}] ${e.text}`));
    }
    
    // === CHECK crearProyecto ===
    console.log('\n=== CHECK crearProyecto FUNCTION ===');
    const typeofFn = await page.evaluate(() => typeof crearProyecto);
    console.log(`typeof crearProyecto: ${typeofFn}`);
    if (typeofFn === 'function') {
        console.log('crearProyecto IS DEFINED ✅');
    } else {
        console.log('crearProyecto IS NOT DEFINED ❌');
        await browser.close();
        process.exit(1);
    }
    
    // Check loadAll
    const typeofLoadAll = await page.evaluate(() => typeof loadAll);
    console.log(`typeof loadAll: ${typeofLoadAll} ${typeofLoadAll === 'function' ? '✅' : '❌'}`);
    
    // Check actualizarHistorial
    const typeofHistorial = await page.evaluate(() => typeof actualizarHistorial);
    console.log(`typeof actualizarHistorial: ${typeofHistorial} ${typeofHistorial === 'function' ? '✅' : '❌'}`);
    
    // === FASE 10: CLICK REAL ===
    console.log('\n=== FASE 10: CLICK REAL ===');
    
    // Find the button
    const btnExists = await page.$('#crear-proyecto-btn');
    console.log(`#crear-proyecto-btn exists: ${btnExists ? 'YES ✅' : 'NO ❌'}`);
    
    // Find the input
    const inputExists = await page.$('#nuevo-proyecto-input');
    console.log(`#nuevo-proyecto-input exists: ${inputExists ? 'YES ✅' : 'NO ❌'}`);
    
    if (!btnExists || !inputExists) {
        console.log('Button or input not found ❌');
        await browser.close();
        process.exit(1);
    }
    
    // Fill the input
    console.log(`\nFilling project name: "${TEST_NAME}"`);
    await page.fill('#nuevo-proyecto-input', TEST_NAME);
    const inputValue = await page.inputValue('#nuevo-proyecto-input');
    console.log(`Input value after fill: "${inputValue}" ${inputValue === TEST_NAME ? '✅' : '❌'}`);
    
    // Clear network log
    networkRequests.length = 0;
    consoleErrors.length = 0;
    
    // Click the button
    console.log('\nClicking #crear-proyecto-btn...');
    await page.click('#crear-proyecto-btn');
    
    // Wait for network calls
    await page.waitForTimeout(3000);
    
    // === FASE 11: NETWORK ===
    console.log('\n=== FASE 11: NETWORK ===');
    console.log(`POST requests detected: ${networkRequests.length}`);
    networkRequests.forEach(r => {
        console.log(`  ${r.method} ${r.url} status=${r.status || 'pending'}`);
        if (r.postData) console.log(`  Payload: ${r.postData}`);
    });
    
    // Check for POST /api/fabrica/proyectos
    const postToFabrica = networkRequests.filter(r => r.url.includes('/api/fabrica/proyectos') && r.url.endsWith('/proyectos'));
    const postDisparar = networkRequests.filter(r => r.url.includes('/disparar'));
    
    if (postToFabrica.length > 0) {
        console.log(`\nPOST /api/fabrica/proyectos: FOUND ✅`);
        const postResp = postToFabrica.find(r => r.status);
        if (postResp) {
            console.log(`  Status: ${postResp.status} ${postResp.status === 202 ? '✅' : '❌'}`);
        }
    } else {
        console.log(`\nPOST /api/fabrica/proyectos: NOT FOUND ❌`);
    }
    
    if (postDisparar.length > 0) {
        console.log(`POST /api/fabrica/proyectos/{id}/disparar: FOUND ✅`);
    } else {
        console.log(`POST /api/fabrica/proyectos/{id}/disparar: NOT FOUND`);
    }
    
    // === FASE 12: UI VALIDATION ===
    console.log('\n=== FASE 12-13: UI VALIDATION ===');
    
    // Wait for UI to update
    await page.waitForTimeout(1000);
    
    // Check console errors after click
    console.log(`\nConsole errors after click: ${consoleErrors.length}`);
    consoleErrors.forEach(e => console.log(`  [${e.type}] ${e.text}`));
    
    // Check the mensaje div
    const mensajeHTML = await page.evaluate(() => {
        const el = document.getElementById('crear-proyecto-mensaje');
        return el ? el.innerHTML : null;
    });
    console.log(`\nMensaje HTML: ${mensajeHTML ? mensajeHTML.substring(0, 200) + '...' : 'null'}`);
    
    // Check if ultimo-proyecto-creado div has content
    const ultimoProyectoHTML = await page.evaluate(() => {
        const el = document.getElementById('ultimo-proyecto-creado');
        return el ? el.innerHTML : null;
    });
    console.log(`Ultimo proyecto creado: ${ultimoProyectoHTML ? ultimoProyectoHTML.substring(0, 200) + '...' : 'null'}`);
    
    // Check for project name in the page
    const pageText = await page.textContent('body');
    const containsProjectName = pageText.includes(TEST_NAME);
    console.log(`\nProject name "${TEST_NAME}" visible in page: ${containsProjectName ? 'YES ✅' : 'NO ❌'}`);
    
    // Wait a bit more for historial to update
    await page.waitForTimeout(3000);
    const updatedPageText = await page.textContent('body');
    const containsInHistorial = updatedPageText.includes(TEST_NAME);
    console.log(`Project name in historial after refresh: ${containsInHistorial ? 'YES ✅' : 'NO ❌'}`);
    
    console.log('\n=== FINAL RESULT ===');
    const errorsAfterClick = consoleErrors.filter(e => !e.text.includes('favicon'));
    if (errorsAfterClick.length === 0 && typeofFn === 'function' && postToFabrica.length > 0) {
        console.log('PORTAL CLICK E2E — PASS ✅');
    } else {
        console.log('PORTAL CLICK E2E — FAIL ❌');
        if (errorsAfterClick.length > 0) console.log('  - Console errors present');
        if (typeofFn !== 'function') console.log('  - crearProyecto is not defined');
        if (postToFabrica.length === 0) console.log('  - No POST to /api/fabrica/proyectos');
    }
    
    await browser.close();
})();
