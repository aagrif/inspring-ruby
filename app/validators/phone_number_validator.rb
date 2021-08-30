class PhoneNumberValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.blank?
      record.errors[attribute] << (
        options[:message] || "is not a valid US phone number (should be 10 or 11 digits)."
      )
    else
      digits = value.gsub(/\D/, "").split(//)
      if !digits.length.between?(10, 11)
        record.errors[attribute] << (
          options[:message] || "is not a valid US phone number (should be 10 or 11 digits)"
        )
      end
    end
  end
end
