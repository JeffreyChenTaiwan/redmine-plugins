const selector = 'div.mermaid, .wiki pre > code[data-language="mermaid"], .wiki pre > code.language-mermaid';
const queued = new WeakSet();
let nextId = 0;
const moduleConfig = document.querySelector('script[data-redmine-mermaid-url]');
const mermaidUrl = moduleConfig?.dataset.redmineMermaidUrl;
const elkUrl = moduleConfig?.dataset.redmineMermaidElkUrl ||
  'https://cdn.jsdelivr.net/npm/@mermaid-js/layout-elk@0.2.2/dist/mermaid-layout-elk.esm.min.mjs';
const debugEnabled = new URL(location.href).searchParams.get('mermaid_debug') === '1';
let debugOutput;
function debug(message) {
  if (!debugEnabled) return;
  if (!debugOutput) {
    const panel = document.createElement('details');
    panel.open = true;
    panel.style.cssText = 'margin:12px;padding:12px;border:2px solid #777;background:#fff;color:#111';
    const title = document.createElement('summary');
    title.textContent = 'Mermaid 頁面檢查（請複製下方結果）';
    debugOutput = document.createElement('pre');
    debugOutput.style.cssText = 'white-space:pre-wrap;overflow-wrap:anywhere';
    panel.append(title, debugOutput);
    document.body.prepend(panel);
  }
  debugOutput.textContent += message + '\n';
}
debug('plugin 已啟動；頁面語言：' + document.documentElement.lang);

function mermaidEngine() {
  // Share initialization with inline macros in previously cached Redmine HTML.
  if (!globalThis.__redmineMermaidReady) {
    debug('開始匯入 Mermaid：' + mermaidUrl);
    globalThis.__redmineMermaidReady = import(mermaidUrl).then(async ({ default: mermaid }) => {
      debug('Mermaid 匯入成功');
      // Mermaid installs its own window.load handler during module evaluation.
      // Disable it immediately, before waiting for another module: otherwise it
      // can mark nodes as processed before ELK is ready and race our queue.
      mermaid.startOnLoad = false;
      mermaid.initialize({ startOnLoad: false });
      debug('自動啟動已關閉，開始匯入 ELK：' + elkUrl);
      const { default: elkLayouts } = await import(elkUrl);
      mermaid.registerLayoutLoaders(elkLayouts);
      debug('ELK 註冊完成');
      return mermaid;
    });
  }
  return globalThis.__redmineMermaidReady;
}

function hasRenderedDiagram(node) {
  return !!node.querySelector(':scope > svg');
}

function enqueue(candidate) {
  if (queued.has(candidate) || hasRenderedDiagram(candidate)) {
    if (hasRenderedDiagram(candidate)) debug('略過已有圖表：' + candidate.id);
    return;
  }

  let node = candidate;
  if (candidate.tagName === 'CODE') {
    node = document.createElement('div');
    node.className = 'mermaid';
    // Use decoded text, preserving arrows, HTML labels and literal markup safely.
    node.textContent = candidate.textContent;
    candidate.parentElement.replaceWith(node);
  }

  if (!node.id) {
    let id;
    do {
      id = `mermaid_fence_${++nextId}`;
    } while (document.getElementById(id));
    node.id = id;
  }

  queued.add(node);
  const source = node.textContent;
  debug('圖表排入佇列：' + node.id + '；字數：' + source.length + '；行數：' + source.split('\n').length);
  globalThis.__redmineMermaidQueue ||= Promise.resolve();
  globalThis.__redmineMermaidQueue = globalThis.__redmineMermaidQueue.then(async () => {
    if (!node.isConnected || hasRenderedDiagram(node)) {
      debug('開始前略過：' + node.id + '；仍在頁面：' + node.isConnected + '；processed：' + node.getAttribute('data-processed'));
      return;
    }

    try {
      const engine = await mermaidEngine();
      if (!node.isConnected || hasRenderedDiagram(node)) {
        debug('載入後略過：' + node.id + '；仍在頁面：' + node.isConnected + '；processed：' + node.getAttribute('data-processed'));
        return;
      }
      // Mermaid treats any data-processed value as complete. An interrupted or
      // competing renderer can leave the marker behind without creating SVG.
      if (node.hasAttribute('data-processed')) debug('清除沒有 SVG 的處理標記：' + node.id);
      node.removeAttribute('data-processed');
      node.textContent = source;
      node.classList.remove('mermaid-error');
      await engine.run({ nodes: [node], suppressErrors: false });
      debug('繪圖完成：' + node.id + '；SVG：' + !!node.querySelector('svg') + '；仍在頁面：' + node.isConnected);
    } catch (error) {
      // Keep the source readable and allow subsequent diagrams to render.
      node.textContent = source;
      node.classList.add('mermaid-error');
      console.error(`[redmine_mermaid_macro] Mermaid render failed: ${node.id}`, error);
      debug('繪圖失敗：' + node.id + '\n' + String(error?.stack || error));
    }
  });
}

function scan(root) {
  if (root.nodeType !== Node.ELEMENT_NODE) {
    return;
  }
  if (root.matches(selector)) {
    enqueue(root);
  }
  root.querySelectorAll(selector).forEach(enqueue);
}

function start() {
  debug('開始掃描；候選圖表：' + document.querySelectorAll(selector).length);
  // Redmine and the WYSIWYG plugin both insert preview HTML dynamically.
  const observer = new MutationObserver(records => {
    records.forEach(record => record.addedNodes.forEach(scan));
  });
  observer.observe(document.body, { childList: true, subtree: true });
  scan(document.body);
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', start, { once: true });
} else {
  start();
}
