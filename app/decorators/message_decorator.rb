class MessageDecorator < Draper::Decorator
  delegate_all

  def title_text
    case
    when type == "ActionMessage"
      "(Action Message) [#{action.type.underscore.humanize.upcase}]"
    when title.present?
      title
    else
      caption.to_s[0..40]
    end
  end
end
