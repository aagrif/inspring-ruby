class OneWordValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.blank?
      record.errors[attribute] << (options[:message] || "is not one word long.")
    else
      words = value.split
      unless words.length == 1
        record.errors[attribute] << (options[:message] || "is not one word long")
      end
    end
  end
end
