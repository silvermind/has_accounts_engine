module Accounting
  class Account < ActiveRecord::Base
    belongs_to :holder, :polymorphic => true
    
    has_many :credit_bookings, :class_name => "Booking", :foreign_key => "credit_account_id"
    has_many :debit_bookings, :class_name => "Booking", :foreign_key => "debit_account_id"
    
    has_many :bookings, :finder_sql => 'SELECT * FROM bookings WHERE credit_account_id = #{id} OR debit_account_id = #{id} ORDER BY value_date'

    # Standard methods
    def to_s(value_range = Date.today, format = :default)
      case format
      when :short
        "#{code}: CHF #{sprintf('%0.2f', saldo(value_range).currency_round)}"
      else
        "#{title} (#{code}): CHF #{sprintf('%0.2f', saldo(value_range).currency_round)}"
      end
    end

    def self.overview(value_range = Date.today, format = :default)
      Accounting::Account.all.map{|a| a.to_s(value_range, format)}
    end
    
    def saldo(value_range = Date.today)
      if value_range.is_a? Range
        credit_amount = credit_bookings.sum(:amount, :conditions => {:value_date => value_range})
        debit_amount = debit_bookings.sum(:amount, :conditions => {:value_date => value_range})
      else
        credit_amount = credit_bookings.sum(:amount, :conditions => ["value_date <= ?", value_range])
        debit_amount = debit_bookings.sum(:amount, :conditions => ["value_date <= ?", value_range])
      end

      credit_amount ||= 0
      debit_amount ||= 0

      return credit_amount - debit_amount
    end
  end

  module ClassMethods
    def has_accounts(options = {})
      class_eval <<-end_eval
        has_many :accounts, :class_name => 'Accounting::Account', :as => 'holder'
        has_one :account, :class_name => 'Accounting::Account', :as => 'holder'
      end_eval
    end
  end
end
