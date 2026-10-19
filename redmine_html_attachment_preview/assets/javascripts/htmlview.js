(function () {
  'use strict';

  const settings = document.currentScript.dataset;
  const selector = '.wiki pre > code[data-language="htmlview"], .wiki pre > code.language-htmlview';
  const frameSelector = '.html-inline-preview > iframe.html-attachment-preview-frame, .html-attachment-preview > iframe.html-attachment-preview-frame';
  const standaloneUrls = new Map();

  function addOpenLink(frame) {
    const wrapper = frame.parentElement;
    if (wrapper.querySelector('.html-preview-toolbar')) return;

    // Only the trusted wrapper is opened at top level. User HTML stays sandboxed.
    const doc = document.implementation.createHTMLDocument(frame.title);
    const referrer = doc.createElement('meta');
    referrer.name = 'referrer';
    referrer.content = 'no-referrer';
    doc.head.appendChild(referrer);
    doc.body.style.margin = '0';
    const standaloneFrame = doc.createElement('iframe');
    standaloneFrame.title = frame.title;
    standaloneFrame.setAttribute('sandbox', '');
    standaloneFrame.setAttribute('referrerpolicy', 'no-referrer');
    standaloneFrame.style.cssText = 'display:block;width:100%;height:100vh;border:0;box-sizing:border-box;background:#fff';
    standaloneFrame.srcdoc = frame.srcdoc;
    doc.body.appendChild(standaloneFrame);
    const url = URL.createObjectURL(new Blob(['<!DOCTYPE html>\n', doc.documentElement.outerHTML], { type: 'text/html;charset=utf-8' }));
    standaloneUrls.set(frame, url);

    const toolbar = document.createElement('div');
    toolbar.className = 'html-preview-toolbar';
    const link = document.createElement('a');
    link.className = 'html-preview-open';
    link.textContent = settings.htmlviewOpen;
    link.href = url;
    link.target = '_blank';
    link.rel = 'noopener noreferrer';
    toolbar.appendChild(link);
    wrapper.insertBefore(toolbar, frame);
  }

  function releaseRemovedPreviews() {
    standaloneUrls.forEach((url, frame) => {
      if (frame.isConnected) return;
      standaloneUrls.delete(frame);
      // Allow a just-clicked tab to finish loading before releasing its URL.
      setTimeout(() => URL.revokeObjectURL(url), 60000);
    });
  }

  function previewDocument(source) {
    const doc = new DOMParser().parseFromString(source, 'text/html');
    doc.querySelectorAll('base').forEach(node => node.remove());
    doc.querySelectorAll('meta[http-equiv]').forEach(node => {
      if (node.getAttribute('http-equiv').toLowerCase() === 'refresh') node.remove();
    });

    const policy = doc.createElement('meta');
    policy.httpEquiv = 'Content-Security-Policy';
    policy.content = settings.htmlviewPolicy;
    const referrer = doc.createElement('meta');
    referrer.name = 'referrer';
    referrer.content = 'no-referrer';
    const base = doc.createElement('base');
    base.href = 'about:srcdoc';
    doc.head.prepend(policy, referrer, base);
    return '<!DOCTYPE html>\n' + doc.documentElement.outerHTML;
  }

  function render(code) {
    // The original code remains available inside details; never render it again.
    if (!code.isConnected || code.closest('.html-inline-preview')) return;

    const frame = document.createElement('iframe');
    frame.className = 'html-attachment-preview-frame html-inline-preview-frame';
    frame.title = settings.htmlviewTitle;
    frame.setAttribute('sandbox', '');
    frame.setAttribute('referrerpolicy', 'no-referrer');
    // Use textContent to decode the code block once; never insert HTML in the host page.
    frame.srcdoc = previewDocument(code.textContent);

    const wrapper = document.createElement('div');
    wrapper.className = 'html-inline-preview';
    const details = document.createElement('details');
    details.className = 'html-attachment-preview-source';
    const summary = document.createElement('summary');
    summary.textContent = settings.htmlviewSource;
    details.appendChild(summary);
    wrapper.append(frame, details);

    const pre = code.parentElement;
    pre.replaceWith(wrapper);
    details.appendChild(pre);
    addOpenLink(frame);
  }

  function scan(root) {
    if (root.nodeType !== Node.ELEMENT_NODE) return;
    if (root.matches(selector)) render(root);
    root.querySelectorAll(selector).forEach(render);
    if (root.matches(frameSelector)) addOpenLink(root);
    root.querySelectorAll(frameSelector).forEach(addOpenLink);
  }

  function start() {
    // Also handle Redmine AJAX previews and the WYSIWYG preview tab.
    const observer = new MutationObserver(records => {
      records.forEach(record => record.addedNodes.forEach(scan));
      if (records.some(record => record.removedNodes.length)) releaseRemovedPreviews();
    });
    observer.observe(document.body, { childList: true, subtree: true });
    scan(document.body);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start, { once: true });
  } else {
    start();
  }
})();
