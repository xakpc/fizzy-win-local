module MarkdownRenderer::Parsing
  HR = /^---$/
  INLINE_HTML_BLOCK_START = /^</
  HEADING_START = /^#/
  CODE_BLOCK_START = /^```/

  NEWLINE_OR_EOF = /\n|$/
  SOFT_LINE_BREAK = /(?<=[^\n])\n(?=[^\n])/

  NUMBERED_LIST_START = /^\d+\.\s/
  NUMBERED_LIST_ITEM = /#{NUMBERED_LIST_START}[^\n]*#{NEWLINE_OR_EOF}/

  UNORDERED_LIST_START = /^-\s/
  UNORDERED_LIST_ITEM = /#{UNORDERED_LIST_START}[^\n]*#{NEWLINE_OR_EOF}/

  BLOCK_QUOTE_START = /^>\s?/
  BLOCK_QUOTE_CONTENT = /#{BLOCK_QUOTE_START}[^\n]*#{NEWLINE_OR_EOF}/

  TABLE_START = /^\|/
  TABLE_HEADER_ROW = /^\|(.+)\|/
  TABLE_SEPARATOR = /^\|[-|]+\|/
  TABLE_DATA_ROW = /^\|.+\|/
  TABLE = /#{TABLE_HEADER_ROW}\r?\n#{TABLE_SEPARATOR}\r?\n((?:#{TABLE_DATA_ROW}\r?\n)*)/

  BLOCK_STARTERS = Regexp.union [
    HR,
    TABLE_START,
    HEADING_START,
    CODE_BLOCK_START,
    BLOCK_QUOTE_START,
    NUMBERED_LIST_START,
    UNORDERED_LIST_START,
    INLINE_HTML_BLOCK_START ]

  private
    def parse_paragraphs(content)
      content.split(/\n\n+/).map do |text|
        if text.match?(BLOCK_STARTERS)
          text
        else
          paragraph text.gsub(SOFT_LINE_BREAK, soft_line_break)
        end
      end.join("\n\n")
    end

    def parse_bold_italics(content)
      transform = ->(match) { bold(italics(match)) }

      content
        .gsub(/(?<!\*)\*\*\*([^*]+)\*\*\*(?!\*)/) { transform.($1) }
        .gsub(/(?<!_)___([^_]+)___(?!_)/) { transform.($1) }
    end

    def parse_bold(content)
      transform = ->(match) { bold(match) }

      content
        .gsub(/(?<!\*)\*\*([^*]+)\*\*(?!\*)/) { transform.($1) }
        .gsub(/(?<!_)__([^_]+)__(?!_)/) { transform.($1) }
    end

    def parse_italics(content)
      transform = ->(match) { italics(match) }

      content
        .gsub(/(?<!\*)\*([^*]+)\*(?!\*)/) { transform.($1) }
        .gsub(/(?<!_)_([^_]+)_(?!_)/) { transform.($1) }
    end

    def parse_strikethrough(content)
      content.gsub(/~~(.*?)~~/) { strikethrough($1) }
    end

    def parse_highlight(content)
      content.gsub(/==(.*?)==/) { highlight($1) }
    end

    def parse_headers(content)
      content
        .gsub(/^# (.*)$/) { header($1, 1) }
        .gsub(/^## (.*)$/) { header($1, 2) }
        .gsub(/^### (.*)$/) { header($1, 3) }
        .gsub(/^#### (.*)$/) { header($1, 4) }
        .gsub(/^##### (.*)$/) { header($1, 5) }
        .gsub(/^###### (.*)$/) { header($1, 6) }
    end

    def parse_tables(content)
      content.gsub(TABLE) do
        headers = $1.split("|").map(&:strip).compact_blank
        rows = $2.split("\n").map { |row| row.split("|").map(&:strip).compact_blank unless row.blank? }.compact
        table(headers, rows) if rows.map(&:size).all?(headers.size)
      end
    end

    def parse_ordered_lists(content)
      content.gsub(/(?:#{NUMBERED_LIST_ITEM})+/) { |list| ordered_list(parse_ordered_list_items(list.strip)) }
    end

    def parse_ordered_list_items(content)
      content.gsub(/#{NUMBERED_LIST_START}(.*)$/) { list_item($1) }
    end

    def parse_unordered_lists(content)
      content.gsub(/(?:#{UNORDERED_LIST_ITEM})+/) { |list| unordered_list(parse_unordered_list_items(list.strip)) }
    end

    def parse_unordered_list_items(content)
      content.gsub(/#{UNORDERED_LIST_START}(.*)$/) { list_item($1) }
    end

    def parse_block_quotes(content)
      content.gsub(/(?:#{BLOCK_QUOTE_CONTENT})+/) { |text| block_quote(text.strip) }
    end

    def parse_horizontal_rules(content)
      content.gsub(HR) { horizontal_rule }
    end

    def parse_images(content)
      content.gsub(/!\[(.*?)\]\((.*?)\)/) { image($2, $1) }
    end

    def parse_links(content)
      content.gsub(/\[(.*?)\]\((.*?)\)/) { link($1, $2) }
    end

    def parse_code_blocks(content)
      content.gsub(/#{CODE_BLOCK_START}(\w*)\n(.*?)```$/m) { code_block($2, $1) }
    end

    def parse_code_spans(content)
      content.gsub(/`([^`\n]+)`/) { code_span($1) }
    end
end
