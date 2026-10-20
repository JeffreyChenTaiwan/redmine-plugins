const { chromium, firefox } = require('playwright');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const assert = require('node:assert/strict');

if (!process.argv[2]) throw new Error('Usage: node test/browser.cjs /path/to/fixture.json');
const fixture = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const assets = path.resolve(__dirname, '../assets');
const server = http.createServer((req, res) => {
  const pathname = new URL(req.url, 'http://localhost').pathname;
  if (/\/redmine_mermaid_macro(?:-[0-9a-f]+)?\.js$/.test(pathname)) {
    res.setHeader('Content-Type', 'text/javascript');
    return res.end(fs.readFileSync(path.join(assets, 'javascripts/redmine_mermaid_macro.js')));
  }
  if (/\/redmine_mermaid_macro(?:-[0-9a-f]+)?\.css$/.test(pathname)) {
    res.setHeader('Content-Type', 'text/css');
    return res.end(fs.readFileSync(path.join(assets, 'stylesheets/redmine_mermaid_macro.css')));
  }
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.end(`<!doctype html><html><head>${fixture.head}</head><body><div id="saved" class="wiki">${fixture.bodies[pathname.slice(1)] || ''}</div><div id="preview" class="wiki"></div></body></html>`);
});

async function waitForGraphs(page, count) {
  await page.waitForFunction(n => document.querySelectorAll('.mermaid > svg').length === n, count, { timeout: 60000 });
  await page.evaluate(async () => { await globalThis.__redmineMermaidQueue; });
  assert(await page.locator('.mermaid > svg').evaluateAll(nodes => nodes.every(node => {
    const bounds = node.getBoundingClientRect();
    return bounds.width > 0 && bounds.height > 0;
  })));
}

(async () => {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  const engine = process.env.MERMAID_BROWSER === 'firefox' ? firefox : chromium;
  const options = engine === chromium ? { args: ['--no-sandbox'] } : {};
  if (process.env.MERMAID_BROWSER_EXECUTABLE) options.executablePath = process.env.MERMAID_BROWSER_EXECUTABLE;
  const browser = await engine.launch(options);
  try {
    const page = await browser.newPage();
    for (const format of Object.keys(fixture.bodies)) {
      await page.goto(`${base}/${format}`);
      await waitForGraphs(page, format === 'textile' ? 1 : 2);
      if (format !== 'textile') {
        assert.match(await page.locator('#saved code[data-language="ruby"]').textContent(), /ordinary code/);
        assert.match(await page.locator('#saved code[data-language="text"]').textContent(), /LiteralA --> LiteralB/);
      }
      console.log(`PASS: ${format} macro, ELK and supported fenced blocks`);
    }

    const format = fixture.bodies.common_mark ? 'common_mark' : 'markdown';
    assert(fixture.bodies[format], 'A Markdown formatter is required for preview tests');
    await page.goto(`${base}/${format}`);
    await waitForGraphs(page, 2);
    await page.evaluate(() => {
      globalThis.renderCalls = 0;
      globalThis.maxConcurrent = 0;
      globalThis.activeRenders = 0;
      const engine = globalThis.__redmineMermaidReady;
      return engine.then(mermaid => {
        const original = mermaid.run.bind(mermaid);
        mermaid.run = async options => {
          ++globalThis.renderCalls;
          globalThis.maxConcurrent = Math.max(globalThis.maxConcurrent, ++globalThis.activeRenders);
          try { return await original(options); } finally { --globalThis.activeRenders; }
        };
      });
    });
    await page.evaluate(html => { document.getElementById('preview').innerHTML = html; }, fixture.bodies[format]);
    await waitForGraphs(page, 4);
    assert.equal(await page.evaluate(() => globalThis.renderCalls), 2);
    assert.equal(await page.evaluate(() => globalThis.maxConcurrent), 1);
    await page.evaluate(() => {
      document.getElementById('preview').innerHTML = '<div class="mermaid">invalid diagram syntax</div><div class="mermaid">flowchart TD\nGoodA --> GoodB</div>';
    });
    await waitForGraphs(page, 3);
    assert.equal(await page.locator('#preview .mermaid-error').textContent(), 'invalid diagram syntax');
    console.log('PASS: dynamic previews render sequentially and recover after invalid syntax');
    await page.close();

    for (const scenario of ['before-scan', 'while-loading']) {
      const context = await browser.newContext();
      if (scenario === 'before-scan') await context.addInitScript(() => {
        const marked = new WeakSet();
        new MutationObserver(records => records.forEach(record => record.addedNodes.forEach(root => {
          if (root.nodeType !== Node.ELEMENT_NODE) return;
          const nodes = [...(root.matches('div.mermaid') ? [root] : []), ...root.querySelectorAll('div.mermaid')];
          nodes.forEach(node => {
            if (!marked.has(node)) { marked.add(node); node.setAttribute('data-processed', 'true'); }
          });
        }))).observe(document, { childList: true, subtree: true });
      });
      if (scenario === 'while-loading') await context.route('**/*', async route => {
        if (route.request().resourceType() !== 'script') return route.continue();
        const url = new URL(route.request().url());
        if (!url.pathname.endsWith('/mermaid-layout-elk.esm.min.mjs')) return route.continue();
        const response = await route.fetch();
        return route.fulfill({ response, body: await response.text() + '\nfor (const node of document.querySelectorAll("div.mermaid")) node.setAttribute("data-processed", "true");\n' });
      });
      const markedPage = await context.newPage();
      await markedPage.goto(`${base}/${format}`);
      await waitForGraphs(markedPage, 2);
      const preserved = await markedPage.evaluate(async () => {
        const node = document.querySelector('#saved .mermaid');
        const svg = node.querySelector('svg');
        node.parentElement.append(node);
        await new Promise(resolve => setTimeout(resolve, 200));
        await globalThis.__redmineMermaidQueue;
        return node.querySelector('svg') === svg && node.querySelectorAll('svg').length === 1;
      });
      assert(preserved, 'Completed diagrams must not be redrawn');
      console.log(`PASS: stale marker ${scenario} recovers without duplicate rendering`);
      await context.close();
    }

    const empty = await browser.newPage();
    const external = [];
    empty.on('request', request => {
      if (new URL(request.url()).origin !== base) external.push(request.url());
    });
    await empty.goto(`${base}/empty`);
    await empty.waitForLoadState('networkidle');
    assert.deepEqual(external, [], 'Pages without diagrams must not request external modules');
    console.log('PASS: no module download on pages without diagrams');
  } finally {
    await browser.close();
    server.close();
  }
})().catch(error => { console.error(error); server.close(); process.exitCode = 1; });
