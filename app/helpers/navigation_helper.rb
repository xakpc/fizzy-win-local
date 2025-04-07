module NavigationHelper
  def link_to_home(icon: "home", label: "Home", **properties)
    classes = properties.delete(:class)

    link_to root_path, class: "btn #{classes}", data: { controller: "hotkey", action: "keydown.esc@document->hotkey#click" } do
      icon_tag(icon) + tag.span(label, class: "for-screen-reader")
    end
  end

  def link_to_back(fallback_path: root_path)
    link_to fallback_path, class: "btn flex-item-justify-start", aria: { label: "Go back" },
      data: { controller: "back-navigation hotkey", action: "keydown.esc@document->hotkey#click", back_navigation_fallback_destination_value: fallback_path } do
      icon_tag("arrow-left")
    end
  end
end
