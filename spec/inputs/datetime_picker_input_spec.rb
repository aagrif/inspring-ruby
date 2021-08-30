require 'rails_helper'

describe DatetimePickerInput do
  it "#input " do
    expect(DatetimePickerInput.new(double.as_null_object,
      double.as_null_object,double.as_null_object,
      double.as_null_object).input({})).to_not be_nil
  end
end