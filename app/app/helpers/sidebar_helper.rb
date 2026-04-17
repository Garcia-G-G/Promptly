module SidebarHelper
  def sidebar_link(label, icon, path, count: nil)
    active = current_page?(path)
    content_tag(:a, href: path, class: "sidebar__nav-item #{active ? 'sidebar__nav-item--active' : ''}") do
      left = content_tag(:div, class: "sidebar__nav-item-left") do
        content_tag(:span, icon.html_safe, class: "sidebar__nav-icon") + content_tag(:span, label)
      end
      right = count ? content_tag(:span, count, class: "sidebar__nav-count") : "".html_safe
      left + right
    end
  end
end
