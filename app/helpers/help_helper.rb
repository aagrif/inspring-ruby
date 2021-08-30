module HelpHelper
  def help_tag(path)
    link_to "Help", path, class: "btn btn-default pull-right"
  end

  def dt(title)
    content = "<p></p>"
    content << content_tag(:dt, title, id: title.split.join.underscore)
    content.html_safe
  end
end
