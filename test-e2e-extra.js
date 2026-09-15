const { chromium } = require('playwright');

(async () => {
    const URL = 'https://as-hermesportal.azurewebsites.net/';
    const browser = await chromium.launch({ headless: true });
    const context = await browser.newContext();
    const page = await context.newPage();
    
    await page.goto(URL, { waitUntil: 'networkidle', timeout: 30000 });
    await page.waitForTimeout(2000);
    
    // ========== FASE 17: PRUEBA DE NOMBRE INVÁLIDO ==========
    console.log('=== FASE 17: PRUEBA DE NOMBRE INVÁLIDO ===');
    
    // Test 1: Empty (too short, single char)
    await page.fill('#nuevo-proyecto-input', 'A');
    console.log('1. Filled input with "A"');
    const mensajeBefore = await page.evaluate(() => {
        const el = document.getElementById('crear-proyecto-mensaje');
        return el ? el.innerHTML : 'null';
    });
    console.log(`   Mensaje before click: ${mensajeBefore}`);
    
    await page.click('#crear-proyecto-btn');
    await page.waitForTimeout(500);
    
    const mensajeAfter1 = await page.evaluate(() => {
        const el = document.getElementById('crear-proyecto-mensaje');
        return el ? el.innerHTML : 'null';
    });
    console.log(`   Mensaje after click with "A": ${mensajeAfter1}`);
    
    // Test 2: Invalid chars (uppercase)
    await page.fill('#nuevo-proyecto-input', 'UPPERCASE-INVALID');
    await page.click('#crear-proyecto-btn');
    await page.waitForTimeout(500);
    
    const mensajeAfter2 = await page.evaluate(() => {
        const el = document.getElementById('crear-proyecto-mensaje');
        return el ? el.innerHTML : 'null';
    });
    console.log(`   Mensaje with UPPERCASE: ${mensajeAfter2}`);
    
    // Test 3: Empty string
    await page.fill('#nuevo-proyecto-input', '');
    await page.click('#crear-proyecto-btn');
    await page.waitForTimeout(500);
    
    const mensajeAfter3 = await page.evaluate(() => {
        const el = document.getElementById('crear-proyecto-mensaje');
        return el ? el.innerHTML : 'null';
    });
    console.log(`   Mensaje with empty: ${mensajeAfter3}`);
    
    const netRequests = [];
    page.on('request', req => {
        if (req.method() === 'POST' && req.url().includes('/api/fabrica/proyectos')) {
            netRequests.push(req.url());
        }
    });
    
    // ========== FASE 16: PRUEBA DE DOBLE CLICK ==========
    console.log('\n=== FASE 16: PRUEBA DE DOBLE CLICK ===');
    
    await page.fill('#nuevo-proyecto-input', 'hermes-dblclick-test');
    
    // Reset tracking
    netRequests.length = 0;
    
    // Double click rapidly
    await page.click('#crear-proyecto-btn');
    await page.click('#crear-proyecto-btn');
    await page.waitForTimeout(3000);
    
    console.log(`POST requests after double click: ${netRequests.length}`);
    console.log(`  (1 = single request protected, >1 = multiple requests)`);
    
    // Check if button was disabled after first click
    const wasDisabled = await page.evaluate(() => {
        const btn = document.getElementById('crear-proyecto-btn');
        return btn ? btn.disabled : 'null';
    });
    console.log(`Button disabled after clicks: ${wasDisabled}`);
    
    console.log('\n=== VALIDATION RESULTS ===');
    
    await browser.close();
})();
