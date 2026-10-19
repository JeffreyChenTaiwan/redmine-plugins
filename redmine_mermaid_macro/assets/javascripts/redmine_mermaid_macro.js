const selector = 'div.mermaid, .wiki pre > code[data-language="mermaid"], .wiki pre > code.language-mermaid';
const queued = new WeakSet();
let nextId = 0;

function mermaidEngine() {
  // Share initialization with inline macros in previously cached Redmine HTML.
  if (!globalThis.__redmineMermaidReady) {
    globalThis.__redmineMermaidReady = Promise.all([
      import('mermaid'),
      import('https://cdn.jsdelivr.net/npm/@mermaid-js/layout-elk@0.2.2/dist/mermaid-layout-elk.esm.min.mjs')
    ]).then(([{ default: mermaid }, { default: elkLayouts }]) => {
      mermaid.registerLayoutLoaders(elkLayouts);
      mermaid.initialize({ startOnLoad: false });
      return mermaid;
    });
  }
  return globalThis.__redmineMermaidReady;
}

function enqueue(candidate) {
  if (queued.has(candidate) || candidate.getAttribute('data-processed') === 'true') {
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
  globalThis.__redmineMermaidQueue ||= Promise.resolve();
  globalThis.__redmineMermaidQueue = globalThis.__redmineMermaidQueue.then(async () => {
    if (!node.isConnected || node.getAttribute('data-processed') === 'true') {
      return;
    }

    try {
      const engine = await mermaidEngine();
      if (!node.isConnected || node.getAttribute('data-processed') === 'true') {
        return;
      }
      await engine.run({ nodes: [node], suppressErrors: false });
    } catch (error) {
      // Keep the source readable and allow subsequent diagrams to render.
      node.textContent = source;
      node.classList.add('mermaid-error');
      console.error(`[redmine_mermaid_macro] Mermaid render failed: ${node.id}`, error);
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
