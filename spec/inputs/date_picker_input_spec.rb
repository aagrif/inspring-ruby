require 'rails_helper'

describe DatePickerInput do
  it "#input " do
    expect(DatePickerInput.new(double.as_null_object,
      'double',double,
      double).input({})).to_not be_nil
  end
end