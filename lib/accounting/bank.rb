module Accounting
  class Bank < ActiveRecord::Base
    has_many :accounts

    has_vcards

    def to_s
      [vcard.full_name, vcard.locality].compact.join(', ')      
    end
  end
end
