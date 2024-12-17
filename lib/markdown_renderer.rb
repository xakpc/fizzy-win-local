class MarkdownRenderer
  require_relative "markdown_renderer/parsing"
  require_relative "markdown_renderer/markup"

  include Parsing, Markup

  def initialize
    @id_counts = Hash.new(0)
  end

  def render(content)
    content
      .then { |c| parse_paragraphs(c) }
      .then { |c| parse_bold_italics(c) }
      .then { |c| parse_bold(c) }
      .then { |c| parse_italics(c) }
      .then { |c| parse_strikethrough(c) }
      .then { |c| parse_highlight(c) }
      .then { |c| parse_headers(c) }
      .then { |c| parse_tables(c) }
      .then { |c| parse_ordered_lists(c) }
      .then { |c| parse_unordered_lists(c) }
      .then { |c| parse_block_quotes(c) }
      .then { |c| parse_horizontal_rules(c) }
      .then { |c| parse_images(c) }
      .then { |c| parse_links(c) }
      .then { |c| parse_code_blocks(c) }
      .then { |c| parse_code_spans(c) }
  end

  private
    attr_reader :id_counts

    def unique_id(text)
      text.parameterize.then do |base_id|
        id_counts[base_id] += 1
        id_counts[base_id] > 1 ? "#{base_id}-#{id_counts[base_id]}" : base_id
      end
    end
end
