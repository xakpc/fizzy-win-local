require "rouge/plugins/redcarpet"

module MarkdownRenderer::Markup
  include Rouge::Plugins::Redcarpet

  TABLE_ROW_INDENT    = " " * 4
  LIST_ITEM_INDENT    = " " * 2
  BLOCK_QUOTE_INDENT  = " " * 2
  TABLE_HEADER_INDENT = " " * 6

  # FIXME: the attributes suggest this should be an app-level override instead
  def header(text, header_level)
    unique_id(text).then do |id|
      <<~HTML.chomp
        <h#{header_level} id="#{id}">
          #{text} <a href="##{id}" class="heading__link" aria-hidden="true">#</a>
        </h#{header_level}>
      HTML
    end
  end

  def bold(text)
    "<strong>#{text}</strong>"
  end

  def italics(text)
    "<em>#{text}</em>"
  end

  def strikethrough(text)
    "<s>#{text}</s>"
  end

  def highlight(text)
    "<mark>#{text}</mark>"
  end

  def table(headers, rows)
    <<~HTML
      <table>
        <thead>
          <tr>
            #{headers.map { |header| "<th>#{header}</th>" }.join("\n" + TABLE_HEADER_INDENT)}
          </tr>
        </thead>
        <tbody>
          #{rows.map { |row| "<tr>#{row.map { |cell| "<td>#{cell}</td>" }.join}</tr>" }.join("\n" + TABLE_ROW_INDENT)}
        </tbody>
      </table>
    HTML
  end

  def ordered_list(contents)
    <<~HTML
      <ol>
        #{contents.split("\n").join("\n" + LIST_ITEM_INDENT)}
      </ol>
    HTML
  end

  def unordered_list(contents)
    <<~HTML
      <ul>
        #{contents.split("\n").join("\n" + LIST_ITEM_INDENT)}
      </ul>
    HTML
  end

  def list_item(text)
    "<li>#{text}</li>"
  end

  def block_quote(text)
    <<~HTML
      <blockquote>
        #{text.gsub(/^>\s?/, '').split("\n").join("\n" + BLOCK_QUOTE_INDENT)}
      </blockquote>
    HTML
  end

  def horizontal_rule
    "<hr>"
  end

  def link(text, href)
    "<a href=\"#{href}\">#{text}</a>"
  end

  def code_block(code, language)
    block_code(code, language) # call Rouge Redcarpet plugin
  end

  def code_span(text)
    "<code>#{text}</code>"
  end

  # FIXME: the attributes suggest this should be an app-level override instead
  def image(url, alt_text)
    <<~HTML.chomp
      <a href="#{url}" data-action="lightbox#open:prevent" data-lightbox-target="image" data-lightbox-url-value="#{url}?disposition=attachment">
        <img src="#{url}" alt="#{alt_text}">
      </a>
    HTML
  end

  def paragraph(text)
    "<p>#{text}</p>"
  end

  def soft_line_break
    "\n#{line_break}\n"
  end

  def line_break
    "<br>"
  end
end
