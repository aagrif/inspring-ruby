class TpartyKeywordValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # TODO: fix intermittent error
    # (MessagingManager.init_instance returns RSpec::Mocks::Double sometimes)
    # error = MessagingManager.init_instance.validate_tparty_keyword(value)
    error = MessagingManager.mmclass.new.validate_tparty_keyword(value)
    record.errors[attribute] << (options[:message] || error) if error
  end
end
