module FiltersHelper
  def filter_chip_tag(text, params)
    link_to cards_path(params), class: "btn txt-x-small btn--remove fill-selected flex-inline" do
      concat tag.span(text)
      concat icon_tag("close")
    end
  end

  def filter_hidden_field_tag(key, value)
    name = params[key].is_a?(Array) ? "#{key}[]" : key
    hidden_field_tag name, value, id: nil
  end

  def filter_selected_collections_title(user_filtering)
    user_filtering.selected_collection_titles.collect { tag.strong it }.to_sentence.html_safe
  end

  def filter_place_menu_item(path, label, icon)
    tag.li class: "popup__group", id: "filter-place-#{label.parameterize}", data: { filter_target: "item", navigable_list_target: "item" } do
      concat icon_tag(icon)
      concat(link_to(path, class: "popup__item btn") do
        concat tag.span(label, class: "overflow-ellipsis")
        concat tag.span(" ›", class: "translucent flex-item-no-shrink flex-item-justify-end")
      end)
    end
  end

  def filter_dialog(label, &block)
    tag.dialog class: "margin-block-start-half popup panel flex-column align-start gap-half fill-white shadow txt-small", data: {
      action: "turbo:before-cache@document->dialog#close keydown->navigable-list#navigate filter:changed->navigable-list#reset toggle->filter#filter",
      aria: { label: label, aria_description: label },
      controller: "filter navigable-list",
      dialog_target: "dialog",
      navigable_list_focus_on_selection_value: false,
      navigable_list_actionable_items_value: true
    }, &block
  end

  def filter_hotkey_link(title, path, key, icon)
    link_to path, class: "popup__group btn borderless", id: "filter-hotkey-#{key}", role: "listitem", data: { filter_target: "item", navigable_list_target: "item", controller: "hotkey", action: "keydown.#{key}@document->hotkey#click keydown.shift+#{key}@document->hotkey#click"} do
      concat icon_tag(icon)
      concat tag.span(title.html_safe)
      concat tag.kbd(key)
    end
  end
end
