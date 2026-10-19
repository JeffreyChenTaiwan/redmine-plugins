suite('RedmineFormatPlugin', function () {
  setup(function () {
    var tempNode = document.createElement('div');
    tempNode.id = "tempNode";
    tempNode.style = 'visibility: hidden';
    document.body.appendChild(tempNode);

    var wysiwygNode = document.createElement('div');
    wysiwygNode.id = 'wysiwyg';
    document.getElementById('tempNode').appendChild(wysiwygNode);
  });
  teardown(function() {
    var editor = tinymce.get('wysiwyg');
    if (editor) {
      editor.off(null);
      tinymce.remove('#wysiwyg');
    }
    var tempNode = document.getElementById('tempNode');
    if (tempNode) {
      tempNode.parentElement.removeChild(tempNode);
    }
  });

  /**
   * Run `testCallback` with RWE TinyMCE editor.
   *
   * @param {Array<string>|string} allowedEvents - Events that shouldn't be suppressed.
   * @param {Function} testCallback - Test function to be run. Initialized TinyMCE
   *  editor will be provided as function argument and the asynchronous test has to be
   *  marked with Mocha's `done()`.
   */
  function withEditor(allowedEvents, testCallback) {
    tinymce.init({
      selector: '#wysiwyg',
      theme: false,
      plugins: 'redmineformat',
      setup: function (editor) {
        editor.on('init', function(e) {
          var events = [].concat(allowedEvents).map(function (event) {
            return event.toLowerCase();
          });
          ['SetContent', 'PreProcess'].forEach(function (event) {
            if (events.indexOf(event.toLowerCase()) < 0) {
              editor.off(event);
            }
          });
          testCallback(editor);
        });
      }
    });
  }

  suite('SetContent handler', function () {
    test('should normalize code block', function (done) {
      withEditor('SetContent', function (editor) {
        var c = '<p><pre><code class="java syntaxhl">foo<br>bar</code></pre></p>';
        editor.setContent(c);
        assert.equal(editor.getContent(), '<pre class="language-java">foo\nbar</pre>');
        done();
      });
    });

    test('should preserve Mermaid language when switching visual editing modes', function (done) {
      withEditor('SetContent', function (editor) {
        editor.setContent('<pre><code data-language="mermaid">flowchart TD\n  A --&gt; B</code></pre>');
        var html = editor.getContent();
        assert.equal(html, '<pre class="language-mermaid">flowchart TD\n  A --&gt; B</pre>');

        var rwe = Object.create(RedmineWysiwygEditor.prototype);
        rwe._format = 'common_mark';
        assert.equal(rwe._toTextMarkdown(html), '~~~ mermaid\nflowchart TD\n  A --> B\n~~~');
        done();
      });
    });

    test('should preserve HTML preview source when switching visual editing modes', function (done) {
      withEditor('SetContent', function (editor) {
        editor.setContent('<pre><code data-language="htmlview">&lt;h1&gt;中文 &amp;amp; SVG&lt;/h1&gt;</code></pre>');
        var html = editor.getContent();
        assert.equal(html, '<pre class="language-htmlview">&lt;h1&gt;中文 &amp;amp; SVG&lt;/h1&gt;</pre>');

        var rwe = Object.create(RedmineWysiwygEditor.prototype);
        rwe._format = 'common_mark';
        assert.equal(rwe._toTextMarkdown(html), '~~~ htmlview\n<h1>中文 &amp; SVG</h1>\n~~~');
        done();
      });
    });
  });

  suite('PreProcess handler', function () {
    test('should convert br to nl and normalize text', function (done) {
      withEditor('PreProcess', function (editor) {
        var c = '<p><pre>foo<br>bar</pre></p>';
        editor.on('PreProcess', function (e) {
          var pre = editor.$('pre', e.node)[0];
          assert.equal(pre.childNodes.length, 1, 'child node count');
          assert.equal(pre.firstChild.nodeType, window.Node.TEXT_NODE, 'node type');
        });
        editor.setContent(c);
        assert.equal(editor.getContent(), '<pre>foo\nbar</pre>');
        done();
      });
    });
  });
});
