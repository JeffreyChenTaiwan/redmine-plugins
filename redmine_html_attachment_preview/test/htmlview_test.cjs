// Generate htmlview_fixture.rb first, then run with Playwright available to Node.
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');

const fixture = JSON.parse(fs.readFileSync(process.argv[2] || '/tmp/redmine-htmlview-fixture.json', 'utf8'));
const assets = path.resolve(__dirname, '../assets');
const assetFiles = {
  '/plugin_assets/redmine_html_attachment_preview/javascripts/htmlview.js': ['javascripts/htmlview.js', 'application/javascript'],
  '/plugin_assets/redmine_html_attachment_preview/stylesheets/html_attachment_preview.css': ['stylesheets/html_attachment_preview.css', 'text/css']
};
const server = http.createServer((req, res) => {
  const pathname = new URL(req.url, 'http://localhost').pathname;
  if (assetFiles[pathname]) {
    const [file, mime] = assetFiles[pathname];
    res.setHeader('Content-Type', mime);
    return res.end(fs.readFileSync(path.join(assets, file)));
  }
  const body = pathname === '/attachment' ? fixture.attachment :
    `<div id="saved" class="wiki">${fixture.bodies[pathname.slice(1)] || ''}</div>`;
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.end(`<!DOCTYPE html><html><head>${fixture.head}</head><body>${body}
    <div id="preview" class="wiki wiki-preview"></div>
    <pre id="outside"><code data-language="htmlview">&lt;h1&gt;Outside wiki&lt;/h1&gt;</code></pre>
    </body></html>`);
});

async function frameFor(page, selector) {
  const handle = await page.locator(selector).elementHandle();
  return handle.contentFrame();
}

async function flushMutations(page) {
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
}

async function checkStandalone(page, wrapper) {
  const link = page.locator(`${wrapper} .html-preview-open`).first();
  assert.equal(await link.getAttribute('target'), '_blank');
  assert.equal(await link.getAttribute('rel'), 'noopener noreferrer');
  assert(await link.textContent(), 'the open link must have a translated label');
  const originalUrl = page.url();
  const document = await page.locator(`${wrapper} iframe`).first().getAttribute('srcdoc');
  const [popup] = await Promise.all([page.waitForEvent('popup'), link.click()]);
  try {
    await popup.waitForLoadState('domcontentloaded');
    assert.match(popup.url(), /^blob:/);
    assert.equal(page.url(), originalUrl);
    assert.equal(await popup.evaluate(() => window.opener), null);
    assert.equal(await popup.locator('iframe').count(), 1);
    assert.equal(await popup.locator('iframe').getAttribute('sandbox'), '');
    assert.equal(await popup.locator('iframe').getAttribute('referrerpolicy'), 'no-referrer');
    assert.equal(await popup.locator('iframe').getAttribute('srcdoc'), document);
    const frame = await frameFor(popup, 'iframe');
    await frame.waitForSelector('h1');
    assert.equal(await frame.locator('h1').textContent(), '中文 HTML & SVG');
    assert.equal(await frame.locator('h1').evaluate(node => getComputedStyle(node).color), 'rgb(12, 34, 56)');
    assert.equal(await frame.locator('svg text').textContent(), '圖表');
    assert.equal(await frame.locator('body').getAttribute('data-script-ran'), null);
    assert.equal(await popup.evaluate(() => window.htmlviewEscaped), undefined);
    assert.equal(await frame.evaluate(() => {
      try { void parent.document.body; return false; } catch (error) { return error.name === 'SecurityError'; }
    }), true);
    const rect = await popup.locator('iframe').boundingBox();
    assert.equal(Math.round(rect.height), popup.viewportSize().height);
    await frame.locator('a').click();
    await frame.waitForFunction(() => location.hash === '#chapter');
  } finally {
    await popup.close();
  }
}

