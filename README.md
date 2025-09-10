# Santoku HTML

Stream-based HTML/XML parser with SAX-style event-driven interface built on libxml2.

## API Reference

### `santoku.html`

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `parsehtml` | `text, [is_html], [start_idx], [encoding]` | `iterator` | Creates parser iterator that yields tokens |

#### Parameters

- `text` (`string`): The HTML or XML text to parse
- `is_html` (`boolean`, optional): Parse as HTML if true, XML if false (default: false)
- `start_idx` (`number`, optional): Starting index in text (default: first non-whitespace)
- `encoding` (`string`, optional): Text encoding (default: "utf-8")

#### Token Types

The iterator yields different token types as multiple return values:

| Token | Returns | Description |
|-------|---------|-------------|
| Open tag | `"open", tag_name` | Opening tag (e.g., `<div>`) |
| Close tag | `"close", tag_name` | Closing tag (e.g., `</div>`) |
| Self-close | `"close"` | Self-closing tag close (e.g., `/>` in XML) |
| Text | `"text", content` | Text content between tags |
| Attribute | `"attribute", name, value` | Tag attribute (yielded after open tag) |
| Comment | `"comment", content` | HTML/XML comment content |

## License

MIT License

Copyright 2025 Matthew Brooks

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
