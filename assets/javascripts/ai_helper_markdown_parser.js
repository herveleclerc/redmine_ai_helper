// Prevent duplicate class declaration
if (typeof AiHelperMarkdownParser === 'undefined') {
  window.AiHelperMarkdownParser = class {
    constructor() {
      this.rules = [
        // Headers
        {
          pattern: /^(#{1,6})\s(.+)$/gm,
          replacement: (match, hashes, content) => {
            const level = hashes.length;
            return `<h${level}>${content.trim()}</h${level}>`;
          }
        },
        // Bold
        {
          pattern: /\*\*(.+?)\*\*/g,
          replacement: (match, content) => `<strong>${content}</strong>`
        },
        // Italic
        {
          pattern: /\*(.+?)\*/g,
          replacement: (match, content) => `<em>${content}</em>`
        },
        // Links
        {
          pattern: /\[(.+?)\]\((.+?)\)/g,
          replacement: (match, text, url) => `<a href="${url}">${text}</a>`
        },
        // Unordered lists
        {
          pattern: /^\s*[-*+]\s+(.+)$/gm,
          replacement: (match, content) => `<li>${content}</li>`
        },
        // Ordered lists
        {
          pattern: /^\s*\d+\.\s+(.+)$/gm,
          replacement: (match, content) => `<li>${content}</li>`
        },
        // Code blocks
        {
          pattern: /```([^`]+)```/g,
          replacement: (match, content) => `<pre><code>${content}</code></pre>`
        },
        // Inline code
        {
          pattern: /`([^`]+)`/g,
          replacement: (match, content) => `<code>${content}</code>`
        },
        // Paragraphs
        {
          pattern: /^(?!<[a-z]).+$/gm,
          replacement: (match) => `<p>${match}</p>`
        }
      ];
    }
  
    parse(markdown) {
      let html = markdown;
      
      // Process tables first
      html = this.processTables(html);
      
      // Process lists
      html = this.processLists(html);
      
      // Apply all other rules
      this.rules.forEach(rule => {
        html = html.replace(rule.pattern, rule.replacement);
      });
      
      return html;
    }
  
    processTables(markdown) {
      const tableRegex = /^\|(.+)\|$/;
      const headerSeparatorRegex = /^\|(\s*:?-+:?\s*\|)+$/;
      
      const lines = markdown.split('\n');
      let html = [];
      let inTable = false;
      let tableData = [];
      let alignments = [];
      
      for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        const isTableRow = tableRegex.test(line);
        const isHeaderSeparator = headerSeparatorRegex.test(line);
        
        if (isTableRow) {
          if (!inTable) {
            inTable = true;
            tableData = [];
            alignments = [];
          }
          
          // Process the row data
          const cells = line.split('|')
            .filter(cell => cell.trim() !== '')
            .map(cell => cell.trim());
          
          tableData.push(cells);
          
          // If next line is a header separator, process alignment
          if (i + 1 < lines.length && headerSeparatorRegex.test(lines[i + 1])) {
            const separators = lines[i + 1].split('|')
              .filter(sep => sep.trim() !== '')
              .map(sep => sep.trim());
            
            alignments = separators.map(sep => {
              if (sep.startsWith(':') && sep.endsWith(':')) return 'center';
              if (sep.endsWith(':')) return 'right';
              if (sep.startsWith(':')) return 'left';
              return 'left';
            });
            // Skip the separator line
            i++;
          }
        } else {
          if (inTable) {
            // Convert table data to HTML
            html.push(this.convertTableToHtml(tableData, alignments));
            inTable = false;
            tableData = [];
            alignments = [];
          }
          
          // Only add non-separator lines
          if (!isHeaderSeparator) {
            html.push(line);
          }
        }
      }
      
      // Handle table at end of document
      if (inTable) {
        html.push(this.convertTableToHtml(tableData, alignments));
      }
      
      return html.join('\n');
    }
  
    convertTableToHtml(tableData, alignments) {
      if (tableData.length === 0) return '';
      
      let html = ['<table class="list">'];
      
      // Add header row
      html.push('<thead>');
      html.push('<tr>');
      tableData[0].forEach((cell, index) => {
        const alignment = alignments[index] || 'left';
        const alignAttr = alignment !== 'left' ? ` align="${alignment}"` : '';
        html.push(`<th${alignAttr}>${cell}</th>`);
      });
      html.push('</tr>');
      html.push('</thead>');
      
      // Add body rows
      if (tableData.length > 1) {
        html.push('<tbody>');
        for (let i = 1; i < tableData.length; i++) {
          html.push('<tr>');
          tableData[i].forEach((cell, index) => {
            const alignment = alignments[index] || 'left';
            const alignAttr = alignment !== 'left' ? ` align="${alignment}"` : '';
            html.push(`<td${alignAttr}>${cell}</td>`);
          });
          html.push('</tr>');
        }
        html.push('</tbody>');
      }
      
      html.push('</table>');
      return html.join('\n');
    }
  
    processLists(markdown) {
      const lines = markdown.split('\n');
      let html = [];
      let inList = false;
      let listType = '';
      
      for (let line of lines) {
        const unorderedMatch = line.match(/^\s*[-*+]\s+(.+)$/);
        const orderedMatch = line.match(/^\s*\d+\.\s+(.+)$/);
        
        if (unorderedMatch || orderedMatch) {
          if (!inList) {
            inList = true;
            listType = unorderedMatch ? 'ul' : 'ol';
            html.push(`<${listType}>`);
          }
          html.push(`<li>${(unorderedMatch || orderedMatch)[1]}</li>`);
        } else {
          if (inList) {
            inList = false;
            html.push(`</${listType}>`);
          }
          html.push(line);
        }
      }
      
      if (inList) {
        html.push(`</${listType}>`);
      }
      
      return html.join('\n');
    }
  };
}