(async () => {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  const browser = await chromium.launch({ args: ['--no-sandbox'] });
  try {
    const page = await browser.newPage();
    const errors = [];
    const requests = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('request', request => requests.push(request.url()));
    for (const format of ['common_mark', 'markdown']) {
      await page.goto(`${base}/${format}`);
      await page.waitForFunction(() => document.querySelectorAll('#saved .html-inline-preview iframe').length === 2);
      const frame = await frameFor(page, '#saved iframe >> nth=0');
      await frame.waitForSelector('h1');
      assert.equal(await frame.locator('h1').textContent(), '中文 HTML & SVG');
      assert.equal(await frame.locator('svg text').textContent(), '圖表');
      assert.equal(await frame.locator('h1').evaluate(node => getComputedStyle(node).color), 'rgb(12, 34, 56)');
      assert.match(await frame.locator('p').textContent(), /literal <\/iframe> <script> and & entities/);
      assert.equal(await page.locator('#saved > h1, #saved > script, #saved > style').count(), 0);
      assert.notEqual(await page.locator('body').evaluate(node => getComputedStyle(node).backgroundColor), 'rgb(234, 245, 255)');
      assert.match(await page.locator('#saved code[data-language="html"]').textContent(), /<h1>Plain HTML source<\/h1>/);
      assert.match(await page.locator('#saved code[data-language="text"]').textContent(), /```htmlview/);
      assert.equal(await page.locator('#outside code[data-language="htmlview"]').count(), 1);
      assert.equal(await page.locator('#saved .html-preview-open').count(), 2);
      assert.equal(await page.locator('#saved iframe').first().getAttribute('sandbox'), '');
      assert.equal(await page.locator('#saved iframe').first().getAttribute('referrerpolicy'), 'no-referrer');
      assert.equal(await page.evaluate(() => window.htmlviewEscaped), undefined);
      assert.equal(await frame.locator('body').getAttribute('data-script-ran'), null);
      assert.equal(await frame.evaluate(() => {
        try { void parent.document.body; return false; } catch (error) { return error.name === 'SecurityError'; }
      }), true, 'sandbox blocks access to the host DOM');
      assert.equal(await frame.evaluate(() => {
        try { void document.cookie; return false; } catch (error) { return error.name === 'SecurityError'; }
      }), true, 'sandbox blocks cookie access');
      assert.deepEqual(await frame.locator('head').evaluate(head => ({
        first: head.firstElementChild.httpEquiv,
        base: [...head.querySelectorAll('base')].map(node => node.getAttribute('href')),
        refresh: [...head.querySelectorAll('meta[http-equiv]')].some(node => node.httpEquiv.toLowerCase() === 'refresh')
      })), { first: 'Content-Security-Policy', base: ['about:srcdoc'], refresh: false });

      await frame.locator('a').click();
      await frame.waitForFunction(() => location.hash === '#chapter');
      assert.match(frame.url(), /^about:srcdoc#chapter$/);
      await frame.locator('button').click();
      await flushMutations(page);
      assert.equal(requests.some(url => url.includes('/blocked-form')), false);
      assert.equal(requests.some(url => url.includes('example.invalid')), false);

      await checkStandalone(page, '#saved .html-inline-preview');

      await page.locator('#saved summary').first().click();
      assert.equal(await page.locator('#saved details[open]').count(), 1);
      assert.equal(await page.locator('#saved details code[data-language="htmlview"]').first().textContent(), fixture.source);
      const before = await page.locator('#saved').innerHTML();
      await page.evaluate(() => document.body.appendChild(document.createElement('p')));
      await page.addScriptTag({ url: `${base}/plugin_assets/redmine_html_attachment_preview/javascripts/htmlview.js` });
      await flushMutations(page);
      assert.equal(await page.locator('#saved').innerHTML(), before, 'rescanning must preserve previews and source details');
      console.log(`PASS: ${format} HTML/CSS/SVG, escaping, ordinary code, sandbox, CSP, anchors, source and repeat scans`);
    }

    await page.evaluate(html => { document.getElementById('preview').innerHTML = html; }, fixture.bodies.common_mark);
    await page.waitForFunction(() => document.querySelectorAll('#preview .html-inline-preview iframe').length === 2);
    assert.equal(await page.locator('#preview .html-preview-open').count(), 2);
    await checkStandalone(page, '#preview .html-inline-preview');
    await page.evaluate(() => {
      document.getElementById('preview').innerHTML = '<pre><code class="language-htmlview">&lt;h2&gt;Updated preview&lt;/h2&gt;</code></pre>';
    });
    await page.waitForFunction(() => document.querySelectorAll('#preview .html-inline-preview iframe').length === 1);
    const updated = await frameFor(page, '#preview iframe');
    await updated.waitForSelector('h2');
    assert.equal(await updated.locator('h2').textContent(), 'Updated preview');
    await page.setViewportSize({ width: 375, height: 720 });
    const rect = await page.locator('#preview iframe').boundingBox();
    assert(rect.width <= 375 && rect.width > 300);
    assert(rect.height >= 240);
    console.log('PASS: AJAX/WYSIWYG preview replacement, language class fallback and mobile width');

    await page.goto(`${base}/attachment`);
    const attachment = await frameFor(page, '.html-attachment-preview iframe');
    await attachment.waitForSelector('h1');
    assert.equal(await attachment.locator('h1').textContent(), '中文 HTML & SVG');
    assert.equal(await page.locator('.html-attachment-preview-source table.filecontent').count(), 1);
    assert.equal(await page.evaluate(() => window.htmlviewEscaped), undefined);
    assert.equal(await page.locator('.html-attachment-preview .html-preview-open').count(), 1);
    await checkStandalone(page, '.html-attachment-preview');
    assert.deepEqual(errors, []);
    console.log('PASS: existing attachment preview and source remain available; no browser script errors');
    console.log('PASS: saved/AJAX/attachment previews open full-height tabs with the same HTML/CSS/SVG, isolated frames, no opener and working anchors');
  } finally {
    await browser.close();
    server.close();
  }
})().catch(error => {
  console.error(error);
  server.close();
  process.exitCode = 1;
});
