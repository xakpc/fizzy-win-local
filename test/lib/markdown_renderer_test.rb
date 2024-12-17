require "test_helper"

class MarkdownRendererTest < ActiveSupport::TestCase
  setup do
    @renderer = MarkdownRenderer.new
  end

  test "renders a complete markdown document" do
    assert_equal expected_html, @renderer.render(markdown_content)
  end

  private
    def expected_html
      <<~HTML
        <h1 id="welcome-to-my-document">
          Welcome to My Document <a href="#welcome-to-my-document" class="heading__link" aria-hidden="true">#</a>
        </h1>

        <p>This is an introduction paragraph with some text.</p>

        <hr>

        <p><strong><em>Hello, world!</em></strong> <strong>Hello, world!</strong> <em>Hello, world!</em> <s>Hello, world!</s> <mark>Hello, world!</mark></p>

        <p><strong><em>Hello, world!</em></strong>
        <br>
        <strong>Hello, world!</strong>
        <br>
        <em>Hello, world!</em>
        <br>
        <s>Hello, world!</s>
        <br>
        <mark>Hello, world!</mark></p>

        <h2 id="getting-started">
          Getting Started <a href="#getting-started" class="heading__link" aria-hidden="true">#</a>
        </h2>

        <p>Here’s what you need to know:</p>

        <ol>
          <li>First important point</li>
          <li>Second crucial thing</li>
          <li>Don’t forget this</li>
        </ol>

        <h2 id="key-features">
          Key Features <a href="#key-features" class="heading__link" aria-hidden="true">#</a>
        </h2>

        <p>Our product offers:</p>

        <ul>
          <li>Simple interface</li>
          <li>Powerful features</li>
          <li>Great documentation</li>
        </ul>

        <p><a href="https://basecamp.com">Get Basecamp</a></p>

        <h3 id="important-note-2">
          Important Note <a href="#important-note-2" class="heading__link" aria-hidden="true">#</a>
        </h3>

        <p>Here’s some
        <br>
        multiline text.
        <br>
        It has line breaks
        <br>
        in-between.</p>

        <blockquote>
          Please read this carefully
          It contains vital information
          That you shouldn’t miss
        </blockquote>

        <p><a href="https://placehold.co/600x400" data-action="lightbox#open:prevent" data-lightbox-target="image" data-lightbox-url-value="https://placehold.co/600x400?disposition=attachment">
          <img src="https://placehold.co/600x400" alt="Placeholder image">
        </a></p>

        <h2 id="important-note">
          Important Note <a href="#important-note" class="heading__link" aria-hidden="true">#</a>
        </h2>

        <p><a href="https://placehold.co/400x400" data-action="lightbox#open:prevent" data-lightbox-target="image" data-lightbox-url-value="https://placehold.co/400x400?disposition=attachment">
          <img src="https://placehold.co/400x400" alt="Placeholder image">
        </a></p>

        <ol>
          <li>Remember to save</li>
          <li>Back up your work</li>
        </ol>

        <p><a href="https://basecamp.com">Get Basecamp</a></p>

        <table>
          <thead>
            <tr>
              <th>Table 1 Header 1</th>
              <th>Table 1 Header 2</th>
            </tr>
          </thead>
          <tbody>
            <tr><td>Table 1 Data 1</td><td>Table 1 Data 2</td></tr>
            <tr><td>Table 1 Data 3</td><td>Table 1 Data 4</td></tr>
          </tbody>
        </table>

        <p>Some content between tables...</p>

        <table>
          <thead>
            <tr>
              <th>Table 2 Header 1</th>
              <th>Table 2 Header 2</th>
            </tr>
          </thead>
          <tbody>
            <tr><td>Table 2 Data 1</td><td>Table 2 Data 2</td></tr>
            <tr><td>Table 2 Data 3</td><td>Table 2 Data 4</td></tr>
          </tbody>
        </table>

        <div class="highlight"><pre class="highlight ruby"><code><span class="k">class</span> <span class="nc">Post</span> <span class="o">&lt;</span> <span class="no">ApplicationRecord</span>
          <span class="k">def</span> <span class="nf">title</span>
            <span class="s2">"foo"</span>
          <span class="k">end</span>
        <span class="k">end</span>
        </code></pre></div>

        <p><code>puts "Hello, world!"</code></p>

        <p>Thanks for reading!</p>

        <details>
          <summary>Summary</summary>
          Details
        </details>
      HTML
    end

    def markdown_content
      <<~MARKDOWN
        # Welcome to My Document

        This is an introduction paragraph with some text.

        ---

        ***Hello, world!*** **Hello, world!** *Hello, world!* ~~Hello, world!~~ ==Hello, world!==

        ***Hello, world!***
        **Hello, world!**
        *Hello, world!*
        ~~Hello, world!~~
        ==Hello, world!==

        ## Getting Started

        Here’s what you need to know:

        1. First important point
        2. Second crucial thing
        3. Don’t forget this

        ## Key Features

        Our product offers:

        - Simple interface
        - Powerful features
        - Great documentation

        [Get Basecamp](https://basecamp.com)

        ### Important Note

        Here’s some
        multiline text.
        It has line breaks
        in-between.

        > Please read this carefully
        > It contains vital information
        > That you shouldn’t miss

        ![Placeholder image](https://placehold.co/600x400)

        ## Important Note

        ![Placeholder image](https://placehold.co/400x400)

        1. Remember to save
        2. Back up your work

        [Get Basecamp](https://basecamp.com)

        | Table 1 Header 1 | Table 1 Header 2 |
        |-|-|
        | Table 1 Data 1 | Table 1 Data 2 |
        | Table 1 Data 3 | Table 1 Data 4 |

        Some content between tables...

        | Table 2 Header 1 | Table 2 Header 2 |
        |------------------|------------------|
        | Table 2 Data 1   | Table 2 Data 2   |
        | Table 2 Data 3   | Table 2 Data 4   |

        ```rb
        class Post < ApplicationRecord
          def title
            "foo"
          end
        end
        ```

        `puts "Hello, world!"`

        Thanks for reading!

        <details>
          <summary>Summary</summary>
          Details
        </details>
      MARKDOWN
    end
end
