FactoryBot.define do
  factory :renewal do
    association :profile
    payment_date { Date.today }
    amount { 1000.00 }
    notes { "年度会员续费" }
  end
end
