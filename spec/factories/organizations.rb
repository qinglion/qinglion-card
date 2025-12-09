FactoryBot.define do
  factory :organization do

    name { "MyString" }
    description { "MyText" }
    admin_user_id { 1 }
    invite_token { "MyString" }

  end
end
